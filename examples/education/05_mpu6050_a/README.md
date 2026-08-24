# 05 mpu6050 acceleration

Language: PicoRuby<br>
Board: Raspberry Pi Pico 2<br>
Custom mrbgem: `picoruby-ws2812-plus`

[日本語](README.ja.md)

Reads MPU6050 acceleration and changes WS2812B color by orientation: level is
green, Y-axis tilt is red, and X-axis tilt is blue.

## Prerequisites

Custom R2P2 firmware containing `ws2812-plus`, as used by `04_ws2812`, is
required.

## Wiring

- WS2812B: DIN -> GP14 (physical pin 19), GND -> GND, VDD -> 3V3(OUT)
- MPU6050: SDA -> GP16 (physical pin 21), SCL -> GP17 (physical pin 22), GND -> GND, VCC -> 3V3(OUT)

## Run

```sh
rpremote run examples/education/05_mpu6050_a/main.rb --timeout 15
```

Serial output shows acceleration and `level`, `X tilt`, or `Y tilt`. The example
succeeds when `mpu6050 tilt: OK` is printed.
