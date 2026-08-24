# 02 switch

Language: PicoRuby<br>
Board: Raspberry Pi Pico 2<br>
Custom mrbgem: none

[日本語](README.ja.md)

Reads a push button and lights the onboard LED only while the button is pressed.

## Wiring

- GP15 (physical pin 20) -> push button -> GND (physical pin 23)
- PicoRuby uses the internal pull-up, so no external resistor is required.

## Run

```sh
rpremote run examples/education/02_switch/main.rb --timeout 15
```

Pressing the button prints `LED ON`; releasing it prints `LED OFF`. The example
succeeds when `switch: OK` is printed at the end.
