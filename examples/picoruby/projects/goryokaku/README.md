# Goryokaku illumination and tambourine

[日本語](README.ja.md)

This PicoRuby project controls 380 WS2812B LEDs, an MPU6050, a touch switch, and a PWM buzzer on a Goryokaku model with a Raspberry Pi Pico 2. It provides illumination, tambourine performance, and touch-selected combined operation.

> The 380 LEDs require a high-current external 5 V supply. Do not power them from the Pico 2.

## Start here

Follow [hardware and safety](docs/hardware.md). In the root `Mrbgems`, enable the five Goryokaku mrbgems and disable mrbgems belonging to other projects. Then run from the repository root:

```sh
rpremote mrbgems lock
rpremote deploy --build examples/picoruby/projects/goryokaku --timeout 120
```

The current [`main.rb`](main.rb) runs the `:highlights` setlist in `:illumination` mode. Cleanup silences the buzzer and clears every LED, including when execution is interrupted.

## Guides

- [Hardware and safety](docs/hardware.md) — power, wiring, amplifier, and MPU6050 orientation
- [Operating modes and settings](docs/modes.md) — three modes, touch selection, and tambourine performance
- [Illumination catalog](docs/illuminations.md) — 21 keys, visible effects, setlist order, and selection steps
- [LED layout](docs/led_layout.md) — 380 addresses and wiring direction
- [Structure reference](docs/structure.md) — Goryokaku structure and model mapping
- [Development workflow](docs/development.md) — build, run, tests, and device checks

## Operating modes

| mode | Behavior |
| --- | --- |
| `:illumination` | Plays LED effects with “Twinkle, Twinkle, Little Star” |
| `:musical` | Plays the shake/strike tambourine with synchronized sound and light in Y-up |
| `:combined` | Selects a candidate with a Y-up touch and confirms it with a Z-up touch |

The project is embedded in firmware as five local mrbgems: `Application`, `Runtime`, `Interaction`, `Musical`, and `Illumination`.
