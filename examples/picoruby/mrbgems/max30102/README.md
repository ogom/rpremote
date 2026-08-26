# picoruby-max30102

[日本語](README.ja.md)

`picoruby-max30102` configures a MAX30102 over I2C and reads coherent 18-bit red and infrared FIFO samples. Ruby handles device setup and register access; the C extension decodes each six-byte FIFO frame.

## Add the mrbgem

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/max30102"
```

```sh
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
```

## Usage

```ruby
require "i2c"
require "max30102"

i2c = I2C.new(unit: :RP2040_I2C0, sda_pin: 16, scl_pin: 17, frequency: 400_000)
sensor = MAX30102.new(i2c: i2c)

if sensor.sample_available?
  sample = sensor.read
  puts "red=#{sample[:red]}, ir=#{sample[:ir]}"
end
```

The defaults reproduce the reference sensor configuration: four-sample FIFO averaging without rollover, SpO2 mode, 4096 nA ADC range, 100 samples per second, 411 us pulse width, and `0x24` red/IR LED amplitudes. The FIFO is cleared during setup.

## Wiring

- VIN -> the voltage accepted by your MAX30102 breakout board
- GND -> GND
- SDA -> GP16
- SCL -> GP17

The MAX30102 IC itself uses low-voltage supplies. Confirm that the breakout board includes the required regulator and I2C level shifting before connecting it to a Pico.

## API

| Method                                   | Description                                             |
| ---------------------------------------- | ------------------------------------------------------- |
| `MAX30102.new(i2c:, ...)`                | Verifies, resets, and configures the sensor.            |
| `connected?`, `part_id`, `revision_id`   | Inspect device identity.                                |
| `available_samples`, `sample_available?` | Inspect unread FIFO data.                               |
| `read`, `read_fifo`                      | Return one `{ red:, ir: }` 18-bit sample.               |
| `clear_fifo`                             | Reset FIFO write, overflow, and read pointers.          |
| `temperature`                            | Return the internal die temperature in degrees Celsius. |
| `shutdown`, `wake`, `reset`              | Control sensor power state.                             |

Constructor options are `fifo_average:`, `sample_rate:`, `pulse_width:`, `adc_range:`, `red_led_amplitude:`, and `ir_led_amplitude:`.

## Scope and safety

This driver returns raw optical samples. It does not calculate heart rate or SpO2, detect finger placement, reject motion artifacts, or provide a medical measurement. Heart-rate estimation requires signal filtering, peak detection, timing, and validation for the sensor placement and intended use.

Register definitions and the default setup follow the official [MAX30102 data sheet](https://www.analog.com/media/en/technical-documentation/data-sheets/max30102.pdf).

## License

MIT License. See [LICENSE](LICENSE).
