# 03 speaker

[日本語](README.ja.md)

Each button press drives a piezo buzzer at 1000 Hz, about 3.05% duty cycle, for 200 ms. These settings match `03_speaker.py`: `frequency=1000`, `duty_u16(2000)`, and 200 ms.

## Wiring

- Switch: GP15 (physical pin 20) -> push button -> GND (physical pin 23)
- GP18 (physical pin 24) -> BTL amplifier input
- BTL amplifier `OUT+` -> piezo buzzer `+`
- BTL amplifier `OUT-` -> piezo buzzer `-`

Do not connect either BTL output, `OUT+` or `OUT-`, to GND.

Start with low amplifier gain or volume.

## Run

```sh
rpremote run examples/picoruby/education/03_speaker/main.rb --timeout 15
```

Each press makes a short beep and prints to serial output. Stopping with `Ctrl-C` turns PWM off.
