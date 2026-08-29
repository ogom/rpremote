class WS2812SPIFakeSPI
  attr_reader :writes

  def initialize
    @writes = []
  end

  def write(data)
    # SPI consumes the bytes synchronously; retain a snapshot for assertions.
    @writes << data.dup
    data.bytesize
  end
end

class WS2812SPITest < Picotest::Test
  def setup
    require "ws2812_spi"
  end

  def test_encodes_one_pixel_as_grb_at_eight_spi_bits_per_ws2812_bit
    spi = WS2812SPIFakeSPI.new
    strip = WS2812SPI.new(spi: spi, count: 1)
    strip.set_rgb(0, 1, 0, 0).show
    frame = spi.writes[0]

    assert_equal 184, frame.bytesize
    assert_equal "\x00" * 80, frame.byteslice(0, 80)
    assert_equal "\x60" * 8, frame.byteslice(80, 8)
    assert_equal "\x60" * 7 + "\x7c", frame.byteslice(88, 8)
    assert_equal "\x60" * 8, frame.byteslice(96, 8)
    assert_equal "\x00" * 80, frame.byteslice(104, 80)
  end

  def test_fill_get_rgb_and_clear
    spi = WS2812SPIFakeSPI.new
    strip = WS2812SPI.new(spi: spi, count: 2)
    strip.fill(10, 20, 30)
    assert_equal [10, 20, 30], strip.get_rgb(1)

    strip.clear
    assert_equal [0, 0, 0], strip.get_rgb(0)
    assert_equal 1, spi.writes.length
  end

  def test_accepts_hex_colors
    strip = WS2812SPI.new(spi: WS2812SPIFakeSPI.new, count: 1)
    strip.set_hex(0, 0x123456)
    assert_equal [0x12, 0x34, 0x56], strip.get_rgb(0)
  end

  def test_updates_the_reusable_frame_before_show
    spi = WS2812SPIFakeSPI.new
    strip = WS2812SPI.new(spi: spi, count: 1)

    strip.show
    strip.set_rgb(0, 0, 1, 0).show

    assert_equal "\x60" * 8, spi.writes[0].byteslice(80, 8)
    assert_equal "\x60" * 7 + "\x7c", spi.writes[1].byteslice(80, 8)
  end

  def test_one_uses_zero_based_indexes_and_clears_other_leds
    spi = WS2812SPIFakeSPI.new
    strip = WS2812SPI.new(spi: spi, count: 3)
    strip.fill(10, 20, 30)

    strip.one(2, 0x123456)

    assert_equal [0, 0, 0], strip.get_rgb(0)
    assert_equal [0, 0, 0], strip.get_rgb(1)
    assert_equal [0x12, 0x34, 0x56], strip.get_rgb(2)
    assert_equal 1, spi.writes.length
  end

  def test_rejects_invalid_count_index_and_channels
    assert_raise(ArgumentError) do
      WS2812SPI.new(spi: WS2812SPIFakeSPI.new, count: 0)
    end

    strip = WS2812SPI.new(spi: WS2812SPIFakeSPI.new, count: 1)
    assert_raise(IndexError) { strip.set_rgb(1, 0, 0, 0) }
    assert_raise(ArgumentError) { strip.set_rgb(0, 256, 0, 0) }
    assert_raise(ArgumentError) { strip.set_hex(0, 0x1000000) }
    assert_raise(IndexError) { strip.one(1) }
    assert_raise(ArgumentError) { strip.one(0, 0x1000000) }
  end
end
