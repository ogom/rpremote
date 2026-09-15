# Operating modes and settings

[日本語](modes.ja.md)

## Configuration

Choose the behavior through `Goryokaku::Application::Config` in [`main.rb`](../main.rb):

```ruby
config = Goryokaku::Application::Config.new(
  mode: :illumination,
  setlist_name: :highlights,
  pattern_key: nil,
  repeat: false,
  buzzer_volume: 0.02
)
```

| Setting | Purpose |
| --- | --- |
| `mode` | Select `:illumination`, `:musical`, or `:combined` |
| `setlist_name` | Select `:tests`, `:highlights`, `:story`, or `:showcase` |
| `pattern_key` | Select one pattern instead of a setlist |
| `repeat` | Repeat illumination until stopped |
| `buzzer_volume` | Set PWM volume; use `0` for silence |
| `musical_axis_signs` | Use `1` or `-1` per axis to match MPU6050 mounting |
| `shake_threshold` | Adjust shake sensitivity |
| `strike_threshold` | Adjust strike sensitivity |

Default pins and I2C settings are documented in [hardware](hardware.md). After changing detection values, verify both gentle performance and the absence of false notes while stationary on the physical device.

### Orientation and tambourine sensitivity

These are the defaults from `Goryokaku::Application::Config`. Leave them unchanged unless the MPU6050 mounting or a performer's motion requires tuning.

| Setting | Default | Effect of decreasing or increasing it |
| ------- | ------: | -------------------------------------- |
| `musical_axis_signs` | `[1, 1, 1]` | This is not a sensitivity value; set only an axis mounted in the opposite direction to `-1` |
| `vertical_threshold` | `0.7` | Lower recognizes Y-up/Z-up more easily but also accepts more tilted poses |
| `horizontal_threshold` | `0.7` | Lower recognizes X-up more easily but makes orientation boundaries less distinct |
| `orientation_stable_ms` | `100` | Lower enables performance sooner; higher rejects more pose wobble |
| `poll_interval_ms` | `20` | Lower samples more frequently but increases processing work |
| `shake_threshold` | `0.2` | Lower responds to gentler shakes; higher suppresses false notes |
| `shake_window_ms` | `250` | Higher accepts slower reversals as one shake gesture |
| `shake_reversals` | `2` | Lower needs fewer reversals; higher requires a more deliberate shake |
| `shake_retrigger_ms` | `100` | Higher suppresses repeated notes after a shake for longer |
| `strike_threshold` | `0.45` | Lower responds to gentler impacts; higher accepts only sharper impacts |
| `strike_release_threshold` | `0.15` | The impact must settle below this value before another strike is accepted |
| `strike_retrigger_ms` | `120` | Higher makes one impact less likely to be detected more than once |

Keep `strike_release_threshold` below `strike_threshold`. Start with the defaults, hold Y-up for at least 100 ms, and test a gentle shake and a short strike separately. Lower only the threshold for a technique that does not respond. Restore or raise it if notes occur while stationary or while changing orientation.

## Illumination mode

`:illumination` displays the selected setlist or individual pattern on all 380 LEDs while playing “Twinkle, Twinkle, Little Star” on the PWM buzzer. It does not use the MPU6050 or touch switch.

`setlist_name` and `pattern_key` are mutually exclusive. Omitting both selects `:highlights`. Set `repeat: true` to repeat both light and music, or `buzzer_volume: 0` for light only. See the [illumination catalog](illuminations.md) for every key, the visible effect, setlist order, and a single-effect configuration example.

## Musical mode

`:musical` is a dedicated tambourine mode without touch selection. Hold the model Y-up with group 5 at the top and wait for the orientation to stabilize before playing.

```ruby
mode: :musical,
setlist_name: nil,
pattern_key: nil,
repeat: false
```

- Shake: move smoothly back and forth along Z, perpendicular to the model face. A multicolor trail travels from group 5 with a “shan-shan” shimmer.
- Strike: apply a short, sharp impact along the same Z axis. A stronger “shan-shan” attack accompanies a fireworks-style burst from the star center through the ravelin to the outer ring.

Leaving Y-up stops performance. This mode does not accept `setlist_name`, `pattern_key`, or `repeat: true`.

## Combined mode

`:combined` uses orientation and the touch switch to select illumination or tambourine:

```ruby
mode: :combined,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

1. Hold the model Y-up and touch to select a candidate.
2. Read the ravelin: red means illumination and blue means tambourine.
3. Keep the selection visible, move to Z-up, and touch again to confirm.

A Z-up touch before selection and touches outside Y-up or Z-up are ignored.

While waiting for a selection, the LEDs also show the current orientation: the entire model is warm white in Z-up, while the star is cherry-blossom pink in Y-up and X-up. After selecting a candidate, the ravelin keeps its red or blue selection color while the model is moved to Z-up.

| Confirmed mode | Behavior |
| --- | --- |
| Illumination | Plays the selected setlist and tune once, then restores the current orientation display |
| Tambourine | Return to Y-up to play shake and strike techniques with synchronized sound and light |

Each time illumination is confirmed, the selected setlist and tune start from the beginning and play once. The current-orientation display returns after playback. Confirming tambourine clears the selection display; return to Y-up to perform. Orientation and touch changes are logged while waiting, and `event=alive` appears approximately every five seconds.
