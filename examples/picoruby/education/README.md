# PicoRuby electronic-craft education

Language: PicoRuby, Boards: Pico 2 (Pico 2 W for 10), Custom mrbgems: `picoruby-ws2812-plus` (04 and 06), local `picoruby-my_gems` (08-09)

[日本語](README.ja.md)

This series introduces electronic craft step by step with Raspberry Pi Pico 2 and PicoRuby, from basic GPIO to sensor-based projects.

`04_ws2812` and `06_mpu6050` require custom R2P2 firmware that embeds `picoruby-ws2812-plus`.
Because the gem is a C extension embedded at build time, it cannot be added to the official R2P2 4.0.3 firmware after flashing.

`08_my_gems` verifies the pure-Ruby local mrbgem, and `09_my_gems_dfu` updates only an application that uses it through DFU.
The extra mrbgems are embedded in the same custom firmware.

## Preparation

Before using WS2812, build and flash the custom firmware included with this repository.
Extra gems are managed in `Mrbgems` and their pinned commits in `Mrbgems.lock`.
Specify the UF2 output name under `firmware/`.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

After flashing, check the connection.

```sh
rpremote ports
```

With one Pico 2 connected, run each program. Examples run for about 10 seconds to leave time for button operation; pass `--timeout 15`.

```sh
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

To run an example repeatedly, change `SAMPLES` in `main.rb`.
For a program changed to an infinite loop, observe it with `rpremote monitor` and leave the local monitor with `Ctrl-]`.

## Safety

- GPIO and ADC are 3.3 V only. Do not connect 5 V to GPIO, ADC, or I2C signals.
- Always place a 330 ohm to 1 kohm resistor in series with an LED.
- Do not drive motors, relays, or high-current LEDs directly from GPIO.
- Disconnect USB before changing wiring.

## Lessons

| No. | Topic | What it does |
| --- | --- | --- |
| 01 | blink | Blinks Pico 2's onboard LED (GP25) and writes to serial output. |
| 02 | switch | Reads a GP15 push button and controls the onboard LED. |
| 03 | speaker | Uses a GP15 button to drive a piezo buzzer on GP18. |
| 04 | ws2812 | Changes a WS2812B on GP14 through seven colors with a button. |
| 06 | mpu6050 | Changes color and buzzer sound according to MPU6050 orientation and movement. |
| 07 | dfu | Updates an app from v1 to v2 and tests rollback after a failed startup. |
| 08 | my_gems | Loads a local mrbgem and blinks Pico 2's onboard LED. |
| 09 | my_gems_dfu | Updates an application that uses a local mrbgem through DFU. |
| 10 | wifi | Connects Pico 2 W to Wi-Fi and blinks its onboard LED. |

## Wiring

### 01 blink

No wiring is needed for Pico 2.

```sh
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

### 02 switch

- GP15 (physical pin 20) -> push button -> GND (physical pin 23)
- PicoRuby enables its internal pull-up, so no external resistor is required.

```sh
rpremote run examples/picoruby/education/02_switch/main.rb --timeout 15
```

### 03 speaker

- Use the same GP15 switch as `02_switch`.
- GP18 (physical pin 24) -> BTL amplifier input
- BTL amplifier `OUT+` -> piezo buzzer `+`
- BTL amplifier `OUT-` -> piezo buzzer `-`
- Do not connect either `OUT+` or `OUT-` to GND.

```sh
rpremote run examples/picoruby/education/03_speaker/main.rb --timeout 15
```

### 04 ws2812 / 06 mpu6050

- WS2812B: DIN -> GP14 (physical pin 19), GND -> Pico GND, VDD -> 3V3(OUT)
- Push button (`04_ws2812` only): GP15 -> button -> GND
- MPU6050: SDA -> GP16 (physical pin 21), SCL -> GP17 (physical pin 22), GND -> GND, VCC -> 3V3(OUT)
- `06_mpu6050` also uses GP18 -> BTL amplifier input and amplifier `OUT+`/`OUT-` -> piezo buzzer `+`/`-`.

```sh
rpremote run examples/picoruby/education/04_ws2812/main.rb --timeout 15
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

Check the power requirements of the WS2812B module. A level shifter may be needed to reliably use a 5 V-only module with 3.3 V logic.

### 07 dfu

No wiring is needed for Pico 2.
PicoModem DFU updates only the application, so BOOTSEL mode and UF2 reflashing are not needed.
Deploy stable v1, update it to v2, and verify automatic recovery from a failed startup.
See [07_dfu](07_dfu/README.md) for the full procedure.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v1.rb
rpremote reset
rpremote dfu status
```

### 08 my_gems

No wiring is needed for Pico 2. Build firmware after locking the local mrbgem, then run the example.

```sh
rpremote run examples/picoruby/education/08_my_gems/main.rb --timeout 15
```

### 09 my_gems_dfu

Keep the local mrbgem embedded for `08_my_gems` in place and update only its application from v1 to v2 through DFU.
See [09_my_gems_dfu](09_my_gems_dfu/README.md) for the full procedure.

```sh
rpremote dfu app examples/picoruby/education/09_my_gems_dfu/app_v1.rb
rpremote reset
rpremote dfu status
```

### 10 wifi

Pico 2 W and custom R2P2 firmware for `pico2_w` are required.
Set Wi-Fi SSID and password in `main.local.rb`; see [10_wifi](10_wifi/README.md) for details.

```sh
rpremote run examples/picoruby/education/10_wifi/main.local.rb --timeout 30
```

## Evaluation

- Check the final `...: OK` line and exit status 0. When Ruby raises an exception, `rpremote run` displays it and exits nonzero.
- If I2C fails, check MPU6050 address `0x68`, the SDA/SCL wiring, and 3.3 V power.
- If WS2812B colors are wrong, check DIN/DOUT direction and RGB/GRB order.
