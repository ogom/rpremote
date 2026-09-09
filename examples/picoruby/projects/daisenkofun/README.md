# Daisen Kofun illumination, Oximeter, and music sample

[日本語](README.ja.md)

This PicoRuby sample runs 572-LED illuminations on a Daisen Kofun model and estimates heart rate and SpO2 with a MAX30102 on a Raspberry Pi Pico 2. Combined mode turns the biological pulse into a PWM canon that travels through the three moats with synchronized LEDs, and can derive a personal “heartbeat signature” from eight beats. It turns off every LED and shuts down the sensor on exit.

The current CoC-based mrbgem structure has been verified on physical Pico 2 hardware with the MAX30102, status LEDs, 572-LED illumination, and PWM buzzer.

> The Oximeter feature is for learning and presentation effects only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

## Start here

Prepare the wiring and LED power described in [hardware and safety](docs/hardware.md), then build, flash, and run the sample from the repository root:

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

The current [`main.rb`](main.rb) measures for 60 seconds in `:combined` mode, uses GP14 for the 572 LEDs, GP16/GP17 for the MAX30102, GP2/GP3 for status-LED SPI, and GP18 for the buzzer. It plays a `:heartbeat_signature` every eight beats. Place a fingertip on the MAX30102, then check sound and moat-LED synchronization, the return to the canon after a signature, and the final `event=verification` line. See [operating modes and settings](docs/modes.md) for every `Application::Config` option and the [development workflow](docs/development.md) for iterative device checks.

## mrbgem structure

The project follows one CoC across its local mrbgems: the gem name, require name, implementation directory, and root namespace use the same singular component name.

| mrbgem | Require / implementation directory | Root namespace | Main responsibility |
| --- | --- | --- | --- |
| `picoruby-daisenkofun-application` | `daisenkofun-application` / `mrblib/daisenkofun-application/` | `Daisenkofun::Application` | Configuration, composition, execution, verification, and cleanup |
| `picoruby-daisenkofun-runtime` | `daisenkofun-runtime` / `mrblib/daisenkofun-runtime/` | `Daisenkofun::Runtime` | Shared clock, logger, and cooperative event loop |
| `picoruby-daisenkofun-oximeter` | `daisenkofun-oximeter` / `mrblib/daisenkofun-oximeter/` | `Daisenkofun::Oximeter` | MAX30102 device lifecycle, measurement, events, and status LEDs |
| `picoruby-daisenkofun-musical` | `daisenkofun-musical` / `mrblib/daisenkofun-musical/` | `Daisenkofun::Musical` | Subscriber, translators, planners, and PWM outputs |
| `picoruby-daisenkofun-illumination` | `daisenkofun-illumination` / `mrblib/daisenkofun-illumination/` | `Daisenkofun::Illumination` | LED device, display, playback, and biometric patterns |

## Guides

- [Development workflow](docs/development.md) — deployment, `rpremote exec`, edit–run loop, firmware rebuilds, and serial logs.
- [Operating modes and settings](docs/modes.md) — illumination, Oximeter, combined operation, GPIO, brightness, and setlists.
- [Hardware and safety](docs/hardware.md) — power requirements and wiring.
- [Biometric pulse to PWM melody](docs/biometric_pwm_music.md) — MAX30102 input, pitch, duration, PWM duty, kofun canon, heartbeat signature, and moat LED synchronization.

## Reference

- [Illumination catalog](docs/illuminations.md) — all selectable illumination patterns.
- [LED layout](docs/led_layout.md) — the model's 572-LED address map.
- [Structure reference](docs/structure.md) — Daisen Kofun features represented by the model.
- [mrbgem migration record](docs/mrbgem_migration.md) — historical loading and migration experiments.
