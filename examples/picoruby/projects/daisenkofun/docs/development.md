# Development workflow

[日本語](development.ja.md)

Use a Raspberry Pi Pico 2 with the wiring and external LED power described in [hardware and safety](hardware.md). From the repository root, build, flash, and run the sample:

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

This builds firmware with the local Daisen Kofun mrbgems, flashes it to the Pico 2, reconnects to the R2P2 Shell, and runs `main.rb`. Flashing replaces the firmware installed on the Pico 2. On the first installation, when serial BOOTSEL entry is unavailable, connect the Pico 2 while holding its BOOTSEL button.

The current `main.rb` measures for 60 seconds in `:combined` mode and runs `:heartbeat_signature`. For a short illumination-only check, set the `Application::Config` options to `mode: :illumination`, `setlist_name: :tests`, `repeat: false`, and `duration_ms: nil`. After the firmware is on the Pico 2, choose the workflow that matches the files you changed.

| Changed files | What to do |
| --- | --- |
| `main.rb` only | Run the application script again. |
| `mrbgems/` (including `daisenkofun-application`), `Mrbgems`, or a hardware driver | Check dependencies, rebuild, flash, then run the application script. |

## Fastest device check: `rpremote exec`

`rpremote exec` sends one Ruby expression directly to the R2P2 Shell. It is the lightest way to verify functionality already included in the flashed firmware: there is no `main.rb` upload and no firmware rebuild.

For example, run only `structure_guide` from the repository root:

```sh
rpremote exec 'require "daisenkofun-illumination"; Daisenkofun::Illumination::Player.new.play_pattern(:structure_guide)' --timeout 120
```

The illumination mrbgem is not auto-required, so the expression loads it explicitly. Use `rpremote exec` for focused checks of an embedded component or pattern; use `rpremote run` when verifying the `main.rb` configuration, mode selection, and full application lifecycle.

The selected pattern runs, turns the LEDs off, and returns to the R2P2 Shell. `DAISENKOFUN mode=illumination event=led_off` confirms that the illumination cleaned up.

## Edit and run `main.rb`

Use this loop for mode selection, setlist selection, pattern selection, and measurement duration changes.

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

`rpremote run` uploads only the execution copy of `main.rb` to `/home/.rpremote-run.rb`; no `fs push` or `lib/daisenkofun` synchronization is needed. See [operating modes and settings](modes.md) for the available settings.

When a finite run completes successfully, the application writes `DAISENKOFUN mode=<selected mode> event=done status=ok`. If it reports `status=error`, use the error class and message in the same line to correct the configuration or hardware issue before running it again.

The CoC-refactored runtime, Oximeter, musical, and illumination mrbgems have completed this device check on physical Pico 2 hardware. Treat that result as the release baseline and rerun the relevant mode after any mrbgem, driver, wiring, threshold, or timing change.

`--timeout 120` is the maximum time without R2P2 Shell output, not the total application runtime. The Oximeter default measurement duration is 60 seconds, and continuing measurement logs reset the timeout.

## Update a DFU app for continuous playback

The repeat API changes an embedded mrbgem, so first rebuild and flash the firmware using the steps below. Then verify `repeat = true` in `main.rb` and update the boot application:

```sh
rpremote dfu app examples/picoruby/projects/daisenkofun/main.rb
rpremote reset
```

Subsequent changes confined to `main.rb`, such as the repeat setting or setlist selection, need only this DFU update and restart. During continuous playback, check that the `event=pattern` index returns to `1` after the last entry instead of waiting for a completion log.

## Rebuild firmware

When changing an mrbgem, `Mrbgems`, or a hardware driver, run the following from the repository root:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

Flashing replaces the firmware installed on the Pico 2. After flashing, use the edit-and-run command above.

## Minimal host regression suite

The retained Picotest suite is intentionally limited to behavior that is difficult to confirm consistently by observation. Hardware interaction and full-application behavior are checked on the physical Pico 2.

| Component | Retained coverage |
| --- | --- |
| Application | [`config_test.rb`](../mrbgems/daisenkofun-application/test/config_test.rb): mode defaults and public configuration validation |
| Runtime | [`event_loop_test.rb`](../mrbgems/daisenkofun-runtime/test/event_loop_test.rb): start, tick, reverse-order stop, and failure cleanup |
| Oximeter | [`measurement_processor_test.rb`](../mrbgems/daisenkofun-oximeter/test/measurement_processor_test.rb): finger, beat, measurement, pulse-shape, and reset events |
| Musical | [`heartbeat_signature_planner_test.rb`](../mrbgems/daisenkofun-musical/test/heartbeat_signature_planner_test.rb) and [`kofun_canon_output_test.rb`](../mrbgems/daisenkofun-musical/test/kofun_canon_output_test.rb): deterministic signature and scheduled PWM canon |
| Illumination | [`patterns_test.rb`](../mrbgems/daisenkofun-illumination/test/patterns_test.rb), [`biometric_player_test.rb`](../mrbgems/daisenkofun-illumination/test/biometric_player_test.rb), and [`moat_canon_test.rb`](../mrbgems/daisenkofun-illumination/test/moat_canon_test.rb): all 32 saved pattern outputs and biometric rendering |

`patterns_test.rb` compares generated frames with [`pattern_baselines.rb`](../mrbgems/daisenkofun-illumination/test/pattern_baselines.rb), preserving the visible output of every presentation pattern during internal refactoring.

## Verify the heartbeat melody

The retained musical tests cover the fixed note sequence, PWM duties, and canon schedule. For device verification, connect the PWM buzzer from education example 03_speaker to GP18, along with MAX30102 and the 572 LEDs, and use `main.rb` as the application entry point.

The refactored `Musical::Subscriber`, planners, outputs, Oximeter device lifecycle, and synchronized illumination have been verified together on the physical device. A new release candidate must still repeat the check and retain its `event=verification` result.

Set the `Daisenkofun::Application::Config` in `main.rb` as follows. Use `:kofun_canon` for the canon alone, or `:heartbeat_signature` for the eight-beat signature.

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :combined,
  duration_ms: 60_000,
  buzzer_pin: 18,
  musical_style: :heartbeat_signature
)
```

Build and flash the mrbgems, then run:

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 90
```

Keep a finger in place for the complete 60-second measurement. `source=canon` identifies ordinary canon notes and `source=heartbeat_signature` identifies signature notes generated from eight beats. Confirm audio and moat-boundary LEDs stay synchronized, the canon resumes after the eight-note signature, and finger removal immediately mutes output and restarts collection after replacement.

The final `event=verification status=ok` means at least 15 cues played with no start delay above 25 ms. The summary includes `cues`, `max_delay_ms`, and, for `:heartbeat_signature`, `signatures`. Per-note logs include normalized `pulse_width_ratio`, approximate `pulse_width_ms`, IR `pulse_amplitude`, and PWM `duty_percent`.

Logged frequencies are PWM requests. The separate fixed-125-MHz calculation issue on Pico 2 is unchanged; actual pitch accuracy needs separate verification.

## Capture serial logs

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined-10min.log
```

Use a separate filename for each run. During long tests, correlate `event=fifo_backlog`, `event=loop_warning`, `event=error`, and `event=done` with the time at which LED corruption is observed.
