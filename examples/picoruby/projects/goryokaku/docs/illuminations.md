# PicoRuby illuminations

[日本語](illuminations.ja.md)

This catalog helps operators choose an effect by showing the configuration key, what appears on the model, and the contents of each setlist.

## Catalog

| Key | Title | What you will see |
| --- | --- | --- |
| `warm_white` | Lights of Goryokaku | The star-shaped fort fades in with warm-white light. |
| `sakura_breathe` | Cherry-blossom breath | The star gently pulses in cherry-blossom pink. |
| `star_twinkle` | Star-shaped sparkle | Irregular white points sparkle over a warm-white star. |
| `ravelin_pulse` | Ravelin pulse | The southwest ravelin repeatedly pulses in cyan. |
| `outer_comet` | Outer comet | A light with a golden tail circles the outer perimeter. |
| `rainbow` | Five-colored bastions | Rainbow colors rotate around the ten edges of the star. |
| `parallel_left` | Left parallel scan | Different colors advance together over the left five-edge group. |
| `parallel_right` | Right parallel scan | Different colors advance together over the right five-edge group. |
| `full_zones` | Full view of Goryokaku | The outer perimeter, ravelin, and star light in order, then go dark in reverse order. |
| `fireworks` | Fireworks over Goryokaku | Light bursts from the star center and ends in a large outer flash. |
| `kouhaku` | Red and white | Red and white areas swap while the entire model flashes. |
| `twinkle` | Golden sparkle | Irregular golden points sparkle over a dark background. |
| `shooting_star` | Shooting star | A golden-tailed light travels across the full LED chain. |
| `breathing` | Golden breath | Gold light across the model rises and falls smoothly. |
| `constellation` | Constellation | Golden stars sparkle over a red-and-white field. |
| `sakura_fubuki` | Cherry-blossom flurry | Pink petals drift irregularly across the model. |
| `sakura_stream` | Cherry-blossom stream | A pink-tailed light travels across the full LED chain. |
| `sakura_gradient` | Cherry-blossom gradient | Bands of several pink shades flow across the model. |
| `sakura_breathing` | Full-bloom breath | Cherry-blossom colors across the model pulse smoothly. |
| `hanami` | Flower viewing | Cherry-blossom lights sparkle over a red-and-white field. |
| `mankai` | Full bloom | Several cherry-blossom shades fill the entire model. |

## Execution settings

### Choose an effect

Select a setlist or one effect through `Goryokaku::Application::Config` in [`main.rb`](../main.rb). This configuration plays `:highlights` once:

```ruby
mode: :illumination,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

To view one effect, set `setlist_name: nil` and assign a key from the catalog to `pattern_key`:

```ruby
mode: :illumination,
setlist_name: nil,
pattern_key: :fireworks,
repeat: false
```

Do not set `setlist_name` and `pattern_key` together. If both are `nil`, `:highlights` is selected. With `repeat: true`, the lights and tune repeat until stopped.

### Setlist contents

| Setlist | Best for | Keys in playback order |
| --- | --- | --- |
| `:tests` | A short lighting check after wiring | `warm_white` |
| `:highlights` | A short tour of the star, ravelin, outer perimeter, and signature effects | `warm_white` → `sakura_breathe` → `ravelin_pulse` → `outer_comet` → `rainbow` → `full_zones` → `fireworks` |
| `:story` | A presentation that moves from fort lights through stars, red and white, blossoms, full bloom, and fireworks | `warm_white` → `star_twinkle` → `ravelin_pulse` → `outer_comet` → `rainbow` → `kouhaku` → `shooting_star` → `constellation` → `sakura_fubuki` → `sakura_stream` → `sakura_gradient` → `sakura_breathing` → `hanami` → `mankai` → `fireworks` |
| `:showcase` | Viewing all 21 registered effects | `warm_white` → `sakura_breathe` → `star_twinkle` → `ravelin_pulse` → `outer_comet` → `rainbow` → `parallel_left` → `parallel_right` → `full_zones` → `kouhaku` → `twinkle` → `shooting_star` → `breathing` → `constellation` → `sakura_fubuki` → `sakura_stream` → `sakura_gradient` → `sakura_breathing` → `hanami` → `mankai` → `fireworks` |

`fireworks` repeats three times in each setlist, and `outer_comet` makes two laps in `:showcase`.

### Playback timing and shutdown

Setlist entries use `[key, wait_ms, loops]`. `:tests` contains one pattern at 1 ms. `:highlights`, `:story`, and `:showcase` use 35 ms and contain 7, 15, and 21 patterns respectively. See [`setlist.rb`](../mrbgems/goryokaku-illumination/mrblib/goryokaku-illumination/setlist.rb) for the playback settings.

Starting a setlist or individual pattern in `:illumination` also starts “Twinkle, Twinkle, Little Star” on the PWM buzzer. With `repeat: false`, the tune plays once to completion; with `repeat: true`, it repeats with the LEDs. Set `buzzer_volume: 0` to disable it.

After one playback finishes, or when execution is interrupted, the buzzer stops and every LED is cleared.
