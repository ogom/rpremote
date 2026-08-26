# picoruby-mpu6050

[日本語](README.ja.md)

`picoruby-mpu6050` reads the MPU6050's three-axis acceleration and three-axis gyroscope values in one I2C burst.
Ruby handles the public API, register configuration, and unit conversion. The C extension decodes the 14-byte sensor frame into signed 16-bit values.

## Add the mrbgem

Add the local gem to the project `Mrbgems` file. This repository already includes the following entry:

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/mpu6050"
```

Lock and build the custom firmware after changing the gem:

```sh
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
```

## Usage

```ruby
require "i2c"
require "mpu6050"

i2c = I2C.new(
  unit: :RP2040_I2C0,
  sda_pin: 16,
  scl_pin: 17,
  frequency: 400_000
)
sensor = MPU6050.new(i2c: i2c)

sample = sensor.read
ax, ay, az = sample[:acceleration] # g
gx, gy, gz = sample[:gyroscope]    # degrees per second
temperature = sample[:temperature] # degrees Celsius
```

`read` starts at `ACCEL_XOUT_H` (`0x3B`) and reads 14 bytes with one repeated-start I2C transaction. The acceleration, temperature, and gyroscope values therefore belong to the same sensor frame.

## Wiring

- VCC -> 3V3(OUT)
- GND -> GND
- SDA -> GP16
- SCL -> GP17
- AD0 -> GND for address `0x68`, or 3V3 for `0x69`

GPIO and I2C signals are 3.3 V only.

## API

| Method                                                                    | Description                                                         |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `MPU6050.new(i2c:, address: 0x68, accel_range: :g2, gyro_range: :dps250)` | Verifies, wakes, and configures the sensor.                         |
| `connected?`                                                              | Returns whether `WHO_AM_I` identifies an MPU6050.                   |
| `who_am_i`                                                                | Returns the raw `WHO_AM_I` register.                                |
| `read`                                                                    | Returns one scaled acceleration, temperature, and gyroscope sample. |
| `read_raw`                                                                | Returns the same sample as signed register values.                  |
| `motion6`                                                                 | Returns `[ax, ay, az, gx, gy, gz]` in g and degrees per second.     |
| `motion6_raw`                                                             | Returns the same six axes as signed register values.                |
| `acceleration`                                                            | Reads and returns `[ax, ay, az]` in g.                              |
| `gyroscope`                                                               | Reads and returns `[gx, gy, gz]` in degrees per second.             |
| `temperature`                                                             | Reads and returns the temperature in degrees Celsius.               |

Use `read` when the application needs coherent acceleration and gyroscope values. The single-purpose accessors each start a new measurement transaction.

Supported acceleration ranges are `:g2`, `:g4`, `:g8`, and `:g16`. Supported gyroscope ranges are `:dps250`, `:dps500`, `:dps1000`, and `:dps2000`. The defaults match the ElectronicCats initialization: +/-2 g, +/-250 degrees per second, and the X-axis gyroscope PLL clock.

## Scope

This example gem implements direct six-axis sampling, temperature, selectable ranges, both I2C addresses, and identity checking. DMP, FIFO, interrupts, offsets, and calibration are outside its current scope.

See [06_mpu6050](../../education/06_mpu6050/README.md) for a finite hardware example that combines this sensor with a WS2812B and a buzzer.

## License

MIT License. See [LICENSE](LICENSE).
