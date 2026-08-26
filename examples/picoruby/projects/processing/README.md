# IMU orientation monitor for Processing

[日本語](README.ja.md)

This project reads a six-axis IMU and streams a common CSV protocol to Processing. It supports the local [`picoruby-mpu6050`](../../mrbgems/mpu6050/README.md) and [`picoruby-bmi270`](../../mrbgems/bmi270/README.md) I2C gems. The orientation and gesture code does not depend on a sensor-specific API.

- [`etc/graph/graph.pde`](etc/graph/graph.pde) plots acceleration, angular velocity, and estimated orientation. See the [graph README](etc/graph/README.md) for field meanings.
- [`etc/model/model.pde`](etc/model/model.pde) applies the estimated orientation to a 3D Pico 2 model. See the [3D model README](etc/model/README.md) for display details.

## Select an IMU

Edit `Processing::Config::IMU_TYPE` in [`lib/processing/config.rb`](lib/processing/config.rb):

```ruby
IMU_TYPE = :mpu6050 # or :bmi270
IMU_ADDRESS = 0x68 # or 0x69
```

`Processing::Unit.build` selects `Processing::Units::Mpu6050` or `Processing::Units::Bmi270`. Both units return acceleration in g, angular velocity in degrees per second, and temperature in degrees Celsius. Add another unit with the same `name` and `read` contract under `lib/processing/units` to use another IMU.

BMI270 has no 120 Hz ODR, so it is configured for 200 Hz and the application samples at 120 Hz.

## Wiring

Both supported IMUs use I2C at 400 kHz:

- VCC -> Pico 2 3V3(OUT)
- GND -> Pico 2 GND
- SDA -> Pico 2 GP16
- SCL -> Pico 2 GP17
- Address-select pin -> the level required for I2C address `0x68`

GPIO and I2C signals are 3.3 V only. Disconnect USB before changing the circuit.

## Prepare and install

The project-root `Mrbgems` embeds both local IMU gems. Build and flash PicoRuby 4.0.3, then copy the configuration, units, and stream before staging the launcher:

```sh
rpremote mrbgems check
rpremote build
rpremote bootsel
rpremote flash
rpremote fs push examples/picoruby/projects/processing/lib/processing :/lib/processing
rpremote dfu app examples/picoruby/projects/processing/main.rb
rpremote reset
```

`lib/processing/` contains reusable configuration, IMU-unit, and stream code under the `Processing` module. Copy it to R2P2's `/lib/processing` before installing the launcher.

`main.rb` checks the selected IMU and starts the stream as a background Sandbox task before calling `DFU.confirm`. The R2P2 Shell therefore remains available.

Each unit averages two seconds of stationary gyroscope readings, retains the three-axis bias, and subtracts it from every subsequent reading. The stream samples at 120 Hz, estimates an IMU-only quaternion on the Pico 2, and sends telemetry at 20 Hz.

Each class has its own matching snake_case file. `Processing::Unit` selects the configured unit, and `Processing::Units::Base` contains the shared calibration and bias-correction behavior. The remaining classes under `Processing::Units` contain only sensor-specific construction. `Processing::Orientation` and `Processing::GestureDetector` are independent from `Processing::Stream`, which runs sampling and telemetry.

When returning to temporary `rpremote run` development, remove the persistent boot application first so its logs do not overlap:

```sh
rpremote dfu remove
rpremote reset
```

```text
IMU_DATA,sensor,timestamp_ms,temperature_c,ax_g,ay_g,az_g,gx_dps,gy_dps,gz_dps,q0,q1,q2,q3,roll_deg,pitch_deg,yaw_relative_deg,posture,gesture
```

## Run Processing

Install Processing 4 and its Serial library, then run either sketch. Both accept the common `IMU_DATA` protocol and show the selected sensor name.

Each sketch prefers `/dev/cu.usbmodem101`, which carries the IMU stream on the current R2P2 firmware. Only one program can open this port: close `rpremote monitor` and do not run another `rpremote` command while Processing is displaying data.

The Processing Console prints the received sensor, acceleration, gyroscope, and orientation once per second; this confirms the selected port is carrying IMU data. Press `R` to reset the estimate and recalibrate.

The current R2P2 firmware exposes Application, Debug, and MIDI CDC ports, usually `/dev/cu.usbmodem101`, `103`, and `105`. The observed Ruby IMU stream is carried by Application CDC (`101`), so this is the default `PREFERRED_PORT`. Adjust it if your Mac assigns different paths.

## Orientation limitations

MPU6050 and BMI270 are six-axis IMUs without magnetometers. Roll and pitch use gravity correction, but `yaw_relative_deg` is relative to calibration and gradually drifts; it is not absolute yaw. Gesture detection reports tilt posture and debounced `TAP`/`SHAKE` events.
