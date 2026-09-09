# Operating modes and settings

[日本語](modes.ja.md)

Set the `Daisenkofun::Application::Config` values in [`main.rb`](../main.rb) to choose one application behavior. The modes are mutually exclusive.

| `mode` | Use it when you want to… | Additional settings |
| --- | --- | --- |
| `:illumination` | Play a setlist or one illumination pattern. | `setlist_name` or `pattern_key`, `repeat` |
| `:oximeter` | Measure with the MAX30102 and show its status on eight LEDs. | `duration_ms` |
| `:combined` | Run measurement, status LEDs, beat-synchronized illumination, and musical behavior together. | `duration_ms`, `buzzer_pin`, `musical_style` |

`setlist_name` and `pattern_key` cannot be used together. `duration_ms` must be a positive integer and defaults to `Oximeter::Config::RUN_DURATION_MS` (60 seconds) in Oximeter and combined modes.

## Configuration reference

These are the defaults resolved by `Daisenkofun::Application::Config`. The current `main.rb` supplies the same GPIO values explicitly and sets `duration_ms: 60_000`.

| Option | Default or resolved value | Used by |
| --- | --- | --- |
| `mode` | `:combined` | Application mode |
| `setlist_name` | `nil`; resolves to `:highlights` in illumination mode when no pattern is selected | Illumination mode |
| `pattern_key` | `nil` | Illumination mode |
| `repeat` | `false` | Illumination mode |
| `duration_ms` | `nil`; resolves to `60_000` in Oximeter and combined modes | Oximeter and combined modes |
| `ws2812_pin` | `14` | 572-LED illumination data |
| `i2c_sda_pin` / `i2c_scl_pin` | `16` / `17` | MAX30102 I2C |
| `spi_sck_pin` / `spi_copi_pin` | `2` / `3` | Eight status LEDs through `RP2040_SPI0` |
| `buzzer_pin` | `18`; `nil` selects silent output | Combined mode |
| `musical_style` | `:heartbeat_signature` | Combined mode |

The mode must be `:illumination`, `:oximeter`, or `:combined`; the musical style must be `:pulse_translation`, `:kofun_canon`, or `:heartbeat_signature`. All five WS2812/I2C/SPI pin values must be non-negative integers. These values are validated before hardware is initialized.

## Illumination mode

Use `:illumination` to play a setlist or exactly one registered pattern. It does not initialize the MAX30102 or the eight Oximeter status LEDs.

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :illumination,
  setlist_name: :tests, # or :highlights, :story, :showcase
  pattern_key: nil,
  repeat: false,
  duration_ms: nil
)
```

To play one pattern, set `setlist_name = nil` and provide a registered `pattern_key`. `:tests` is the short verification setlist and plays `structure_guide`. See the [illumination catalog](illuminations.md) for pattern descriptions and [`setlist.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/setlist.rb) for setlist contents.

Set `repeat = true` to repeat the whole setlist or the selected pattern until interrupted. With `false`, playback ends after one pass and turns the LEDs off. The current `main.rb` is configured for combined mode; use the `:tests` and `repeat = false` settings above for a short illumination check. Other modes ignore `repeat`. Illumination does not accept `duration_ms`.

For direct calls, use `Daisenkofun::Illumination::Player#play_setlist(:story, repeat: true)` or `Daisenkofun::Illumination::Player#play_pattern(:sunrise, repeat: true)`. Omitting `repeat:` plays once. Continuous playback keeps the LED connection open and clears and closes it when an exception exits playback. The normal completion log `event=done status=ok` does not appear while playback continues.

## Oximeter mode

Use `:oximeter` to measure heart rate and SpO2 with the MAX30102. It controls the MAX30102 and eight status LEDs, but does not start the 572-LED illumination or musical subscriber.

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :oximeter,
  duration_ms: nil
)
```

When a dim white point appears on the status LEDs, rest a fingertip lightly on the MAX30102. Keep it still after `event=finger_detected`. Read estimates from `event=measurement_updated` or `event=measurement_completed`; removing the finger emits `event=finger_removed` and resets the measurement.

> This feature is for learning and presentation effects only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

`Daisenkofun::Oximeter::Runner` owns the measurement lifecycle. Normal and exceptional exits stop the sensor and clear the status LEDs.

## Combined mode

Use `:combined` for the complete interactive presentation: Oximeter measurement, eight status LEDs, 572 beat-synchronized LEDs, and the musical subscriber share one event loop.

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :combined,
  duration_ms: nil,
  ws2812_pin: 14,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  spi_sck_pin: 2,
  spi_copi_pin: 3,
  buzzer_pin: 18, # nil disables audio
  musical_style: :heartbeat_signature # :pulse_translation or :kofun_canon
)
```

Detected beats trigger the 572-LED biometric illumination and, unless `buzzer_pin` is `nil`, the PWM buzzer on GP18. Silent output and `:pulse_translation` use `Illumination::Biometrics::BeatPulse`; `:kofun_canon` and `:heartbeat_signature` use `Illumination::Biometrics::MoatCanon` with the same planner instance as the audio output. A successful run ends with `DAISENKOFUN mode=combined event=done status=ok`.

The `:kofun_canon` style splits one beat at 0%, about 33%, and about 67% into sequential inner-, middle-, and outer-moat voices. The voices use pentatonic offsets of 0, 2, and 4 steps. An interval at least 40 ms shorter than the previous beat rotates forward; one at least 40 ms longer rotates backward. Relative SpO₂ selects the base route only at four-beat phrase boundaries. Each moat adds +0.4, 0, or -0.4 percentage points to the pulse-width-derived duty. Because the physical moats contain no LEDs, the outlines bordering each moat light with its voice.

`:heartbeat_signature` keeps the kofun canon for seven beats, then turns the latest eight beats into an eight-note “heartbeat signature” on the eighth beat. Beat intervals and their changes, SpO₂ direction relative to the first beat, and optical pulse width determine pentatonic pitch, note length, and 2–6% PWM duty. The eight notes fit inside the eighth beat interval while the boundary LEDs cycle through the inner, middle, and outer moats. Canon resumes on the next beat and collection starts again. Identical eight-beat input produces the same signature; finger removal discards a partial collection.

Set `musical_style = :pulse_translation` to use the idea 1/2 main-note and half-beat response. Its main note quantizes `256000 / interval_ms` to a C major pentatonic scale. Each detected beat starts the main note; a response follows half an interval later. The median of the first eight SpO₂ updates becomes the personal baseline. The smoothed estimate selects a response one scale step below, at, or above the main note. Missing, invalid, or older-than-five-second readings select the same note. A measurement published after a beat affects the next beat.

The MAX30102 IR waveform is divided into beats. The contiguous region below half the trough depth becomes the pulse width, which is normalized by the beat interval and mapped to 2–6% PWM duty. Duty falls back to 3% until a complete wave is available or when its amplitude or sample count is insufficient. A new beat cancels pending audio; finger removal mutes audio and resets the baseline, partial signature, and waveform state. See the [development workflow](development.md#verify-the-heartbeat-melody) for the application check and timing logs.

The event loop reads Oximeter samples first, then ticks subscribers once. It processes at most `MAX_SAMPLES_PER_TICK` samples per tick; beat illumination renders at most one frame every `50 ms`.

| Start order | Component | Hardware ownership | Stop order |
| --- | --- | --- | --- |
| 1 | `Musical::Subscriber` | Injected audio output | 3 |
| 2 | `Illumination::BiometricPlayer` | 572 WS2812B LEDs on GP14 | 2 (clear and close) |
| 3 | `Oximeter::Runner` | MAX30102 and eight status LEDs | 1 (stop publishing, shut down, clear) |

The MAX30102 publisher stops first, then subscribers stop in reverse order; exceptions use the same sequence. When a shared tick exceeds `25 ms` and sets a new maximum, the application logs `event=loop_warning`. When pending MAX30102 samples exceed the per-tick limit and set a new maximum, it logs `event=fifo_backlog`.

The illumination, Oximeter, and combined paths have been verified on physical Pico 2 hardware with the refactored mrbgem namespaces. This confirms startup, sensor events, LED rendering, musical cues, and normal cleanup for the tested configuration; repeat the device check whenever wiring, thresholds, timing, or firmware changes.

## Hardware and setlist settings

Set the WS2812 data pin, MAX30102 I2C SDA/SCL pins, status-LED SPI SCK/COPI pins, and buzzer pin in `Application::Config` in [`main.rb`](../main.rb). Change the 572-LED brightness in the illumination [`config.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/config.rb), and the eight status-LED brightness in the Oximeter [`config.rb`](../mrbgems/daisenkofun-oximeter/mrblib/daisenkofun-oximeter/config.rb). Change setlist patterns, `wait_ms`, and `loops` in [`setlist.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/setlist.rb). Rebuild and reflash after changing an mrbgem; pin-only changes in `main.rb` require only rerunning the application.

## Implementation reference

| Path | Responsibility |
| --- | --- |
| `main.rb` | Declare the configuration and start the application. |
| `mrbgems/daisenkofun-application/` | Validate settings, compose dependencies, run the selected mode, report verification, and clean up. |
| `mrbgems/daisenkofun-runtime/` | `Daisenkofun::Runtime` clock, console logger, and cooperative event loop. |
| `mrbgems/daisenkofun-illumination/` | WS2812 initialization, setlists, presentation patterns, layout, and biometric patterns. |
| `mrbgems/daisenkofun-oximeter/` | `Daisenkofun::Oximeter` device, measurement, events, status display, and runner. |
| `mrbgems/daisenkofun-musical/` | `Daisenkofun::Musical` subscriber, translators, planners, and outputs. |
