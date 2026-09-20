# frozen_string_literal: true

require "rpremote/mrbgems"
require "tmpdir"

RSpec.describe "Resolving project mrbgems" do
  let(:described_class) { Rpremote::Mrbgems }
  let(:commit) { "a" * 40 }

  def create_local_gem(root, name = "my-led")
    directory = File.join(root, name)
    require_name = name.tr("-", "_")
    FileUtils.mkdir_p(File.join(directory, "mrblib"))
    File.write(File.join(directory, "mrbgem.rake"), <<~RUBY)
      MRuby::Gem::Specification.new(#{name.inspect}) do |spec|
        spec.require_name = #{require_name.inspect}
      end
    RUBY
    File.write(File.join(directory, "mrblib", "#{require_name}.rb"), "class MyLed; end\n")
    directory
  end

  it "loads GitHub and manifest-relative local mrbgems" do
    Dir.mktmpdir do |root|
      local = create_local_gem(root)
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
        gem path: "my-led"
      RUBY

      dependencies = described_class.new(cwd: root).check

      expect(dependencies.map(&:type)).to eq(%i[github path])
      expect(dependencies.last.path).to eq(local)
    end
  end

  it "selects the VM required by the project" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        vm :mrubyc
        gem github: "ksbmyk/picoruby-ws2812-plus", commit: "#{commit}"
      RUBY

      manager = described_class.new(cwd: root)

      expect(manager.vm).to eq(:mrubyc)
      expect(manager.lock.fetch("vm")).to eq("mrubyc")
    end
  end

  it "groups dependencies with a Bundler-style group block" do
    Dir.mktmpdir do |root|
      create_local_gem(root)
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        group :development, :test do
          gem path: "my-led"
        end
      RUBY
      manager = described_class.new(cwd: root)

      expect(manager.dependencies.first.groups).to eq(%i[development test])
      result = manager.lock(with: %i[development test])
      expect(result.fetch("with")).to eq(%w[development test])
      expect(result.fetch("gems").first.fetch("groups")).to eq(%w[development test])
    end
  end

  it "selects nested groups by the union of their memberships" do
    Dir.mktmpdir do |root|
      create_local_gem(root, "nested")
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        group :development do
          group :test do
            gem path: "nested"
          end
        end
      RUBY
      manager = described_class.new(cwd: root)

      expect(manager.dependencies.first.groups).to eq(%i[development test])
      expect(manager.lock(with: [:test]).fetch("gems").length).to eq(1)
    end
  end

  it "assigns groups with the gem group option and lets without override with" do
    Dir.mktmpdir do |root|
      create_local_gem(root, "production-only")
      create_local_gem(root, "my-gems")
      create_local_gem(root, "shared")
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem path: "production-only", group: :production
        gem path: "my-gems", group: :test
        gem path: "shared", group: [:production, :test]
      RUBY
      manager = described_class.new(cwd: root)

      result = manager.lock(with: %i[production test], without: [:test])

      expect(manager.dependencies.map(&:groups)).to eq([[:production], [:test], %i[production test]])
      expect(result.fetch("with")).to eq(%w[production test])
      expect(result.fetch("without")).to eq(["test"])
      expect(result.fetch("gems").map { |entry| entry["source"] }).to eq(["production-only"])
    end
  end

  it "records multiple exclusions and combines block and inline groups" do
    Dir.mktmpdir do |root|
      create_local_gem(root, "common")
      create_local_gem(root, "shared")
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem path: "common"
        group :production do
          gem path: "shared", group: :test
        end
      RUBY
      manager = described_class.new(cwd: root)

      result = manager.lock(without: %i[production test])

      expect(manager.dependencies.last.groups).to eq(%i[production test])
      expect(result.fetch("without")).to eq(%w[production test])
      expect(result.fetch("gems").map { |entry| entry["source"] }).to eq(["common"])
    end
  end

  it "locks common gems and the requested groups for builds and automatic requires" do
    Dir.mktmpdir do |root|
      common = create_local_gem(root, "common")
      production = create_local_gem(root, "production-only")
      create_local_gem(root, "test-only")
      definition = File.join(root, "Mrbgems")
      base = File.join(root, "base.rb")
      File.write(definition, <<~RUBY)
        gem path: "common"
        group :production do
          gem path: "production-only"
        end
        group :test do
          gem path: "test-only"
        end
      RUBY
      File.write(base, "MRuby::CrossBuild.new('r2p2-picoruby-pico2') {}\n")
      manager = described_class.new(path: definition)
      common_result = manager.lock
      expect(common_result.fetch("with")).to eq([])
      expect(common_result.fetch("gems").map { |entry| entry["source"] }).to eq(["common"])

      result = manager.lock(with: [:production])

      overlay = manager.generate_overlay(
        base_config: base, target: "r2p2-picoruby-pico2", directory: File.join(root, "build")
      )
      generated = File.read(overlay.path)

      expect(result.fetch("with")).to eq(["production"])
      expect(result.fetch("gems").map { |entry| entry["source"] }).to eq(%w[common production-only])
      expect(generated).to include("conf.gem #{common.inspect}")
      expect(generated).to include("conf.gem #{production.inspect}")
      expect(generated).not_to include("test-only")
      expect(manager.require_names).to eq(%w[common production_only])
    end
  end

  it "rejects unknown and invalid group names" do
    Dir.mktmpdir do |root|
      create_local_gem(root)
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        group :test do
          gem path: "my-led"
        end
      RUBY

      manager = described_class.new(cwd: root)
      expect { manager.lock(with: [:production]) }
        .to raise_error(described_class::DefinitionError, /unknown mrbgem group: production/)
      expect { manager.lock(without: [:production]) }
        .to raise_error(described_class::DefinitionError, /unknown mrbgem group: production/)
      expect { manager.lock(with: ["bad group"]) }
        .to raise_error(described_class::DefinitionError, /invalid mrbgem group/)
      expect { described_class.parse_groups("") }
        .to raise_error(described_class::DefinitionError, /invalid mrbgem group/)
      ["production,", ",production", "production,,test", "production, ,test"].each do |groups|
        expect { described_class.parse_groups(groups) }
          .to raise_error(described_class::DefinitionError, /invalid mrbgem group/)
      end
    end
  end

  it "recognizes declared groups even when they contain no gems" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), "group :production do\nend\n")

      result = described_class.new(cwd: root).lock(with: [:production])

      expect(result).to include("with" => ["production"], "gems" => [])
    end
  end

  it "validates only selected local gems while check validates the entire definition" do
    Dir.mktmpdir do |root|
      create_local_gem(root, "common")
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem path: "common"
        gem path: "missing-test-gem", group: :test
      RUBY
      manager = described_class.new(cwd: root)

      expect(manager.lock(without: [:test]).fetch("gems").map { |entry| entry["source"] }).to eq(["common"])
      expect { manager.check }.to raise_error(described_class::DefinitionError, /missing-test-gem/)
    end
  end

  it "locks GitHub commits and local contents" do
    Dir.mktmpdir do |root|
      create_local_gem(root)
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
        gem path: "my-led"
      RUBY
      manager = described_class.new(cwd: root, resolver: ->(_source, _branch) { commit })

      result = manager.lock

      expect(result.fetch("gems").first.fetch("commit")).to eq(commit)
      expect(result.fetch("gems").last.fetch("sha256")).to match(/\A[0-9a-f]{64}\z/)
      expect(result.fetch("gems").last.fetch("require_name")).to eq("my_led")
      expect(JSON.parse(File.read(File.join(root, "Mrbgems.lock")))).to eq(result)
    end
  end

  it "resolves an explicit lock path from the command working directory" do
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "config"))
      File.write(File.join(root, "config", "Mrbgems"), "")

      manager = described_class.new(
        path: "config/Mrbgems", lock_path: "locks/production.lock", cwd: root
      )

      expect(manager.path).to eq(File.join(root, "config", "Mrbgems"))
      expect(manager.lock_path).to eq(File.join(root, "locks", "production.lock"))
    end
  end

  it "records local require names and prepends them to executed source" do
    Dir.mktmpdir do |root|
      create_local_gem(root)
      File.write(File.join(root, "Mrbgems"), "gem path: \"my-led\"\n")
      manager = described_class.new(cwd: root)

      manager.lock

      expect(manager.require_names).to eq(["my_led"])
      expect(manager.prepend_requires("puts :ready\n")).to eq("require \"my_led\"\nputs :ready\n")
    end
  end

  it "validates an inferred local require name before replacing the lock" do
    Dir.mktmpdir do |root|
      directory = create_local_gem(root)
      File.write(
        File.join(directory, "mrbgem.rake"),
        "spec.require_name = \"bad\tname\"\n"
      )
      File.write(File.join(root, "Mrbgems"), "gem path: \"my-led\"\n")
      lock_path = File.join(root, "Mrbgems.lock")
      File.write(lock_path, "existing\n")

      expect { described_class.new(cwd: root).lock(update: true) }
        .to raise_error(described_class::LockError, /invalid mrbgems lock entry/)
      expect(File.read(lock_path)).to eq("existing\n")
    end
  end

  it "can embed a local gem without automatically requiring it" do
    Dir.mktmpdir do |root|
      create_local_gem(root)
      File.write(File.join(root, "Mrbgems"), "gem path: \"my-led\", auto_require: false\n")
      manager = described_class.new(cwd: root)

      result = manager.lock

      expect(result.fetch("gems").first).to include("auto_require" => false)
      expect(result.fetch("gems").first).not_to have_key("require_name")
      expect(manager.require_names).to be_empty
      expect(manager.prepend_requires("require \"my_led\"\n")).to eq("require \"my_led\"\n")
    end
  end

  it "records an explicitly configured GitHub require name" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "ksbmyk/picoruby-ws2812-plus", commit: "#{commit}", require: "ws2812-plus"
      RUBY

      result = described_class.new(cwd: root).lock

      expect(result.fetch("gems").first.fetch("require_name")).to eq("ws2812-plus")
    end
  end

  it "reuses a lock unless update is requested" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
      RUBY
      calls = 0
      resolver = lambda do |_source, _branch|
        calls += 1
        calls == 1 ? "a" * 40 : "b" * 40
      end
      manager = described_class.new(cwd: root, resolver: resolver)

      expect(manager.lock.fetch("gems").first.fetch("commit")).to eq("a" * 40)
      expect(manager.lock.fetch("gems").first.fetch("commit")).to eq("a" * 40)
      expect(manager.lock(update: true).fetch("gems").first.fetch("commit")).to eq("b" * 40)
      expect(calls).to eq(2)
    end
  end

  it "reuses remaining commits when the selected groups change" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "example/common"
        gem github: "example/production", group: :production
        gem github: "example/test", group: :test
      RUBY
      calls = []
      commits = { "example/common" => "a" * 40, "example/production" => "b" * 40, "example/test" => "c" * 40 }
      resolver = lambda do |source, _branch|
        calls << source
        commits.fetch(source)
      end
      manager = described_class.new(cwd: root, resolver: resolver)

      manager.lock(with: [:production])
      result = manager.lock(with: [:test])

      expect(calls).to eq(%w[example/common example/production example/test])
      expect(result.fetch("gems").map { |entry| entry.fetch("commit") }).to eq(["a" * 40, "c" * 40])
    end
  end

  it "updates only selected unresolved commits and preserves explicit commits" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "example/common"
        gem github: "example/pinned", commit: "#{commit}"
        gem github: "example/test", group: :test
      RUBY
      calls = []
      resolver = lambda do |source, _branch|
        calls << source
        source == "example/common" ? "b" * 40 : "c" * 40
      end
      manager = described_class.new(
        cwd: root,
        resolver: resolver
      )

      result = manager.lock(update: true)

      expect(calls).to eq(["example/common"])
      expect(result.fetch("gems").map { |entry| entry.fetch("commit") }).to eq(["b" * 40, commit])
    end
  end

  it "generates a build config overlay without modifying the base config" do
    Dir.mktmpdir do |root|
      local = create_local_gem(root)
      definition = File.join(root, "Mrbgems")
      base = File.join(root, "base.rb")
      File.write(definition, <<~RUBY)
        gem github: "ksbmyk/picoruby-ws2812-plus", commit: "#{commit}"
        gem path: "my-led"
      RUBY
      File.write(base, "MRuby::CrossBuild.new('r2p2-picoruby-pico2') {}\n")
      original = File.read(base)
      manager = described_class.new(path: definition)
      manager.lock

      overlay = manager.generate_overlay(
        base_config: base, target: "r2p2-picoruby-pico2", directory: File.join(root, "build")
      )
      generated = File.read(overlay.path)

      expect(generated).to start_with("# frozen_string_literal: true\n\n")
      expect(generated).to include("load #{base.inspect}")
      expect(generated).to include("checksum_hash: #{commit.inspect}")
      expect(generated).to include("conf.gem #{local.inspect}")
      expect(File.read(base)).to eq(original)
      expect(overlay.fingerprint).to match(/\A[0-9a-f]{12}\z/)
    end
  end

  it "resolves local gems relative to a custom lock file" do
    Dir.mktmpdir do |root|
      local = create_local_gem(root)
      FileUtils.mkdir_p(File.join(root, "config"))
      File.write(File.join(root, "config", "Mrbgems"), "gem path: \"../my-led\"\n")
      base = File.join(root, "base.rb")
      File.write(base, "MRuby::CrossBuild.new('target') {}\n")
      manager = described_class.new(
        path: "config/Mrbgems", lock_path: "locks/production.lock", cwd: root
      )

      result = manager.lock
      overlay = manager.generate_overlay(base_config: base, target: "target", directory: File.join(root, "build"))

      expect(result.fetch("gems").first.fetch("source")).to eq("../my-led")
      expect(File.read(overlay.path)).to include("conf.gem #{local.inspect}")

      File.write(File.join(local, "mrblib", "my_led.rb"), "class MyLed; UPDATED = true; end\n")
      expect do
        manager.generate_overlay(base_config: base, target: "target", directory: File.join(root, "build"))
      end.to raise_error(described_class::LockError, /has changed/)
    end
  end

  it "builds an overlay from the lock without evaluating Mrbgems" do
    Dir.mktmpdir do |root|
      base = File.join(root, "base.rb")
      File.write(File.join(root, "Mrbgems"), <<~RUBY)
        gem github: "ksbmyk/picoruby-ws2812-plus", commit: "#{commit}"
      RUBY
      File.write(base, "MRuby::CrossBuild.new('r2p2-picoruby-pico2') {}\n")
      manager = described_class.new(cwd: root)
      manager.lock
      locked_contents = File.binread(File.join(root, "Mrbgems.lock"))
      File.write(File.join(root, "Mrbgems"), "raise 'must not be evaluated by build'\n")

      overlay = manager.generate_overlay(
        base_config: base, target: "r2p2-picoruby-pico2", directory: File.join(root, "build")
      )

      expect(File.read(overlay.path)).to include("checksum_hash: #{commit.inspect}")
      expect(File.binread(File.join(root, "Mrbgems.lock"))).to eq(locked_contents)
    end
  end

  it "rejects a changed local gem before generating an overlay" do
    Dir.mktmpdir do |root|
      local = create_local_gem(root)
      base = File.join(root, "base.rb")
      File.write(File.join(root, "Mrbgems"), "gem path: \"my-led\"\n")
      File.write(base, "MRuby::CrossBuild.new('r2p2-picoruby-pico2') {}\n")
      manager = described_class.new(cwd: root)
      manager.lock
      File.write(File.join(local, "mrblib", "my_led.rb"), "class MyLed; UPDATED = true; end\n")

      expect do
        manager.generate_overlay(
          base_config: base, target: "r2p2-picoruby-pico2", directory: File.join(root, "build")
        )
      end.to raise_error(described_class::LockError, /has changed.*mrbgems lock/m)
    end
  end

  it "requires a version 2 lock for lock consumers" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems.lock"), JSON.generate("version" => 1, "gems" => []))

      expect { described_class.new(cwd: root).read_lock }
        .to raise_error(described_class::LockError, /run `rpremote mrbgems lock`/)
    end
  end

  it "reuses a valid version 1 commit while migrating to version 2" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), "gem github: \"example/common\"\n")
      File.write(
        File.join(root, "Mrbgems.lock"),
        JSON.generate("version" => 1, "gems" => [
                        { "type" => "github", "source" => "example/common",
                          "branch" => "main", "commit" => commit }
                      ])
      )
      manager = described_class.new(cwd: root, resolver: ->(*) { raise "must not resolve" })

      result = manager.lock

      expect(result).to include("version" => 2, "with" => [], "without" => [])
      expect(result.fetch("gems").first.fetch("commit")).to eq(commit)
    end
  end

  it "reports malformed lock structures as lock errors" do
    invalid_locks = [
      nil,
      { "version" => 2, "with" => [], "gems" => [nil] },
      { "version" => 2, "with" => [], "gems" => [1] },
      { "version" => 2, "with" => [], "gems" => [[]] },
      { "version" => 2, "with" => [], "gems" => [
        { "type" => "github", "source" => 1, "branch" => "main", "commit" => commit }
      ] },
      { "version" => 2, "with" => [], "gems" => [
        { "type" => "path", "source" => "local", "sha256" => 1 }
      ] },
      { "version" => 2, "with" => [], "gems" => [
        { "type" => "path", "source" => "/absolute", "sha256" => "a" * 64 }
      ] }
    ]

    Dir.mktmpdir do |root|
      manager = described_class.new(cwd: root)
      invalid_locks.each do |contents|
        File.write(File.join(root, "Mrbgems.lock"), JSON.generate(contents))
        expect { manager.read_lock }.to raise_error(described_class::LockError)
      end
    end
  end

  it "rejects malformed JSON, headers, entries, and duplicates" do
    valid = { "type" => "github", "source" => "example/common", "branch" => "main", "commit" => commit }
    invalid_locks = [
      "{",
      JSON.generate("version" => 1, "gems" => []),
      JSON.generate("version" => 2, "with" => [], "vm" => "ruby", "gems" => []),
      JSON.generate("version" => 2, "with" => ["bad group"], "gems" => []),
      JSON.generate("version" => 2, "with" => [], "gems" => [valid.merge("commit" => "bad")]),
      JSON.generate("version" => 2, "with" => [], "gems" => [
                      { "type" => "path", "source" => "local", "sha256" => "bad" }
                    ]),
      JSON.generate("version" => 2, "with" => [], "gems" => [valid, valid])
    ]

    Dir.mktmpdir do |root|
      manager = described_class.new(cwd: root)
      invalid_locks.each do |contents|
        File.write(File.join(root, "Mrbgems.lock"), contents)
        expect { manager.read_lock }.to raise_error(described_class::LockError)
      end
    end
  end

  it "reports a malformed previous lock as a lock error" do
    Dir.mktmpdir do |root|
      File.write(File.join(root, "Mrbgems"), "")
      File.write(File.join(root, "Mrbgems.lock"), "null")

      expect { described_class.new(cwd: root).lock }
        .to raise_error(described_class::LockError, /invalid mrbgems lock file/)
    end
  end

  it "keeps the existing lock and removes its temporary file when replacement fails" do
    Dir.mktmpdir do |root|
      lock_path = File.join(root, "Mrbgems.lock")
      File.write(File.join(root, "Mrbgems"), "")
      File.write(lock_path, "existing\n")
      allow(File).to receive(:rename).and_raise(Errno::EACCES)

      expect { described_class.new(cwd: root).lock(update: true) }.to raise_error(Errno::EACCES)
      expect(File.read(lock_path)).to eq("existing\n")
      expect(Dir.glob("#{lock_path}.tmp-*")).to be_empty
    end
  end

  it "keeps the existing lock when commit resolution fails" do
    Dir.mktmpdir do |root|
      lock_path = File.join(root, "Mrbgems.lock")
      File.write(File.join(root, "Mrbgems"), "gem github: \"example/common\"\n")
      File.write(lock_path, "existing\n")
      manager = described_class.new(cwd: root, resolver: ->(*) { raise described_class::LockError, "failed" })

      expect { manager.lock(update: true) }.to raise_error(described_class::LockError, "failed")
      expect(File.read(lock_path)).to eq("existing\n")
      expect(Dir.glob("#{lock_path}.tmp-*")).to be_empty
    end
  end

  it "rejects lock entries outside the recorded group selection" do
    Dir.mktmpdir do |root|
      contents = {
        "version" => 2,
        "with" => ["production"],
        "gems" => [
          { "type" => "path", "source" => "test-only", "sha256" => "a" * 64,
            "groups" => ["test"] }
        ]
      }
      File.write(File.join(root, "Mrbgems.lock"), JSON.generate(contents))

      expect { described_class.new(cwd: root).read_lock }
        .to raise_error(described_class::LockError, /invalid mrbgems lock entry/)
    end
  end

  it "rejects lock entries belonging to an excluded group" do
    Dir.mktmpdir do |root|
      contents = {
        "version" => 2,
        "with" => %w[production test],
        "without" => ["test"],
        "gems" => [
          { "type" => "path", "source" => "shared", "sha256" => "a" * 64,
            "groups" => %w[production test] }
        ]
      }
      File.write(File.join(root, "Mrbgems.lock"), JSON.generate(contents))

      expect { described_class.new(cwd: root).read_lock }
        .to raise_error(described_class::LockError, /invalid mrbgems lock entry/)
    end
  end

  it "rejects a local directory without mrbgem.rake" do
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "not-a-gem"))
      File.write(File.join(root, "Mrbgems"), "gem path: \"not-a-gem\"\n")

      expect { described_class.new(cwd: root).check }
        .to raise_error(described_class::DefinitionError, /mrbgem\.rake/)
    end
  end
end
