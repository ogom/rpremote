# Daisen Kofun illumination and Oximeter sample

[日本語](README.ja.md)

This PicoRuby sample runs 572-LED illuminations on a Daisen Kofun model and estimates heart rate and SpO2 with a MAX30102 on a Raspberry Pi Pico 2. It turns off every LED and shuts down the sensor on exit.

> The Oximeter feature is for learning and presentation effects only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

## Start here

Prepare the wiring and LED power described in [hardware and safety](docs/hardware.md), then build, flash, and run the sample from the repository root:

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

The default application plays the `:tests` illumination setlist. When it finishes, `DAISENKOFUN mode=illumination event=done status=ok` confirms success. For iterative work and the fastest device checks with `rpremote exec`, see the [development workflow](docs/development.md).

## Guides

- [Development workflow](docs/development.md) — deployment, `rpremote exec`, edit–run loop, firmware rebuilds, and serial logs.
- [Operating modes and settings](docs/modes.md) — illumination, Oximeter, combined operation, GPIO, brightness, and setlists.
- [Hardware and safety](docs/hardware.md) — power requirements and wiring.

## Reference

- [Illumination catalog](docs/illuminations.md) — all selectable illumination patterns.
- [LED layout](docs/led_layout.md) — the model's 572-LED address map.
- [Structure reference](docs/structure.md) — Daisen Kofun features represented by the model.
- [mrbgem migration record](docs/mrbgem_migration.md) — historical loading and migration experiments.
