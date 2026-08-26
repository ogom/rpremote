# picoruby-bmi270

[日本語](README.ja.md)

This mrbgem configures a Bosch BMI270 over I2C and reads coherent three-axis acceleration and gyroscope frames. Ruby performs initialization, register access, and scaling; the C extension provides the Bosch configuration data and decodes the 12-byte little-endian frame.

## Initialization

BMI270 requires Bosch's 8192-byte configuration file during initialization. This gem embeds the configuration data used by the repository's Spresense implementation under Bosch's BSD-3-Clause license. Pass an 8192-byte `configuration:` String only when overriding the bundled data.

```ruby
require "bmi270"
require "i2c"

i2c = I2C.new(unit: :RP2040_I2C0, frequency: 400_000, sda_pin: 16, scl_pin: 17)
sensor = BMI270.new(i2c: i2c, address: 0x68, accel_range: :g2, gyro_range: :dps2000, odr: :hz100)
sample = sensor.read
```

Connect SDA to GP16 and SCL to GP17 for the example above. The driver supports the BMI270's primary address `0x68` and secondary address `0x69` at 400 kHz.

Acceleration ranges are ±2/4/8/16 g; gyroscope ranges are ±125/250/500/1000/2000 degrees per second. ODR symbols range from `:hz25` through `:hz1600`. The defaults follow the reference implementation: ±2 g, ±2000 degrees per second, and 100 Hz. `read` returns acceleration in g, gyroscope values in degrees per second, and temperature in degrees Celsius. Raw gyroscope X is corrected using BMI270's ZX cross-axis sensitivity factor.

The basic driver does not expose FIFO, interrupts, step/activity features, auxiliary magnetometers, or CRT calibration. Absolute yaw requires a magnetometer and sensor fusion outside this six-axis driver.

## License

The mrbgem code is MIT licensed. The bundled Bosch configuration data is covered by [LICENSE-BOSCH](LICENSE-BOSCH) (BSD-3-Clause) and is based on the official [Bosch BMI270 SensorAPI](https://github.com/boschsensortec/BMI270_SensorAPI).
