# rpremote PicoRuby Examples

[日本語](README.ja.md)

These examples use PicoRuby R2P2 on Raspberry Pi Pico 2 and Pico 2 W. Run all commands from the repository root.

## Education series

The [education series](education/README.md) progresses from GPIO basics to a sensor-driven project.

| Example                                              | Description                                                     | Hardware                     |
| ---------------------------------------------------- | --------------------------------------------------------------- | ---------------------------- |
| [01_blink](education/01_blink/README.md)             | Blink the onboard LED.                                          | Pico 2                       |
| [02_switch](education/02_switch/README.md)           | Read a push button and control an LED.                          | Button                       |
| [03_speaker](education/03_speaker/README.md)         | Drive a piezo buzzer through a BTL amplifier.                   | Button, amplifier, buzzer    |
| [04_ws2812](education/04_ws2812/README.md)           | Change a WS2812B through seven colors.                          | Button, WS2812B              |
| [06_mpu6050](education/06_mpu6050/README.md)         | React to orientation and movement with color and sound.         | MPU6050, WS2812B, buzzer     |
| [07_dfu](education/07_dfu/README.md)                 | Verify application updates and rollback after a failed startup. | Pico 2                       |
| [08_my_gems](education/08_my_gems/README.md)         | Verify a project-local mrbgem with the onboard LED.             | Pico 2                       |
| [09_my_gems_dfu](education/09_my_gems_dfu/README.md) | Update an application that uses a local mrbgem through DFU.     | Pico 2                       |
| [10_wifi](education/10_wifi/README.md)               | Connect Pico 2 W to Wi-Fi.                                      | Pico 2 W, Wi-Fi access point |

## Prepare and run

The [oximeter project](projects/oximeter/README.md) combines the local MAX30102 and SPI WS2812 mrbgems to estimate heart rate and SpO2 and display its state on eight NeoPixels.

```sh
rpremote setup
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

Read the individual example before wiring it. GPIO, ADC, and I2C signals are 3.3 V only; disconnect USB before changing the circuit.

## PicoModem DFU

[education/07_dfu](education/07_dfu/README.md) demonstrates PicoModem DFU boot confirmation, rollback, and a v1 to v2 update.
[education/09_my_gems_dfu](education/09_my_gems_dfu/README.md) keeps a local mrbgem in firmware while updating only its application through DFU.
