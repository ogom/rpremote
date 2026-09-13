# PicoRuby illuminations

[日本語](illuminations.ja.md)

## Catalog

| Key | Effect |
| --- | --- |
| `warm_white` | Warm-white fade on the star |
| `sakura_breathe` | Breathing cherry-blossom star |
| `star_twinkle` | White sparkles on a warm-white star |
| `ravelin_pulse` | Cyan ravelin pulse |
| `outer_comet` | Golden comet around the outer perimeter |
| `rainbow` | Rotating colors on the ten star edges |
| `parallel_left` | Parallel scan over the left five-edge group |
| `parallel_right` | Parallel scan over the right five-edge group |
| `full_zones` | Outer, ravelin, and star sequence |
| `fireworks` | Star-center burst followed by an outer flash |
| `kouhaku` | Alternating red and white |
| `twinkle` | Golden sparkles |
| `shooting_star` | Golden shooting star over all LEDs |
| `breathing` | Breathing gold over all LEDs |
| `constellation` | Golden stars on a red-and-white field |
| `sakura_fubuki` | Scattered cherry-blossom petals |
| `sakura_stream` | Cherry-blossom stream over all LEDs |
| `sakura_gradient` | Moving cherry-blossom gradient |
| `sakura_breathing` | Breathing cherry-blossom colors over all LEDs |
| `hanami` | Cherry-blossom sparkles on red and white |
| `mankai` | Full bloom in several cherry-blossom colors |

## Execution settings

Setlist entries use `[key, wait_ms, loops]`. `:tests` contains one pattern at 1 ms. `:highlights`, `:story`, and `:showcase` use 35 ms and contain 7, 15, and 21 patterns respectively. Highlights briefly covers all three physical zones. Story moves from the illuminated fort through stars, red and white, cherry blossoms, full bloom, and fireworks. Showcase contains every registered effect. See [`setlist.rb`](../mrbgems/goryokaku-illumination/mrblib/goryokaku-illumination/setlist.rb) for the authoritative order and loop counts.

Starting a setlist or individual pattern in `:illumination` also starts “Twinkle, Twinkle, Little Star” on the PWM buzzer. With `repeat: false`, the tune plays once to completion; with `repeat: true`, it repeats with the LEDs. Set `buzzer_volume: 0` to disable it.
