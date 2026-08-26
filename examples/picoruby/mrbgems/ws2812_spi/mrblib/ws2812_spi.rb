# frozen_string_literal: true

require "spi"

class WS2812SPI
  FREQUENCY = 8_000_000
  MODE = 3

  attr_reader :count

  def initialize(spi:, count:)
    unless count.is_a?(Integer) && count > 0
      raise ArgumentError, "count must be a positive Integer"
    end

    @spi = spi
    @count = count
    @pixels = Array.new(count, 0)
    @frame = _encode(@pixels)
  end

  def set_rgb(index, red, green, blue)
    validate_index(index)
    validate_channel(red, "red")
    validate_channel(green, "green")
    validate_channel(blue, "blue")
    rgb = (red << 16) | (green << 8) | blue
    @pixels[index] = rgb
    _encode_pixel(@frame, index, rgb)
    self
  end

  def set_hex(index, rgb)
    unless rgb.is_a?(Integer) && rgb >= 0 && rgb <= 0xFFFFFF
      raise ArgumentError, "rgb must be an Integer from 0x000000 to 0xFFFFFF"
    end

    set_rgb(index, (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF)
  end

  def get_rgb(index)
    validate_index(index)
    rgb = @pixels[index]
    [(rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF]
  end

  def fill(red, green, blue)
    validate_channel(red, "red")
    validate_channel(green, "green")
    validate_channel(blue, "blue")
    rgb = (red << 16) | (green << 8) | blue
    index = 0
    while index < @count
      @pixels[index] = rgb
      index += 1
    end
    _encode(@pixels, @frame)
    self
  end

  def show
    @spi.write(@frame)
    self
  end

  def clear
    fill(0, 0, 0)
    show
  end

  # Lights one LED and turns every other LED off. Indexes start at 0.
  def one(index, rgb = 0xFFFFFF)
    validate_index(index)
    validate_rgb(rgb)
    fill(0, 0, 0)
    set_hex(index, rgb)
    show
  end

  private

  def validate_index(index)
    return if index.is_a?(Integer) && index >= 0 && index < @count

    raise IndexError, "pixel index out of range: #{index.inspect}"
  end

  def validate_channel(value, name)
    return if value.is_a?(Integer) && value >= 0 && value <= 255

    raise ArgumentError, "#{name} must be an Integer from 0 to 255"
  end

  def validate_rgb(rgb)
    return if rgb.is_a?(Integer) && rgb >= 0 && rgb <= 0xFFFFFF

    raise ArgumentError, "rgb must be an Integer from 0x000000 to 0xFFFFFF"
  end

  private :_encode, :_encode_pixel
end
