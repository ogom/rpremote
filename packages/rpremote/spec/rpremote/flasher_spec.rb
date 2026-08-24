# frozen_string_literal: true

require "tmpdir"

RSpec.describe Rpremote::Flasher do
  def create_bootsel(root, name: "RP2350", info: "Board-ID: RP2350\n")
    mount = File.join(root, name)
    Dir.mkdir(mount)
    File.write(File.join(mount, described_class::INFO_FILE), info)
    mount
  end

  def create_uf2(path)
    block = +"\0".b * described_class::UF2_BLOCK_SIZE
    block[0, 8] = [described_class::UF2_MAGIC_START0, described_class::UF2_MAGIC_START1].pack("V2")
    block[-4, 4] = [described_class::UF2_MAGIC_END].pack("V")
    File.binwrite(path, block)
    block
  end

  it "copies UF2 to an RP2350 drive and waits for the serial port" do
    Dir.mktmpdir do |root|
      mount = create_bootsel(root)
      uf2 = File.join(root, "r2p2.uf2")
      uf2_data = create_uf2(uf2)
      flasher = described_class.new(
        volumes_root: root,
        mount_probe: ->(_path) { false },
        port_probe: -> { "/dev/cu.usbmodem1101" }
      )

      result = flasher.flash(uf2)

      expect(result.mount).to eq(mount)
      expect(result.port).to eq("/dev/cu.usbmodem1101")
      expect(File.binread(result.destination)).to eq(uf2_data)
    end
  end

  it "recognizes Pico 2 from INFO_UF2.TXT on a nonstandard mount name" do
    Dir.mktmpdir do |root|
      mount = create_bootsel(root, name: "CUSTOM", info: "Model: Raspberry Pi Pico 2\n")

      expect(described_class.new(volumes_root: root).find_mount).to eq(mount)
    end
  end

  it "rejects an RP2040 BOOTSEL drive" do
    Dir.mktmpdir do |root|
      create_bootsel(root, name: "RPI-RP2", info: "Board-ID: RPI-RP2\n")

      expect { described_class.new(volumes_root: root).find_mount }
        .to raise_error(described_class::MountNotFoundError, /not found/)
    end
  end

  it "rejects a non-UF2 input" do
    Dir.mktmpdir do |root|
      input = File.join(root, "firmware.bin")
      File.binwrite(input, "data")

      expect { described_class.new(volumes_root: root).flash(input) }
        .to raise_error(described_class::InvalidTargetError, /\.uf2 extension/)
    end
  end

  it "rejects a malformed file with a UF2 extension" do
    Dir.mktmpdir do |root|
      input = File.join(root, "firmware.uf2")
      File.binwrite(input, "not UF2")

      expect { described_class.new(volumes_root: root).flash(input) }
        .to raise_error(described_class::InvalidTargetError, /valid UF2/)
    end
  end

  it "times out if the BOOTSEL drive does not disappear" do
    Dir.mktmpdir do |root|
      mount = create_bootsel(root)
      uf2 = File.join(root, "r2p2.uf2")
      create_uf2(uf2)
      flasher = described_class.new(
        volumes_root: root,
        timeout: 0.001,
        mount_probe: ->(_path) { true },
        sleeper: ->(_seconds) {}
      )

      expect { flasher.flash(uf2, mount: mount) }
        .to raise_error(described_class::TimeoutError, /drive to disappear/)
    end
  end
end
