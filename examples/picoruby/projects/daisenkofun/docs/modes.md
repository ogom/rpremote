# Operating modes and settings

[日本語](modes.ja.md)

Choose the behavior with `Daisenkofun::Application::Config` in [`main.rb`](../main.rb).

| `mode` | Behavior |
| --- | --- |
| `:illumination` | Play a registered setlist or one pattern |
| `:oximeter` | Measure with the MAX30102 and show status on eight LEDs |
| `:combined` | Run measurement, 572 LEDs, status LEDs, and PWM sound together |

## Configuration example

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :combined,
  setlist_name: nil,
  pattern_key: nil,
  repeat: false,
  duration_ms: 60_000,
  ws2812_pin: 14,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  spi_sck_pin: 2,
  spi_copi_pin: 3,
  buzzer_pin: 18,
  buzzer_volume: 3,
  musical_style: :heartbeat_signature
)
```

| Setting | Purpose |
| --- | --- |
| `setlist_name` | Select `:tests`, `:highlights`, `:story`, or `:showcase` |
| `pattern_key` | Select one registered pattern |
| `repeat` | Repeat illumination until interrupted |
| `duration_ms` | Runtime for Oximeter or combined mode |
| Pin settings | Select GPIOs that match the model wiring |
| `buzzer_pin` | Use `nil` to disable sound |
| `buzzer_volume` | 0–100; use `0` to disable sound |
| `musical_style` | Select `:pulse_translation`, `:kofun_canon`, or `:heartbeat_signature` |

Do not set `setlist_name` and `pattern_key` together. Do not set `duration_ms` in illumination mode; use a positive duration in Oximeter and combined modes.

## Illumination mode

`:illumination` plays the selected effect on 572 LEDs without using the MAX30102 or the eight status LEDs. Use this configuration for a short check:

```ruby
mode: :illumination,
setlist_name: :tests,
pattern_key: nil,
repeat: false,
duration_ms: nil
```

To run one effect, set `setlist_name: nil` and provide `pattern_key`. With `repeat: false`, playback runs once and clears the LEDs; with `repeat: true`, it continues until interrupted. See the [illumination catalog](illuminations.md) for every key, visible effect, and setlist order.

## Oximeter mode

```ruby
mode: :oximeter,
duration_ms: 60_000
```

When the status LEDs show the waiting state, lightly place a fingertip on the MAX30102 and keep it still. Observe `event=measurement_updated` or `event=measurement_completed`. Removing the finger resets the measurement.

> Heart-rate and SpO₂ estimates are presentation data and must not be used for medical decisions.

## Combined mode

```ruby
mode: :combined,
duration_ms: 60_000,
buzzer_volume: 3,
musical_style: :heartbeat_signature
```

Each detected beat drives sound and the moat-outline LEDs according to `musical_style`.

- `:pulse_translation`: a main note and response for each heartbeat
- `:kofun_canon`: a three-note canon traveling across the inner, middle, and outer moats
- `:heartbeat_signature`: seven canon beats followed by an eight-note phrase derived from the latest eight beats

See [biometric pulse and music](biometric_pwm_music.md) for interpretation and tuning.
