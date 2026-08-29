# frozen_string_literal: true

require "tmpdir"
require "rpremote/nuke_firmware"

RSpec.describe Rpremote::NukeFirmware do
  it "downloads the official universal nuke UF2 into firmware" do
    Dir.mktmpdir do |directory|
      firmware = described_class.new(
        directory: directory,
        fetcher: lambda do |url|
          expect(url).to eq(described_class::URL)
          "uf2-data"
        end
      )

      path = firmware.setup

      expect(path).to eq(File.join(directory, "nuke_universal.uf2"))
      expect(File.binread(path)).to eq("uf2-data")
    end
  end

  it "reuses an existing download unless forced" do
    Dir.mktmpdir do |directory|
      path = File.join(directory, "nuke_universal.uf2")
      File.binwrite(path, "existing")
      firmware = described_class.new(directory: directory, fetcher: ->(_url) { "replacement" })

      expect(firmware.setup).to eq(path)
      expect(File.binread(path)).to eq("existing")
      firmware.setup(force: true)
      expect(File.binread(path)).to eq("replacement")
    end
  end
end
