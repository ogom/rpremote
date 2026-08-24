# 01 blink

Language: PicoRuby<br>
Board: Raspberry Pi Pico 2<br>
Custom mrbgem: none

[日本語](README.ja.md)

Blinks the Pico 2 onboard LED (GP25) five times and writes status to serial
output.

## Wiring

No wiring is needed for Pico 2.

## Run

Run from the repository root.

```sh
rpremote run examples/education/01_blink/main.rb --timeout 15
```

The example succeeds when `blink: OK` is printed and the LED blinks five times.
