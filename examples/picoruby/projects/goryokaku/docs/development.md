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

## Save a log

```sh
mkdir -p tmp/goryokaku-run
rpremote run examples/picoruby/projects/goryokaku --timeout 120 2>&1 \
  | tee tmp/goryokaku-run/output.log
```

For failures, correlate `event=error` with the time at which the LEDs, sound, or orientation became abnormal.
