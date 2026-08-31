# frozen_string_literal: true

class WS2812
  FNV_OFFSET = 2_166_136_261
  FNV_PRIME = 16_777_619
  UINT32_MASK = 0xffff_ffff

  attr_reader :brightness, :checksum, :closed, :frame_count, :invalid_indices, :pixels

  def initialize(pin:, num:, order: :grb)
    raise ArgumentError, "num must be positive" unless num > 0
    raise ArgumentError, "order must be :rgb or :grb" unless order == :rgb || order == :grb

    @pin = pin
    @num = num
    @order = order
    @brightness = 5
    @pixels = Array.new(num, 0)
    @frame_count = 0
    @checksum = FNV_OFFSET
    @invalid_indices = []
    @closed = false
  end

  def brightness=(value)
    value = 0 if value < 0
    value = 100 if value > 100
    @brightness = value
  end

  def set_rgb(index, red, green, blue)
    if index < 0 || index >= @num
      @invalid_indices << index
      return
    end

    @pixels[index] = ((red & 0xff) << 16) | ((green & 0xff) << 8) | (blue & 0xff)
  end

  def fill(red, green, blue)
    index = 0
    while index < @num
      set_rgb(index, red, green, blue)
      index += 1
    end
  end

  def show
    frame_checksum = FNV_OFFSET
    index = 0
    while index < @pixels.length
      color = @pixels[index]
      frame_checksum = checksum_byte(frame_checksum, visible_component(color >> 16))
      frame_checksum = checksum_byte(frame_checksum, visible_component(color >> 8))
      frame_checksum = checksum_byte(frame_checksum, visible_component(color))
      index += 1
    end
    @frame_count += 1
    @checksum = ((@checksum ^ frame_checksum ^ @frame_count) * FNV_PRIME) & UINT32_MASK
    nil
  end

  def clear
    fill(0, 0, 0)
    show
  end

  def close
    @closed = true
  end

  private

  def visible_component(value)
    ((value & 0xff) * @brightness / 100) & 0xff
  end

  def checksum_byte(checksum, byte)
    ((checksum ^ byte) * FNV_PRIME) & UINT32_MASK
  end
end
