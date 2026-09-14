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

## Illumination mode

`:illumination` displays the selected setlist or individual pattern on all 380 LEDs while playing “Twinkle, Twinkle, Little Star” on the PWM buzzer. It does not use the MPU6050 or touch switch.

`setlist_name` and `pattern_key` are mutually exclusive. Omitting both selects `:highlights`. Set `repeat: true` to repeat both light and music, or `buzzer_volume: 0` for light only. See the [illumination catalog](illuminations.md) for available effects.

## Musical mode

`:musical` is a dedicated tambourine mode without touch selection. Hold the model Y-up with group 5 at the top and wait for the orientation to stabilize before playing.

- Shake: move smoothly back and forth along Z, perpendicular to the model face. A multicolor trail travels from group 5 with a “shan-shan” shimmer.
- Strike: apply a short, sharp impact along the same Z axis. A stronger “shan-shan” attack accompanies a fireworks-style burst from the star center through the ravelin to the outer ring.

Leaving Y-up stops performance. This mode does not accept `setlist_name`, `pattern_key`, or `repeat: true`.

## Combined mode

`:combined` uses orientation and the touch switch to select illumination or tambourine:

1. Hold the model Y-up and touch to select a candidate.
2. Read the ravelin: red means illumination and blue means tambourine.
3. Keep the selection visible, move to Z-up, and touch again to confirm.

A Z-up touch before selection and touches outside Y-up or Z-up are ignored.

| Confirmed mode | Behavior |
| --- | --- |
| Illumination | Plays the selected setlist and tune once, then restores the current orientation display |
| Tambourine | Return to Y-up to play shake and strike techniques with synchronized sound and light |

Orientation and touch changes are logged while waiting, and `event=alive` appears approximately every five seconds.
