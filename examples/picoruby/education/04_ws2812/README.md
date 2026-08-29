# 04 ws2812

[日本語](README.ja.md)

Each button press selects one of seven colors for a WS2812B connected to GP14.

## Prerequisites

Custom R2P2 firmware containing `ws2812-plus` is required. Build and flash it with the repository-root `Mrbgems` and `Mrbgems.lock` files.

```sh
rpremote mrbgems check
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

## Wiring

- WS2812B: DIN -> GP14 (physical pin 19), GND -> GND, VDD -> 3V3(OUT)
- Button: GP15 (physical pin 20) -> push button -> GND

Check the WS2812B module power requirements. A 5 V-only module may require a level shifter.

## Run

```sh
rpremote run examples/picoruby/education/04_ws2812/main.rb --timeout 15
```

Each press prints `color 1/7` through `color 7/7` and changes the LED color. The example succeeds when `ws2812: OK` is printed.
