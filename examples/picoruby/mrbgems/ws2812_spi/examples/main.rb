require "spi"
require "ws2812_spi"

BRIGHTNESS = 4

spi = SPI.new(
  unit: :RP2040_SPI0,
  frequency: WS2812SPI::FREQUENCY,
  sck_pin: 2,
  copi_pin: 3,
  mode: WS2812SPI::MODE
)
leds = WS2812SPI.new(spi: spi, count: 8)
leds.set_rgb(0, BRIGHTNESS, 0, 0)
leds.set_hex(1, BRIGHTNESS << 8)
leds.show

# Turn all LEDs off except the final one.
leds.one(7, (BRIGHTNESS << 16) | (BRIGHTNESS << 8) | BRIGHTNESS)
