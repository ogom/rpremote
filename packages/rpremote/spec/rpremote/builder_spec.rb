# frozen_string_literal: true

require "rpremote/builder"
require "tmpdir"

RSpec.describe Rpremote::Builder do
  it "runs the repository firmware build script" do
    calls = []
    runner = lambda do |*arguments, **keywords|
      calls << [arguments, keywords]
      true
    end
    output = StringIO.new
    error = StringIO.new

    Dir.mktmpdir do |root|
      source = File.join(root, "firmware", "picoruby-4.0.3")
      FileUtils.mkdir_p(source)
      described_class.new(root: root, runner: runner).build(
        mrbgems: false, output: output, error: error
      )

      arguments, keywords = calls.fetch(0)
      expect(arguments).to eq([{ "RPREMOTE_LANGUAGE_VERSION" => "4.0.3",
                                 "RPREMOTE_LANGUAGE" => "picoruby",
                                 "RPREMOTE_BOARD" => "pico2",
                                 "RPREMOTE_ROOT" => root,
                                 "PICORUBY_DIR" => source,
                                 "RPREMOTE_FIRMWARE" => File.join(root, "firmware/picoruby-4.0.3-pico2.uf2") },
                               RbConfig.ruby,
                               File.expand_path("../../tasks/firmware_build.rb", __dir__)])
      expect(keywords).to include(chdir: root, out: output, err: error)
    end
  end

  it "builds PicoRuby 3.4.2 from its prepared cache directory" do
    calls = []
    runner = lambda do |*arguments, **keywords|
      calls << [arguments, keywords]
      true
    end

    Dir.mktmpdir do |root|
      source = File.join(root, "firmware", "picoruby-3.4.2")
      FileUtils.mkdir_p(source)
      described_class.new(root: root, runner: runner).build(
        language_version: "3.4.2", mrbgems: false
      )

      arguments, = calls.fetch(0)
      expect(arguments.first).to eq(
        "RPREMOTE_LANGUAGE_VERSION" => "3.4.2",
        "RPREMOTE_LANGUAGE" => "picoruby",
        "RPREMOTE_BOARD" => "pico2",
        "RPREMOTE_ROOT" => root,
        "PICORUBY_DIR" => source,
        "RPREMOTE_FIRMWARE" => File.join(root, "firmware/picoruby-3.4.2-pico2.uf2")
      )
    end
  end

  it "applies the bundled PicoRuby source patch before building" do
    events = []
    source_patcher = ->(source, version) { events << [:patch, source, version] }
    runner = lambda do |*|
      events << [:build]
      true
    end

    Dir.mktmpdir do |root|
      source = File.join(root, "firmware", "picoruby-4.0.3")
      FileUtils.mkdir_p(source)
      described_class.new(root: root, runner: runner, source_patcher: source_patcher).build(mrbgems: false)

      expect(events).to eq([[:patch, source, "4.0.3"], [:build]])
    end
  end

  it "explains when the prepared PicoRuby source is missing" do
    expect { described_class.new(root: "/tmp/rpremote-missing").build }
      .to raise_error(Rpremote::Builder::Error, /Run `rpremote setup/)
  end

  it "removes only the project's build directory" do
    Dir.mktmpdir do |directory|
      build_directory = File.join(directory, "build")
      firmware_directory = File.join(directory, "firmware")
      FileUtils.mkdir_p([build_directory, firmware_directory])
      File.write(File.join(build_directory, "generated.txt"), "build output")
      File.write(File.join(firmware_directory, "firmware.uf2"), "firmware output")
      output = StringIO.new

      described_class.new(root: directory).clean(output: output)

      expect(File.exist?(build_directory)).to be(false)
      expect(File.exist?(File.join(firmware_directory, "firmware.uf2"))).to be(true)
      expect(output.string).to eq("removed build files: #{build_directory}\n")
    end
  end

  it "passes the generated Mrbgems overlay to the firmware build" do
    calls = []
    runner = lambda do |*arguments, **keywords|
      calls << [arguments, keywords]
      true
    end
    manager = instance_double(
      Rpremote::Mrbgems,
      path: "/project/Mrbgems",
      lock_path: "/project/Mrbgems.lock",
      vm: :mrubyc,
      generate_overlay: Rpremote::Mrbgems::Overlay.new(
        path: "/project/build/mrbgems/config.rb", fingerprint: "abc123def456"
      )
    )
    mrbgems_class = class_double(Rpremote::Mrbgems, new: manager)

    Dir.mktmpdir do |directory|
      source = File.join(directory, "firmware", "picoruby-4.0.3")
      FileUtils.mkdir_p(File.join(source, "build_config"))
      File.write(File.join(directory, "Mrbgems"), "")
      File.write(File.join(source, "build_config", "r2p2-femtoruby-pico2.rb"), "")

      described_class.new(root: directory, runner: runner, mrbgems_class: mrbgems_class).build
    end

    environment = calls.fetch(0).first.first
    expect(environment).to include(
      "RPREMOTE_MRUBY_CONFIG" => "/project/build/mrbgems/config.rb",
      "RPREMOTE_MRBGEMS_FINGERPRINT" => "abc123def456",
      "RPREMOTE_CONFIG_NAME" => "r2p2-femtoruby-pico2"
    )
  end
end
