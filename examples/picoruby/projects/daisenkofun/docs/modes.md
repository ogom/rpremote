# Operating modes and settings

[日本語](modes.ja.md)

Set `mode` in [`main.rb`](../main.rb) to choose one application behavior. The modes are mutually exclusive.

| `mode` | Use it when you want to… | Additional settings |
| --- | --- | --- |
| `:illumination` | Play a setlist or one illumination pattern. | `setlist_name` or `pattern_key` |
| `:oximeter` | Measure with the MAX30102 and show its status on eight LEDs. | `duration_ms` |
| `:combined` | Run measurement, status LEDs, beat-synchronized illumination, and musical behavior together. | `duration_ms` |

`setlist_name` and `pattern_key` cannot be used together. `duration_ms` must be a positive integer and defaults to `Oximeter::Config::RUN_DURATION_MS` (60 seconds) in Oximeter and combined modes.

## Illumination mode

Use `:illumination` to play a setlist or exactly one registered pattern. It does not initialize the MAX30102 or the eight Oximeter status LEDs.

```ruby
mode = :illumination
setlist_name = :tests # or :highlights, :story, :showcase
pattern_key = nil
duration_ms = nil
```

To play one pattern, set `setlist_name = nil` and provide a registered `pattern_key`. `:tests` is the short verification setlist and plays `structure_guide`. See the [illumination catalog](illuminations.md) for pattern descriptions and [`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb) for setlist contents.

## Oximeter mode

Use `:oximeter` to measure heart rate and SpO2 with the MAX30102. It controls the MAX30102 and eight status LEDs, but does not start the 572-LED illumination or musical subscriber.

```ruby
mode = :oximeter
setlist_name = nil
pattern_key = nil
duration_ms = nil
```

When a dim white point appears on the status LEDs, rest a fingertip lightly on the MAX30102. Keep it still after `event=finger_detected`. Read estimates from `event=measurement_updated` or `event=measurement_completed`; removing the finger emits `event=finger_removed` and resets the measurement.

> This feature is for learning and presentation effects only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

`Daisenkofun::Oximeter::Runner` owns the measurement lifecycle. Normal and exceptional exits stop the sensor and clear the status LEDs.

## Combined mode

Use `:combined` for the complete interactive presentation: Oximeter measurement, eight status LEDs, 572 beat-synchronized LEDs, and the musical subscriber share one event loop.

```ruby
mode = :combined
setlist_name = nil
pattern_key = nil
duration_ms = nil
```

Detected beats trigger the 572-LED beat illumination. The musical subscriber uses `NullOutput` by default, so it does not claim an audio pin until an output is supplied. A successful run ends with `DAISENKOFUN mode=combined event=done status=ok`.

The event loop reads Oximeter samples first, then ticks subscribers once. It processes at most `MAX_SAMPLES_PER_TICK` samples per tick; beat illumination renders at most one frame every `50 ms`.

| Start order | Component | Hardware ownership | Stop order |
| --- | --- | --- | --- |
| 1 | `BeatIllumination` | 572 WS2812B LEDs on GP14 | 3 (clear and close) |
| 2 | `Musical::BeatSubscriber` | Injected audio output | 2 |
| 3 | `Oximeter::Runner` | MAX30102 and eight status LEDs | 1 (stop publishing, shut down, clear) |

The MAX30102 publisher stops first, then subscribers stop in reverse order; exceptions use the same sequence. When a shared tick exceeds `25 ms` and sets a new maximum, the application logs `event=loop_warning`. When pending MAX30102 samples exceed the per-tick limit and set a new maximum, it logs `event=fifo_backlog`.

## Hardware and setlist settings

Change GPIO assignments and brightness in [`config.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb). Change setlist patterns, `wait_ms`, and `loops` in [`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb). The `:tests`, `:highlights`, `:story`, and `:showcase` frame intervals use `TESTS_FRAME_MS`, `HIGHLIGHTS_FRAME_MS`, `STORY_FRAME_MS`, and `SHOWCASE_FRAME_MS`, respectively. Rebuild and reflash after changing an mrbgem.

## Implementation reference

| Path | Responsibility |
| --- | --- |
| `main.rb` | Validate settings, compose dependencies, run the selected mode, and clean up. |
| `mrbgems/daisenkofun-runtime/` | Shared event loop and console logger. |
| `mrbgems/daisenkofun-illuminations/` | WS2812 initialization, setlists, patterns, layout, and beat illumination. |
| `mrbgems/daisenkofun-oximeter/` | MAX30102 measurement, status display, and execution lifecycle. |
| `mrbgems/daisenkofun-musical/` | Beat-event subscriber and tick-driven audio-output interface. |
