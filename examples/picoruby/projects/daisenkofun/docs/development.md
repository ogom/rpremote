# Development workflow

[日本語](development.ja.md)

First connect the Pico 2, LED power, MAX30102, and PWM amplifier according to [hardware and safety](hardware.md).

## Build and deploy

When a local mrbgem, `Mrbgems`, or a driver changes, deploy with a firmware build:

```sh
rpremote deploy examples/picoruby/projects/daisenkofun --build
```

The project embeds its five local mrbgems in firmware instead of compiling many Ruby files sequentially on the device. See [why the project uses mrbgems](mrbgem_migration.md) for the reasoning and tradeoffs.

## Change settings and run

When only mode, duration, pins, volume, or another value in [`main.rb`](../main.rb) changes, run without rebuilding firmware:

```sh
rpremote run examples/picoruby/projects/daisenkofun --timeout 120
```

See [operating modes and settings](modes.md) for configuration. A successful finite run prints `event=done status=ok`.

## Check one component

Use `rpremote exec` for a short check of an embedded component or pattern:

```sh
rpremote exec 'require "daisenkofun-illumination"; Daisenkofun::Illumination::Player.new.play_pattern(:structure_guide)' --timeout 120
```

## Run host specifications

RSpec verifies internal contracts such as configuration, event order, musical transformation, LED layout, mrbgem loading, and documentation links.

```sh
cd packages/rpremote
bundle exec rake spec:daisenkofun
```

The Picotest files under each mrbgem retain representative PicoRuby and mruby/c compatibility checks. They do not replace RSpec or physical-device checks.

## Check the physical device

Check the areas affected by the change:

- `:illumination`: selected pattern, clear-on-exit, and repeat behavior
- `:oximeter`: finger arrival/removal, estimates, and status LEDs
- `:combined`: sound and moat-LED synchronization, mute, and clean exit
- power or wiring: no hangs, overheating, LED corruption, or I2C errors

Host tests cannot verify power delivery, perceived PWM volume, real-time LED output, or sensor quality.

## Save logs

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined.log
```

For failures, correlate `event=error`, `event=loop_warning`, and `event=fifo_backlog` with the time that visible or audible symptoms occurred.
