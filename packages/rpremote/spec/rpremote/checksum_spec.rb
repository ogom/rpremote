# frozen_string_literal: true

RSpec.describe Rpremote::Checksum do
  describe ".crc16" do
    it "matches the CRC-16/CCITT-FALSE check value" do
      expect(described_class.crc16("123456789")).to eq(0x29B1)
    end
  end

  describe ".crc32" do
    it "matches the standard CRC32 check value" do
      expect(described_class.crc32("123456789")).to eq(0xCBF43926)
    end

    it "can be updated incrementally" do
      crc = described_class.crc32("1234")
      expect(described_class.crc32("56789", crc)).to eq(described_class.crc32("123456789"))
    end
  end
end
