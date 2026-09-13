# LED layout

[日本語](led_layout.ja.md)

- Motif: Goryokaku
- Total LEDs: 380

## Address ranges by structure

- Five-pointed star: 0–169
- Ravelin: 170–189
- Outer perimeter: 190–379

### Star edges

- 1-1: 0–16
- 1-2: 17–33
- 2-1: 34–50
- 2-2: 51–67
- 3-1: 68–84
- 3-2: 85–101
- 4-1: 102–118
- 4-2: 119–134
- 5-1: 135–151
- 5-2: 152–169

### Edge details

#### Illumination direction

- Illuminate 1-1, 2-1, 3-1, 4-1, and 5-1 from the lower address to the higher address.
- Illuminate 1-2, 2-2, 3-2, 4-2, and 5-2 from the higher address to the lower address.

#### Edge groups

- The left group contains 5-2, 1-1, 1-2, 2-1, and 2-2.
- The right group contains 3-1, 3-2, 4-1, 4-2, and 5-1.

### Tambourine group order

Performance uses Y-up with group 5 at the top. `MUSICAL_GROUP_ORDER = [4, 0, 1, 2, 3]` scans group 5, 1, 2, 3, then 4 for a positive-Z shake; a negative-Z shake reverses the order while retaining group 5 as the starting point. Each shake adds a dim multicolor trail plus ravelin and outer sparks. A strike reuses `star_rays` from `fireworks` to send a six-frame colored burst from the center across all ten star segments. The ravelin alternates white and color, while sparse outer sparks expand into a full outer-ring flash. `Config::BRIGHTNESS` remains the global intensity ceiling.
