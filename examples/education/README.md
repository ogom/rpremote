# PicoRuby electronic-craft education

Language: PicoRuby<br>
Boards: Raspberry Pi Pico 2 (Pico 2 W for 07_wifi)<br>
Custom mrbgems: `picoruby-ws2812-plus` for 04 through 06; local `picoruby-my_gems` for 08

[日本語](README.ja.md)

This series introduces electronic craft step by step with Raspberry Pi Pico 2
and PicoRuby, from basic GPIO to sensor-based projects.

`04_ws2812`, `05_mpu6050_a`, and `06_mpu6050_g` require custom R2P2 firmware
that embeds [`picoruby-ws2812-plus`](https://github.com/ksbmyk/picoruby-ws2812-plus).
Because the gem is a C extension embedded at build time, it cannot be added to
the official R2P2 4.0.3 firmware after flashing.

`08_my_gems` verifies the pure-Ruby local mrbgem in
`examples/mrbgems/my_gems`. Both dependencies are built into the same custom
firmware.

## Preparation

Before using WS2812, build and flash the custom firmware included with this
repository. Extra gems are managed in `Mrbgems` and their pinned commits in
`Mrbgems.lock`. Specify the UF2 output name under `firmware/`.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build \
  --language picoruby \
  --language-version 4.0.3 \
  --board pico2 \
  --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

After flashing, check the connection.

```sh
rpremote ports
```

With one Pico 2 connected, run each program. Examples run for about 10 seconds
to leave time for button operation; pass `--timeout 15`.

```sh
rpremote run examples/education/01_blink/main.rb --timeout 15
```

To run an example repeatedly, change `SAMPLES` in `main.rb`. For a program
changed to an infinite loop, observe it with `rpremote monitor` and leave the
local monitor with `Ctrl-]`.

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
| 05 | mpu6050_a | Reads MPU6050 acceleration and shows tilt with WS2812B color. |
| 06 | mpu6050_g | Changes WS2812B color and buzzer sound according to MPU6050 motion. |
| 07 | wifi | Connects Pico 2 W to Wi-Fi and blinks its onboard LED. |
| 08 | my_gems | Loads a local mrbgem and blinks Pico 2's onboard LED. |

## Wiring

### 01 blink

No wiring is needed for Pico 2.

```sh
rpremote run examples/education/01_blink/main.rb --timeout 15
```

### 02 switch

- GP15 (physical pin 20) -> push button -> GND (physical pin 23)
- PicoRuby enables its internal pull-up, so no external resistor is required.

```sh
rpremote run examples/education/02_switch/main.rb --timeout 15
```

### 03 speaker

- Use the same GP15 switch as `02_switch`.
- GP18 (physical pin 24) -> BTL amplifier input
- BTL amplifier `OUT+` -> piezo buzzer `+`
- BTL amplifier `OUT-` -> piezo buzzer `-`
- Do not connect either `OUT+` or `OUT-` to GND.

```sh
rpremote run examples/education/03_speaker/main.rb --timeout 15
```

### 04 ws2812 / 05 mpu6050_a / 06 mpu6050_g

- WS2812B: DIN -> GP14 (physical pin 19), GND -> Pico GND, VDD -> 3V3(OUT)
- Push button (`04_ws2812` only): GP15 -> button -> GND
- MPU6050: SDA -> GP16 (physical pin 21), SCL -> GP17 (physical pin 22), GND -> GND, VCC -> 3V3(OUT)
- `06_mpu6050_g` also uses GP18 -> BTL amplifier input and amplifier `OUT+`/`OUT-` -> piezo buzzer `+`/`-`.

```sh
rpremote run examples/education/04_ws2812/main.rb --timeout 15
rpremote run examples/education/05_mpu6050_a/main.rb --timeout 15
rpremote run examples/education/06_mpu6050_g/main.rb --timeout 15
```

Check the power requirements of the WS2812B module. A level shifter may be
needed to reliably use a 5 V-only module with 3.3 V logic.

### 07 wifi

Pico 2 W and custom R2P2 firmware for `pico2_w` are required. Set Wi-Fi SSID
and password in `main.local.rb`; see [07_wifi](07_wifi/README.md) for details.

```sh
rpremote run examples/education/07_wifi/main.local.rb --timeout 30
```

### 08 my_gems

No wiring is needed for Pico 2. Build firmware after locking the local mrbgem,
then run the example.

```sh
rpremote run examples/education/08_my_gems/main.rb --timeout 15
```

## Evaluation

- Check the final `...: OK` line. Current `rpremote run` does not turn R2P2
  Ruby exceptions into a nonzero exit status, so do not use the exit code alone.
- If I2C fails, check MPU6050 address `0x68`, the SDA/SCL wiring, and 3.3 V power.
- If WS2812B colors are wrong, check DIN/DOUT direction and RGB/GRB order.
