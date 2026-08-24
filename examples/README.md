# rpremote Examples

Language: PicoRuby<br>
Boards: Raspberry Pi Pico 2 and Pico 2 W<br>
Custom mrbgems: `picoruby-ws2812-plus` for 04 through 06; local `picoruby-my_gems` for 08

[日本語](README.ja.md)

This directory contains PicoRuby hardware examples for [rpremote](../README.md).
Run all commands from the repository root.

## Education series

The [education series](education/README.md) progresses from GPIO basics to a
sensor-driven project on Raspberry Pi Pico 2.

| Example | Description | Hardware |
| --- | --- | --- |
| [01_blink](education/01_blink/README.md) | Blink the onboard LED. | Pico 2 |
| [02_switch](education/02_switch/README.md) | Read a push button and control an LED. | Button |
| [03_speaker](education/03_speaker/README.md) | Drive a piezo buzzer through a BTL amplifier. | Button, amplifier, buzzer |
| [04_ws2812](education/04_ws2812/README.md) | Change a WS2812B through seven colors. | Button, WS2812B |
| [05_mpu6050_a](education/05_mpu6050_a/README.md) | Display accelerometer tilt as color. | MPU6050, WS2812B |
| [06_mpu6050_g](education/06_mpu6050_g/README.md) | React to motion with color and sound. | MPU6050, WS2812B, buzzer |
| [07_wifi](education/07_wifi/README.md) | Connect Pico 2 W to Wi-Fi. | Pico 2 W, Wi-Fi access point |
| [08_my_gems](education/08_my_gems/README.md) | Verify a project-local mrbgem with the onboard LED. | Pico 2 |

## Prepare and run

The repository `Mrbgems` includes `picoruby-ws2812-plus` for examples 04 through
06 and the local `examples/mrbgems/my_gems` for example 08.

```sh
rpremote setup
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run examples/education/01_blink/main.rb --timeout 15
```

Read the individual example before wiring it. GPIO, ADC, and I2C signals are
3.3 V only; disconnect USB before changing the circuit.

## PicoModem DFU

[dfu/app.rb](dfu/README.md) is a minimal application that confirms a successful
PicoModem DFU boot.
