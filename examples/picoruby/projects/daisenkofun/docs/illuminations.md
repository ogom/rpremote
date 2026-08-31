# PicoRuby illuminations

[日本語](illuminations.ja.md)

## Catalog

| Key | Title | Description |
| --- | --- | --- |
| `structure_guide` | Daisen Kofun structure guide | Introduces the three mound tiers, two banks, and three moats in order from the center outward. |
| `moonlight` | Moonlight | Sends blue moonlight from the outside toward the center and reflects it from the attached kofun. |
| `starry_kofun` | Starry kofun | Makes irregular white stars appear over an indigo kofun and slowly fade away. |
| `attached_kofun_lights` | Lights of the attached kofun on the middle bank | Spreads gold and light-blue light from Chayama Kofun and Daianjiyama Kofun across the middle bank. |
| `goodnight_pastel` | Goodnight pastel | Colors the five outlines in soft hues and gently pulses the entire model. |
| `dappled_light` | Dappled light | Layers pale-gold points over greens of different depths to represent sunlight filtering through leaves. |
| `green_shimmer` | Green shimmer | Moves waves of green brightness along the LED order. |
| `fireflies` | Fireflies | Sends seven green lights flying at different speeds through a lingering glow. |
| `sea` | Sea | Varies shades of blue by vertical row to draw continuous waves. |
| `water_ripples` | Water ripples | Sends light-blue ripples outward from the center and brightens the attached kofun when they arrive. |
| `triple_moat_mirror` | Reflections in the three moats | Highlights the inner, second, and outer moats in blue to represent reflections on the water. |
| `sunrise` | Sunrise | Represents dawn with light changing from indigo through rose and orange to gold. |
| `sakai_sunset` | Sakai sunset | Changes an amber sky through rose to indigo and depicts the afterglow. |
| `golden_breath` | Golden breath | Slowly pulses all outlines in gold with the same period. |
| `aurora` | Aurora | Waves blue, green, and purple bands vertically to represent light flowing across the sky. |
| `divine_light` | Divine light | Fills the side and circular sections with rainbow colors, then lights the two attached kofun. |
| `cherry_blossom` | Cherry-blossom flurry | Sends rose, pink, and white petals drifting downward. |
| `rose_garden` | Rose garden | Blooms rose-colored light around each outline with staggered phases. |
| `pastel_ribbon` | Pastel ribbon | Sends a trail of soft colors clockwise from the outside toward the center. |
| `princess_sparkle` | Princess sparkle | Adds small golden sparkles over pink, purple, gold, and light-blue backgrounds. |
| `unicorn_dream` | Unicorn dream | Flows pastel color bands across the entire kofun to create a dreamlike scene. |
| `peekaboo` | Peekaboo | Repeats hiding and appearing by increasing and decreasing the vertically visible area. |
| `heartbeat` | Heartbeat | Creates heartbeat-like brightness with a double pink pulse. |
| `jewel_box` | Jewel box | Switches each outline among colors reminiscent of ruby, sapphire, emerald, and other gems. |
| `symmetric_forepart_chase` | Symmetric forepart chase | Pairs the left and right sides of the forepart and advances blue lights symmetrically. |
| `rainbow_comet` | Rainbow comet | Sends a light with a rainbow tail clockwise from the outside toward the center. |
| `two_banks_clockwise` | Two banks clockwise | Colors the inner bank light blue and the middle bank green, then advances two lights clockwise at the same time. |
| `color_bound` | Color bound | Sends multicolored light to the ends of the entire kofun and bounces it back in the opposite direction. |
| `carnival_chase` | Carnival chase | Sends different-colored lights clockwise around the five outlines with staggered timing. |
| `torch_procession` | Torch procession | Advances five gold and orange torches with spaces between them. |
| `fireworks` | Fireworks | Opens small multicolored fireworks at several positions and slowly fades their afterglow. |
| `launch_fireworks` | Launch fireworks | Launches blue-to-purple light, then spreads a large multicolored burst and sparks across the mound and banks. |

## Execution settings

Each setlist entry has the form `[key, wait_ms, loops]`. The wait time and number of repetitions can differ by execution mode, even for the same pattern.

```ruby
[:water_ripples, SHORT_FRAME_MS, 3]
```

[`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb) uses `SHORT_FRAME_MS` for `:short`, `LONG_FRAME_MS` for `:long`, and `ALL_FRAME_MS` for `:all`. The `:only` mode uses the defaults in the `PATTERNS` registry.

| Mode | Pattern count | `wait_ms` setting |
| --- | ---: | --- |
| `:short` | 7 | `SHORT_FRAME_MS` (10 ms) |
| `:long` | 19 | `LONG_FRAME_MS` (5 ms) |
| `:all` | 30 | `ALL_FRAME_MS` (2 ms) |
| `:only` | 1 | Default for the selected pattern in `PATTERNS` |

Only `water_ripples` in `:short` and `:long` uses `loops` set to `3`; all other entries use `1`. In `:only` mode, `loops` follows the `PATTERNS` setting.
