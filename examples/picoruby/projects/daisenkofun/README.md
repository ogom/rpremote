# Daisen Kofun illumination, Oximeter, and music sample

[日本語](README.ja.md)

This PicoRuby sample controls 572 LEDs on a Daisen Kofun model and turns heart rate and SpO₂ estimates from a MAX30102 into synchronized light and PWM sound. It provides standalone illumination, standalone Oximeter, and combined modes.

> The Oximeter feature is for learning and presentation effects only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

## Start here

Prepare the wiring and LED power described in [hardware and safety](docs/hardware.md), then run this command from the repository root. Include the build when embedding the mrbgems for the first time.

```sh
rpremote deploy examples/picoruby/projects/daisenkofun --build
```

The current [`main.rb`](main.rb) runs for 60 seconds in `:combined` mode. Place a fingertip on the MAX30102 and observe the heartbeat-driven sound and moat LEDs.

## Guides

- [Hardware and safety](docs/hardware.md) — power, wiring, and amplifier
- [Operating modes and settings](docs/modes.md) — mode and `Application::Config`
- [Development workflow](docs/development.md) — build, run, tests, and device checks
- [Why the project uses mrbgems](docs/mrbgem_migration.md) — design decision and comparison with runtime loading
- [Biometric pulse and music](docs/biometric_pwm_music.md) — relationships among heartbeat, SpO₂, sound, and light
- [Illumination catalog](docs/illuminations.md) — every key, visible effect, setlist order, and selection steps
- [LED layout](docs/led_layout.md) — the 572-LED address map
- [Structure reference](docs/structure.md) — Daisen Kofun features represented by the model

## Architecture

The project consists of five local mrbgems: `Application`, `Runtime`, `Oximeter`, `Musical`, and `Illumination`. Each uses its matching `Daisenkofun` namespace and is embedded in the firmware.
