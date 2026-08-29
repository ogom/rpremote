# frozen_string_literal: true

require "tmpdir"

RSpec.describe Rpremote::Config do
  it "loads only options supported by the selected command" do
    Dir.mktmpdir do |cwd|
      path = File.join(cwd, "settings.json")
      File.write(path, <<~JSON)
        {
          "port": "/dev/cu.usbmodem101",
          "mount": "/Volumes/RP2350",
          "cache": "tmp/cache",
          "language": "picoruby",
          "language_version": "3.4.2",
          "board": "pico2",
          "firmware": "firmware/custom.uf2",
          "mrbgems": "Mrbgems",
          "baud": 9600,
          "timeout": 12.5
        }
      JSON

      expect(described_class.load("run", filename: path, cwd: cwd)).to eq(
        port: "/dev/cu.usbmodem101", baud: 9600, timeout: 12.5, language: "picoruby"
      )
      expect(described_class.load("flash", filename: path, cwd: cwd)).to include(
        mount: "/Volumes/RP2350", cache: "tmp/cache", language: "picoruby",
        language_version: "3.4.2", board: "pico2"
      )
      expect(described_class.load("build", filename: path, cwd: cwd)).to include(
        mrbgems: "Mrbgems", firmware: "firmware/custom.uf2"
      )
      expect(described_class.load("deploy", filename: path, cwd: cwd)).to include(
        mount: "/Volumes/RP2350", port: "/dev/cu.usbmodem101", mrbgems: "Mrbgems",
        firmware: "firmware/custom.uf2", baud: 9600, timeout: 12.5
      )
      expect(described_class.load("bootsel", filename: path, cwd: cwd)).to eq(
        mount: "/Volumes/RP2350", port: "/dev/cu.usbmodem101", baud: 9600, timeout: 12.5
      )
      expect(described_class.load("config", filename: path, cwd: cwd)).to include(
        port: "/dev/cu.usbmodem101", mount: "/Volumes/RP2350", mrbgems: "Mrbgems"
      )
    end
  end

  it "treats an absent default file as optional" do
    Dir.mktmpdir do |cwd|
      expect(described_class.load("run", cwd: cwd)).to eq({})
      expect { described_class.load("run", filename: "missing.json", required: true, cwd: cwd) }
        .to raise_error(described_class::Error, /does not exist/)
    end
  end

  it "rejects invalid JSON, unknown options, and invalid values" do
    Dir.mktmpdir do |cwd|
      path = File.join(cwd, "settings.json")

      File.write(path, "[")
      expect { described_class.load("run", filename: path, cwd: cwd) }
        .to raise_error(described_class::Error, /invalid config/)

      File.write(path, '{"unknown": true}')
      expect { described_class.load("run", filename: path, cwd: cwd) }
        .to raise_error(described_class::Error, /unknown config option/)

      File.write(path, '{"timeout": 0}')
      expect { described_class.load("run", filename: path, cwd: cwd) }
        .to raise_error(described_class::Error, /must be positive/)
    end
  end

  it "creates a default object without overwriting an existing config" do
    Dir.mktmpdir do |cwd|
      first = described_class.setup(cwd: cwd)
      second = described_class.setup(cwd: cwd)

      expect(first.created).to be(true)
      expect(second.created).to be(false)
      expect(File.read(first.path)).to eq("{}\n")
    end
  end

  it "allows automatic mrbgem detection to be disabled in config" do
    Dir.mktmpdir do |cwd|
      path = File.join(cwd, "settings.json")
      File.write(path, '{"mrbgems": false}')

      expect(described_class.load("build", filename: path, cwd: cwd)).to eq(mrbgems: false)
    end
  end

  it "extracts a global config option without consuming positional arguments" do
    args = ["run", "main.rb", "--config=project.json", "--timeout", "2"]

    expect(described_class.extract_option!(args)).to eq(["project.json", true])
    expect(args).to eq(["run", "main.rb", "--timeout", "2"])
  end
end
