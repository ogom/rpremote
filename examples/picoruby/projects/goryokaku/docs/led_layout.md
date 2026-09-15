# LED layout

[日本語](led_layout.ja.md)

This guide maps the Goryokaku features described in the [structure guide](structure.md) to the model's 380 WS2812 LEDs. Use it while assembling the model, wiring the strip, choosing effects, and locating lighting faults. The authoritative address map is [`led_layout.rb`](../mrbgems/goryokaku-illumination/mrblib/goryokaku-illumination/led_layout.rb).

## Zones

| Zone | Addresses | Count | Model feature |
| ---- | --------: | ----: | ------------- |
| `STAR` | `0..169` | 170 | Star body and five bastions |
| `RAVELIN` | `170..189` | 20 | Southwest ravelin |
| `OUTER` | `190..379` | 190 | Outline beyond the moat |

```text
Center
  Interior               no LEDs
  STAR                    0..169   170 LEDs
  Low rampart and moat   no LEDs
  RAVELIN               170..189    20 LEDs (southwest only)
  OUTER                  190..379   190 LEDs
Outside
```

The interior and the moat have no dedicated LEDs; their spaces are implied between the illuminated outlines. The ravelin is a local outwork at the southwest entrance, not a complete concentric middle ring.

The physical strip connects the three zones in this order:

```text
DATA IN → STAR 0..169 → RAVELIN 170..189 → OUTER 190..379
```

## Star body

Each of the five bastions is split into an A edge and a B edge, producing ten wired segments. Normal traversal follows the physical strip from lower to higher addresses.

| Group | Edge | Addresses | Count | Normal traversal |
| ----: | ---- | --------: | ----: | ---------------- |
| 1 | 1-A | `0..16` | 17 | `0` → `16` |
| 1 | 1-B | `17..33` | 17 | `17` → `33` |
| 2 | 2-A | `34..50` | 17 | `34` → `50` |
| 2 | 2-B | `51..67` | 17 | `51` → `67` |
| 3 | 3-A | `68..84` | 17 | `68` → `84` |
| 3 | 3-B | `85..101` | 17 | `85` → `101` |
| 4 | 4-A | `102..118` | 17 | `102` → `118` |
| 4 | 4-B | `119..134` | 16 | `119` → `134` |
| 5 | 5-A | `135..151` | 17 | `135` → `151` |
| 5 | 5-B | `152..169` | 18 | `152` → `169` |

The ten edges total 170 LEDs. Only edge 4-B has 16 LEDs and edge 5-B has 18; all other edges have 17. Check these boundaries during installation rather than assuming that every edge has the same length.

Most effects traverse each segment from low to high addresses. The radial pass in `fireworks` traverses A edges low-to-high and B edges high-to-low so both rays appear to travel outward from the same origin. This is an animation order, not a request to reverse the physical wiring.

```text
Group 1:   0 → 16       33 → 17
Group 2:  34 → 50       67 → 51
Group 3:  68 → 84      101 → 85
Group 4: 102 → 118     134 → 119
Group 5: 135 → 151     169 → 152
```

## Left and right parallel scans

`parallel_left` and `parallel_right` divide the ten star edges into two five-edge groups and advance light over each group in parallel.

| Effect key | Edges |
| ---------- | ----- |
| `parallel_left` | 3-A, 3-B, 4-A, 4-B, 5-A |
| `parallel_right` | 5-B, 1-A, 1-B, 2-A, 2-B |

What appears left or right depends on how the model is placed and viewed. For wiring checks, verify the listed edges instead of relying on the name alone.

## Tambourine orientation

The display orientation is Z-up. Performance uses Y-up with group 5 at the top. A positive-Z shake travels group 5→1→2→3→4; a negative-Z shake travels group 5→4→3→2→1.

```text
Positive Z: group 5 → group 1 → group 2 → group 3 → group 4
Negative Z: group 5 → group 4 → group 3 → group 2 → group 1
```

During a shake, the current group is bright and the previous group remains dim, making the direction visible. Points on the ravelin and outer ring also change color as the group advances.

A strike uses the same center-out rays as `fireworks`. Multicolored light spreads over all ten edges, the ravelin flashes, sparse outer points appear, and the sequence ends with a large flash around the outer ring. LED addresses and zones do not change when the model orientation changes.

## Ravelin

The ravelin is the continuous range `170..189`. It is separate from the star's ten segments and displays selection state or independent pulses.

| Check | Appearance |
| ----- | ---------- |
| `ravelin_pulse` | Only the 20 ravelin LEDs pulse in cyan |
| Combined-mode selection | Red selects illumination; blue selects tambourine |
| `full_zones` | The ravelin lights after the outer ring and before the star |

## Outer ring

The outer zone is a closed ring of 190 LEDs over `190..379`. Normal travel begins at `190`, reaches `379`, and wraps to `190`. Place LEDs `379` and `190` next to each other on the physical model.

`outer_comet` sends a golden tail around this ring. If the light jumps or reverses at the seam, check the positions and wiring direction of LEDs `379` and `190`.

## Check the layout with effects

Individual effects from the [illumination catalog](illuminations.md) let an operator check the zones and wiring direction in stages.

| Effect key | What it checks |
| ---------- | -------------- |
| `warm_white` | All 170 star LEDs light without a gap |
| `ravelin_pulse` | Only the 20 LEDs at the southwest ravelin light |
| `outer_comet` | The 190 outer LEDs follow the correct order and the `379`→`190` seam is continuous |
| `parallel_left` / `parallel_right` | The two five-edge groups match the table |
| `fireworks` | Every A and B edge expands from the center toward the outside |
| `full_zones` | The outer ring, ravelin, and star behave as three independent zones |

For a first check, run `warm_white`, then check the ravelin, outer ring, parallel groups, and fireworks in that order. See [hardware](hardware.md) for power and safety guidance and the [illumination catalog](illuminations.md) for single-effect configuration.

## Changing the layout

When wiring order or LED counts change, update and check:

- zones, segments, and traversal order in `led_layout.rb`;
- `led_count` in `main.rb`;
- center-out direction of the firework rays;
- visual continuity between outer LEDs `379` and `190`;
- group 5 at the top in Y-up and direction reversal for Z-axis shakes; and
- this guide and the [structure guide](structure.md).

After making a change, replay the individual effects above and verify that the tables match the illuminated positions on the model.
