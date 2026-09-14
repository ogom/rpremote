# LED layout

[日本語](led_layout.ja.md)

This guide maps the structure of the Goryokaku model to its 380 WS2812 LEDs. The authoritative address map is
[`led_layout.rb`](../mrbgems/goryokaku-illumination/mrblib/goryokaku-illumination/led_layout.rb).

## Zones

| Zone | Addresses | Count | Model feature |
| ---- | --------: | ----: | ------------- |
| `STAR` | `0..169` | 170 | Star body and five bastions |
| `RAVELIN` | `170..189` | 20 | Southwest ravelin |
| `OUTER` | `190..379` | 190 | Outline beyond the moat |

```text
DATA IN → STAR 0..169 → RAVELIN 170..189 → OUTER 190..379
```

The interior and the moat have no dedicated LEDs; their spaces are implied between the illuminated outlines. The ravelin is a local outwork at the southwest entrance, not a complete concentric middle ring.

## Star body

Each of the five bastions is split into an A edge and a B edge, producing ten wired segments.

| Group | A edge | B edge | Count (A + B) |
| ----: | -----: | -----: | ------------: |
| 1 | `0..16` | `17..33` | 17 + 17 |
| 2 | `34..50` | `51..67` | 17 + 17 |
| 3 | `68..84` | `85..101` | 17 + 17 |
| 4 | `102..118` | `119..134` | 17 + 16 |
| 5 | `135..151` | `152..169` | 17 + 18 |

Most effects traverse each segment from low to high addresses. The radial pass in `fireworks` traverses A edges low-to-high and B edges high-to-low so both rays appear to travel outward from the same origin. This is an animation order, not a request to reverse the physical wiring.

## Tambourine orientation

The display orientation is Z-up. Performance uses Y-up with group 5 at the top. A positive-Z shake travels group 5→1→2→3→4; a negative-Z shake travels group 5→4→3→2→1.

```text
Positive Z: group 5 → group 1 → group 2 → group 3 → group 4
Negative Z: group 5 → group 4 → group 3 → group 2 → group 1
```

Shake gestures leave a moving trail. Strikes use the same center-out rays as `fireworks`. LED addresses and zones do not change when the model orientation changes.

## Ravelin and outer ring

The ravelin is the continuous range `170..189`. It is separate from the star's ten segments and displays selection state or independent pulses.

The outer zone is a closed ring over `190..379`. Its physical seam joins LED `379` back to LED `190`; confirm that this transition appears continuous during chase effects.

## Changing the layout

When wiring order or LED counts change, update and check:

- zones, segments, and traversal order in `led_layout.rb`;
- `led_count` in `main.rb`;
- center-out direction of the firework rays;
- visual continuity between outer LEDs `379` and `190`;
- group 5 at the top in Y-up and direction reversal for Z-axis shakes; and
- this guide and the [structure guide](structure.md).

See [Illuminations](illuminations.md) for effect names and execution settings.
