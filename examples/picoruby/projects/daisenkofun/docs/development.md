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

## Temporary execution and startup after reset

`main.rb` execution through `rpremote run` or `deploy` is temporary. Use it for verification. Register a DFU startup application only when the Daisen Kofun application should start automatically after the Pico 2 resets:

```sh
rpremote dfu app examples/picoruby/projects/daisenkofun/main.rb
rpremote dfu status
rpremote reset
```

After a successful start, the application calls `DFU.confirm` to confirm the candidate slot. Before registering it, verify that firmware containing all five required mrbgems is installed. Changing an mrbgem requires a firmware rebuild and flash in addition to updating the DFU application.

To remove the startup application, run the following commands. `dfu remove` permanently clears both A/B application slots.

```sh
rpremote dfu remove
rpremote reset
```

## Check one component

Use `rpremote exec` for a short check of an embedded component or pattern:

```sh
rpremote exec 'require "daisenkofun-illumination"; Daisenkofun::Illumination::Player.new.play_pattern(:structure_guide)' --timeout 120
```

## Run host specifications

RSpec verifies internal contracts such as configuration, event order, musical transformation, LED layout, mrbgem loading, and documentation links.

```sh
rake spec:examples:picoruby:daisenkofun
```

The Picotest files under each mrbgem retain representative PicoRuby and mruby/c compatibility checks. They do not replace RSpec or physical-device checks.

## Check the physical device

Check the areas affected by the change:

- `:illumination`: selected pattern, clear-on-exit, and repeat behavior
- `:oximeter`: finger arrival/removal, estimates, and status LEDs
- `:combined`: sound and moat-LED synchronization, mute, and clean exit
- power or wiring: no hangs, overheating, LED corruption, or I2C errors

Host tests cannot verify power delivery, perceived PWM volume, real-time LED output, or sensor quality.

## Read the log

| Log | Meaning and check |
| --- | ----------------- |
| `mode=... event=start` | The selected mode started |
| `component=oximeter event=measurement_start` | The MAX30102 was initialized and measurement began |
| `event=finger_detected` / `event=finger_removed` | Finger arrival/removal was recognized |
| `event=measurement_updated ... state=result` | Heart-rate and SpO₂ estimates were updated |
| `component=kofun_canon event=note ...` | A scheduled PWM and moat-LED cue ran |
| `component=musical event=verification status=ok` | Cue count and start delay met the runtime checks |
| `event=led_off` or `component=illumination event=stop` | Cleanup cleared the illumination |
| `event=done status=ok` | The run completed normally |
| `event=done status=error error=...` | The run failed after cleanup; inspect the error class and message |
| `event=fifo_backlog` / `event=loop_warning` | Sensor work backed up / an event-loop delay was detected |

`status=ok` alone does not prove physical loudness, LED color, synchronization accuracy, or sensor quality. Correlate the log with the model's behavior.

## Save logs

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined.log
```

For failures, correlate `event=error`, `event=loop_warning`, and `event=fifo_backlog` with the time that visible or audible symptoms occurred.
