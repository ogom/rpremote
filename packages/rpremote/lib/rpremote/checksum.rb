# frozen_string_literal: true

require "zlib"

module Rpremote
  module Checksum
    module_function

    def crc16(data, initial = 0xFFFF)
      data.each_byte.reduce(initial) do |crc, byte|
        crc ^= byte << 8
        8.times do
          crc = if crc.nobits?(0x8000)
                  crc << 1
                else
                  (crc << 1) ^ 0x1021
                end
        end
        crc & 0xFFFF
      end
    end

    def crc32(data, initial = 0)
      Zlib.crc32(data, initial)
    end
  end
end
