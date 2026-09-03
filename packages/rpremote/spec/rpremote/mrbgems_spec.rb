# frozen_string_literal: true

require "rpremote/mrbgems"
require "tmpdir"

RSpec.describe Rpremote::Mrbgems do
  let(:commit) { "a" * 40 }

  def create_local_gem(root, name = "my-led")
    directory = File.join(root, name)
    FileUtils.mkdir_p(File.join(directory, "mrblib"))
    File.write(File.join(directory, "mrbgem.rake"), <<~RUBY)
      MRuby::Gem::Specification.new('my-led') do |spec|
        spec.require_name = "my_led"
      end
    RUBY
    File.write(File.join(directory, "mrblib", "my_led.rb"), "class MyLed; end\n")
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

      overlay = manager.generate_overlay(
        base_config: base, target: "r2p2-picoruby-pico2", directory: File.join(root, "build")
      )
      generated = File.read(overlay.path)

      expect(generated).to include("load #{base.inspect}")
      expect(generated).to include("checksum_hash: #{commit.inspect}")
      expect(generated).to include("conf.gem #{local.inspect}")
      expect(File.read(base)).to eq(original)
      expect(overlay.fingerprint).to match(/\A[0-9a-f]{12}\z/)
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
