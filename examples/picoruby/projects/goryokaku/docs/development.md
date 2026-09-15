# Development workflow

[日本語](development.ja.md)

Follow [hardware and safety](hardware.md), then work from the repository root.

## Build and deploy

In the root `Mrbgems`, enable the five Goryokaku mrbgems as the only project-specific gems. After changing an mrbgem, `mrbgem.rake`, or `Mrbgems`, update the lock and rebuild the firmware:

```sh
rpremote mrbgems lock
rpremote deploy --build examples/picoruby/projects/goryokaku --timeout 120
```

When only the mode, pins, or volume in `main.rb` changes, run it temporarily against the embedded firmware:

```sh
rpremote run examples/picoruby/projects/goryokaku --timeout 120
```

## Temporary execution and startup after reset

`main.rb` execution through `rpremote run` or `deploy` is temporary. Use it for verification. Register a DFU startup application only when the Goryokaku application should start automatically after the Pico 2 resets:

```sh
rpremote dfu app examples/picoruby/projects/goryokaku/main.rb
rpremote dfu status
rpremote reset
```

After a successful start, the application calls `DFU.confirm` to confirm the candidate slot. Before registering it, verify that firmware containing all five required mrbgems is installed. Changing an mrbgem requires a firmware rebuild and flash in addition to updating the DFU application.

To remove the startup application, run the following commands. `dfu remove` permanently clears both A/B application slots.

```sh
rpremote dfu remove
rpremote reset
```

## Check one pattern

```sh
rpremote exec 'require "goryokaku-illumination"; Goryokaku::Illumination::Player.new.play_pattern(:warm_white)' --timeout 120
```

A successful run reports `event=done status=ok`. A failure reports `status=error` after cleanup.

## Run host specifications

RSpec verifies configuration, event order, mode selection, tambourine transformation, LED layout, mrbgem loading, and documentation links:

```sh
rake spec:examples:picoruby:goryokaku
```

Picotest files inside each mrbgem retain representative PicoRuby and mruby/c compatibility checks. They do not replace RSpec or physical-device checks.

## Physical-device checks

- `:illumination`: selected effect and tune, repetition, and silence/blackout during cleanup
- `:musical`: stable Y-up, gentle shakes, short strikes, no stationary false notes, and synchronized sound and light
- `:combined`: red/blue selection in Y-up, confirmation in Z-up, and restoration of orientation display
- Hardware: current and temperature at maximum brightness, I2C, PWM volume, and MPU6050 mounting orientation

Host tests cannot verify physical color, power capacity, sound level, sensor sensitivity, or real-time synchronization.

## Read the log

| Log | Meaning and check |
| --- | ----------------- |
| `mode=... event=start` | The selected mode started |
| `event=pattern index=... key=...` | The effect and position that started within the setlist |
| `event=led_off` | Cleanup cleared every LED |
| `event=orientation mode=y_up|z_up|x_up|unknown` | Current orientation recognized from the MPU6050 |
| `event=touch action=select mode=...` | A Y-up touch changed the candidate |
| `event=touch action=confirm mode=...` | A Z-up touch confirmed the displayed candidate |
| `event=touch action=ignored ...` | Touch was ignored because no candidate existed or the orientation was unsupported |
| `event=alive` | The combined-mode event loop is still running |
| `event=done status=ok` | The run completed normally |
| `event=done status=error` | The run failed after cleanup; inspect the preceding exception |

`status=ok` alone does not prove physical color, loudness, gesture sensitivity, or synchronization. Correlate the log with the model's behavior.

## Save a log

```sh
mkdir -p tmp/goryokaku-run
rpremote run examples/picoruby/projects/goryokaku --timeout 120 2>&1 \
  | tee tmp/goryokaku-run/output.log
```

For failures, correlate `event=error` with the time at which the LEDs, sound, or orientation became abnormal.
