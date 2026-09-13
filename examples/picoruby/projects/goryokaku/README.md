# Goryokaku illumination and tambourine

[日本語](README.ja.md)

This PicoRuby project controls 380 WS2812B LEDs and a tambourine instrument on a Goryokaku model with a Raspberry Pi Pico 2. It provides `:illumination`, `:musical`, and `:combined` modes.

## Preparation

Read [Hardware and safety](docs/hardware.md) before wiring. The 380 LEDs require a high-current external 5 V supply. Do not power them from the Pico 2.

## Build and run

Lock the dependencies, build and flash the firmware, and run the application from the repository root.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote bootsel
rpremote flash
rpremote run examples/picoruby/projects/goryokaku/main.rb --timeout 120
```

The current `main.rb` runs the `:musical` tambourine input loop until stopped. `:illumination` runs the configured effects and exits, while `:combined` uses touch input to select illumination or tambourine. Press `Ctrl-C` to exit; cleanup silences the buzzer and clears every LED. The same stages can be run as one command when the hardware is connected:

```sh
rpremote deploy --build examples/picoruby/projects/goryokaku --timeout 120
```

After changing `mrbgems/` or the root `Mrbgems`, lock, build, and flash again. A pin-only change in `main.rb` only requires another `rpremote run`.

## Operating modes

See [Operating modes and settings](docs/modes.md) for configuration, setlists, and the individual-pattern catalog.

### Illumination

`main.rb` uses:

```ruby
mode: :illumination,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

This mode can run the `:tests`, `:highlights`, `:story`, or `:showcase` setlist, or one registered pattern. `:story` uses 15 effects to move from the illuminated fort through stars and cherry blossoms to fireworks. The PWM buzzer plays “Twinkle, Twinkle, Little Star” once alongside the LEDs. `repeat: true` repeats the tune too, while `buzzer_volume: 0` disables it. This mode does not initialize the MPU6050 or touch switch.

### Musical

`mode: :musical` skips touch selection. Hold group 5 at the top in Y-up: both smooth Z-axis shake reversals and sharp Z-axis strikes produce a metallic “shan-shan” shimmer. Shakes scan a multicolor afterglow across the star; strikes adapt the `fireworks` effect into a ten-way burst from the star center followed by ravelin and outer-ring flashes.

### Combined

Set `mode: :combined`, the desired `setlist_name`, and `pattern_key: nil` in `main.rb`.

| Action/state | Result |
| --- | --- |
| Start | No candidate; the first Y-up touch selects illumination |
| Press the touch switch while the IMU is Y-up | Change the candidate; the ravelin is red for illumination and blue for tambourine |
| Press the touch switch while the IMU is Z-up | Confirm the displayed candidate |
| Illumination mode | Display the current orientation; on confirmation, play “Twinkle, Twinkle, Little Star” and `setlist_name` once, then restore that display |
| Hold Y-up and shake or strike in tambourine mode | Synchronize the “shan-shan” shimmer with star, ravelin, and outer-ring performance lighting |

Startup prints `GORYOKAKU mode=combined event=start`, and orientation changes print `event=orientation`. Selection prints `event=touch action=select mode=...`, while confirmation prints `event=touch action=confirm mode=...`. An `event=alive` line approximately every five seconds confirms that the idle loop is responsive.

## LED layout and effects

The [LED layout](docs/led_layout.md) assigns the star to addresses 0–169, the ravelin to 170–189, and the outer perimeter to 190–379. The migrated illumination gem includes warm-white and cherry-blossom effects, per-zone fades, trails and rainbows, combined-zone effects, and fireworks.

## File structure

| Path | Responsibility |
| --- | --- |
| `main.rb` | Pin settings and application startup |
| `mrbgems/goryokaku-application/` | Configuration, validation, and composition |
| `mrbgems/goryokaku-runtime/` | Clock, logging, and cooperative event loop |
| `mrbgems/goryokaku-interaction/` | Touch and MPU6050 event detection |
| `mrbgems/goryokaku-illumination/` | 380-LED layout and effects |
| `mrbgems/goryokaku-musical/` | Non-blocking PWM buzzer output |
| `docs/hardware.md` | Wiring, power, and safety |
| `docs/modes.md` | Modes, setlists, and individual patterns |
| `docs/development.md` | Development and verification workflow |

Host tests use mocks to cover zone boundaries, buzzer output, application composition, and cleanup. Verify physical color, timing, power, and the MPU6050 mounting orientation on the hardware.
