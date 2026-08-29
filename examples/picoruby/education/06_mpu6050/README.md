# 06 MPU6050

[日本語](README.ja.md)

Reads the MPU6050's three-axis acceleration and three-axis gyroscope values together, detects orientation and movement, and reacts with WS2812B color and a piezo buzzer.
Tilting the board slowly shows level in green, Y-axis tilt in red, and X-axis tilt in blue.
Moving it strongly changes the color and sound according to the axis with the greatest change.

## Prerequisites

Custom R2P2 firmware containing `ws2812-plus` and the local [`mpu6050`](../../mrbgems/mpu6050/README.md) gem is required. Both are already declared in the project-root `Mrbgems` file.

## Wiring

- WS2812B: DIN -> GP14 (physical pin 19), GND -> GND, VDD -> 3V3(OUT)
- MPU6050: SDA -> GP16 (physical pin 21), SCL -> GP17 (physical pin 22), GND -> GND, VCC -> 3V3(OUT)
- Piezo buzzer: GP18 (physical pin 24) -> BTL amplifier input, `OUT+` -> buzzer `+`, `OUT-` -> buzzer `-`

Do not connect either BTL output, `OUT+` or `OUT-`, to GND.

## Run

```sh
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

The serial output shows all six `ax`/`ay`/`az` and `gx`/`gy`/`gz` values from one sensor frame, followed by `level`, `X tilt`, or `Y tilt` according to orientation.
Moving the board strongly prints `X: shake`, `Y: pico`, or `Z: don` and changes the color and sound.
The example succeeds when `mpu6050: OK` is printed.
