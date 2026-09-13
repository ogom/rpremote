# Operating modes and settings

[日本語](modes.ja.md)

## Illumination mode

`:illumination` uses the 380 LEDs and PWM buzzer. It does not initialize the MPU6050 or touch switch.

```ruby
config = Goryokaku::Application::Config.new(
  mode: :illumination,
  setlist_name: :highlights,
  pattern_key: nil,
  repeat: false,
  led_pin: 14,
  led_count: 380,
  buzzer_pin: 18,
  buzzer_volume: 1
)
```

`setlist_name` and `pattern_key` are mutually exclusive. When both are `nil`, the configuration selects `:highlights`. Set `repeat: true` to repeat the selected setlist or pattern until stopped.

The PWM buzzer starts “Twinkle, Twinkle, Little Star” with the LED effects. Its 14-note sequence is `C4 C4 G4 G4 A4 A4 G4 / F4 F4 E4 E4 D4 D4 C4`, using 400 ms notes, 800 ms phrase endings, and 50 ms gaps. With `repeat: false`, the complete tune plays once even if the LED effect finishes first. With `repeat: true`, both the LEDs and tune repeat. Set `buzzer_volume: 0` to disable the tune. Cleanup and exception handling always return PWM duty to zero.

### Setlists

| Name | Contents |
| --- | --- |
| `:tests` | A short warm-white check |
| `:highlights` | Seven short representative effects covering the star, ravelin, outer perimeter, rainbow, full view, and fireworks |
| `:story` | Fifteen effects moving from the illuminated fort through stars, red and white, cherry blossoms, full bloom, and fireworks |
| `:showcase` | All 21 registered effects |

### Individual patterns

Set `setlist_name: nil` and choose one of these `pattern_key` values:

| Key | Effect |
| --- | --- |
| `:warm_white` | Fade in the complete model in warm white |
| `:sakura_breathe` | Breathe the star in cherry-blossom pink |
| `:star_twinkle` | Twinkle the star |
| `:ravelin_pulse` | Pulse the ravelin |
| `:outer_comet` | Run a comet around the outer perimeter |
| `:rainbow` | Run rainbow trails along the star |
| `:parallel_left` | Illuminate the left edge group in parallel |
| `:parallel_right` | Illuminate the right edge group in parallel |
| `:full_zones` | Illuminate, breathe, and clear all zones in sequence |
| `:fireworks` | Run three firework effects |
| `:kouhaku` | Alternate red and white across the model |
| `:twinkle` | Scatter golden twinkles across the model |
| `:shooting_star` | Run a golden shooting star across the model |
| `:breathing` | Breathe the complete model in gold |
| `:constellation` | Show golden stars over a red-and-white background |
| `:sakura_fubuki` | Scatter cherry-blossom petals across the model |
| `:sakura_stream` | Run a cherry-blossom trail across the model |
| `:sakura_gradient` | Move a cherry-blossom gradient across the model |
| `:sakura_breathing` | Breathe the complete model in cherry-blossom pink |
| `:hanami` | Show cherry blossoms over a red-and-white background |
| `:mankai` | Fill the model with a cherry-blossom palette |

Example:

```ruby
mode: :illumination,
setlist_name: nil,
pattern_key: :fireworks,
repeat: false
```

Each effect logs its start, and all LEDs are cleared when playback finishes:

```text
GORYOKAKU mode=illumination event=pattern index=1/7 key=warm_white wait_ms=35 loops=1
GORYOKAKU mode=illumination event=led_off
```

## Musical mode

`:musical` is a dedicated tambourine mode that synchronizes the MPU6050, PWM buzzer, and all 380 LEDs without using touch selection.

```ruby
mode: :musical,
setlist_name: nil,
pattern_key: nil,
repeat: false
```

Hold the model Y-up with star group 5 at the top for 100 ms to enable performance. The shake technique detects two smooth Z-axis reversals at or above 0.2 g. A gentle shake plays a decaying “shan-shan” shimmer that switches between metallic frequencies from 4.2 to 7.4 kHz every 20 ms, while scanning the five star groups from group 5 with a multicolor afterglow. A sharp impact on the same Z axis is classified as a strike when jerk reaches 0.45 g. It plays a sharper “shan-shan” sequence of six decaying tones from 4.1 to 7.8 kHz at 20 ms intervals. Adapted from `fireworks`, the synchronized light expands in ten colored rays from the star center, flashes the ravelin, then lights the outer ring. It does not rearm until the impact falls below 0.15 g, limiting repeated notes from small resting noise.

Sound and light share the same gesture event, start time, intensity, and duration. Leaving Y-up, stopping, or raising an exception silences PWM and clears every LED. This mode does not accept `setlist_name`, `pattern_key`, or `repeat: true`.

## Combined mode

The sensor-driven behavior from the former `my-penta` component remains available as `:combined`.

```ruby
mode: :combined,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

No candidate is selected at startup. The first Y-up touch selects illumination, and subsequent Y-up touches alternate it with tambourine. Select and confirm a mode as follows:

1. Hold the IMU Y-up and press the touch switch to alternate the candidate.
2. Read the ravelin color: red means illumination and blue means tambourine.
3. Hold the IMU Z-up and press the touch switch to confirm the displayed candidate.

The indicator remains visible while moving from Y-up to Z-up. A Z-up touch before selection, and touches in orientations other than Y-up and Z-up, are ignored.

| State | Behavior |
| --- | --- |
| Illumination | Show warm white at Z-up or a pink star at Y-up/X-up; play “Twinkle, Twinkle, Little Star” and `setlist_name` once when confirmed; motion is silent |
| Tambourine | Return to Y-up to play; shakes scan a multicolor afterglow from group 5 and strikes synchronize the “shan-shan” sound with a star-to-outer-ring fireworks burst |

Each illumination confirmation starts “Twinkle, Twinkle, Little Star” and the setlist from their first entries, then restores the display for the current orientation after both finish. Input processing waits until playback finishes. Confirming tambourine clears the selection indicator and all other LEDs. Omitting `setlist_name` selects `:highlights`. Combined mode does not accept `pattern_key` or `repeat: true`.
