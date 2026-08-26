# 06 MPU6050

Language: PicoRuby, Board: Raspberry Pi Pico 2, Custom mrbgem: `picoruby-ws2812-plus`

[日本語](README.ja.md)

Detects orientation and movement from MPU6050 acceleration and reacts with WS2812B color and a piezo buzzer.
Tilting the board slowly shows level in green, Y-axis tilt in red, and X-axis tilt in blue.
Moving it strongly changes the color and sound according to the axis with the greatest change.

## Prerequisites

Custom R2P2 firmware containing `ws2812-plus`, as used by `04_ws2812`, is required.

## Wiring

- WS2812B: DIN -> GP14 (physical pin 19), GND -> GND, VDD -> 3V3(OUT)
- MPU6050: SDA -> GP16 (physical pin 21), SCL -> GP17 (physical pin 22), GND -> GND, VCC -> 3V3(OUT)
- Piezo buzzer: GP18 (physical pin 24) -> BTL amplifier input, `OUT+` -> buzzer `+`, `OUT-` -> buzzer `-`

Do not connect either BTL output, `OUT+` or `OUT-`, to GND.

## Run

```sh
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

The serial output shows `level`, `X tilt`, or `Y tilt` according to orientation.
Moving the board strongly prints `X: shake`, `Y: pico`, or `Z: don` and changes the color and sound.
The example succeeds when `mpu6050: OK` is printed.
