# picoruby-ws2812_spi

[日本語](README.ja.md)

`picoruby-ws2812_spi` drives WS2812-compatible addressable RGB LEDs through an SPI COPI pin. Ruby manages pixels and the SPI transaction; the C extension converts RGB pixels to the GRB waveform bytes used by the reference implementation.

The class is named `WS2812SPI` so it can coexist with the repository's PIO/RMT-based `WS2812` gem.

## Add the mrbgem

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/ws2812_spi"
```

```sh
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
```

## Usage

```ruby
require "spi"
require "ws2812_spi"

spi = SPI.new(
  unit: :RP2040_SPI0,
  frequency: WS2812SPI::FREQUENCY,
  sck_pin: 2,
  copi_pin: 3,
  mode: WS2812SPI::MODE
)
leds = WS2812SPI.new(spi: spi, count: 8)
leds.set_rgb(0, 255, 0, 0)
leds.set_hex(1, 0x00FF00)
leds.show

# Turn all LEDs off except the final one.
leds.one(7)
```

Connect the LED DIN signal to the SPI COPI pin, GP3 in this example. GP2 is configured as SPI SCK but is not connected to the LED strip. No chip-select or CIPO connection is used.

The timing depends on exactly 8 MHz, mode 3, MSB-first SPI. Each WS2812 data bit becomes one SPI byte: `0x60` for zero and `0x7c` for one. The encoded frame begins and ends with 80 zero bytes (80 us each) to provide reset and latch intervals. The encoded frame is reused, so `show` performs no memory allocation and adds no fixed delay.

The SPI transmission time per frame is `160 + 24 * LED count` us. For example, 8 LEDs take 352 us and 64 LEDs take 1,696 us.

## API

| Method | Description |
| --- | --- |
| `WS2812SPI.new(spi:, count:)` | Create a strip with all pixels initially off. |
| `set_rgb(index, red, green, blue)` | Set one pixel using 0–255 channels. |
| `set_hex(index, rgb)` | Set one pixel using `0xRRGGBB`. |
| `get_rgb(index)` | Return one pixel as `[red, green, blue]`. |
| `fill(red, green, blue)` | Set all pixels without transmitting. |
| `show` | Encode and transmit the current pixels. |
| `clear` | Turn off and transmit all pixels. |
| `one(index, rgb = 0xFFFFFF)` | Turn off every LED, then light one 0-based index and transmit. |

## Electrical notes

Use a power supply sized for the LED count, join the LED and Pico grounds, and do not power a strip from a GPIO pin. A 3.3 V-to-5 V logic-level shifter is recommended when the LEDs are powered at 5 V. The application is responsible for limiting brightness and current.

## License

MIT License. See [LICENSE](LICENSE).
