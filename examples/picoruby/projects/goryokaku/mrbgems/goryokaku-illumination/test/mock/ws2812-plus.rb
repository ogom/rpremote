# frozen_string_literal: true

class WS2812
  FNV_OFFSET = 2_166_136_261
  FNV_PRIME = 16_777_619
  UINT32_MASK = 0xffff_ffff

  attr_reader :brightness, :buffer_write_count, :checksum, :closed,
              :frame_count, :invalid_indices, :pixels, :set_rgb_count

  class << self
    attr_reader :last_instance
  end

  def initialize(pin:, num:, order: :grb)
    @pin = pin
    @num = num
    @order = order
    @brightness = 100
    @pixels = Array.new(num, 0)
    @frame_count = 0
    @buffer_write_count = 0
    @set_rgb_count = 0
    @checksum = FNV_OFFSET
    @invalid_indices = []
    @closed = false
    self.class.instance_variable_set(:@last_instance, self)
  end

  def brightness=(value); @brightness = value; end

  def set_rgb(index, red, green, blue)
    @set_rgb_count += 1
    unless index >= 0 && index < @num
      @invalid_indices << index
      return
    end
    @pixels[index] = ((red & 0xff) << 16) | ((green & 0xff) << 8) | (blue & 0xff)
  end

  def replace_pixels(pixels)
    @pixels = pixels.dup
    @buffer_write_count += 1
  end

  def show
    frame_checksum = FNV_OFFSET
    index = 0
    while index < @pixels.length
      color = @pixels[index]
      frame_checksum = checksum_byte(frame_checksum, color >> 16)
      frame_checksum = checksum_byte(frame_checksum, color >> 8)
      frame_checksum = checksum_byte(frame_checksum, color)
      index += 1
    end
    @frame_count += 1
    @checksum = ((@checksum ^ frame_checksum ^ @frame_count) * FNV_PRIME) & UINT32_MASK
  end

  def clear
    @pixels = Array.new(@num, 0)
    show
  end

  def close; @closed = true; end

  private

  def checksum_byte(checksum, byte)
    ((checksum ^ (byte & 0xff)) * FNV_PRIME) & UINT32_MASK
  end
end
