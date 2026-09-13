# Structure

[日本語](structure.ja.md)

Goryokaku in Hakodate is a Western-style earthwork fort whose five bastions form a star-shaped pentagon. Its main rampart is surrounded by a lower rampart and water moat. A single ravelin protects the southwest entrance. The illumination model treats these visible outlines as independently controlled zones.

## Model mapping

The project uses 380 LEDs and a nominal model scale of approximately 1:1,938, based on 535 m represented by 276 mm. The scale is a design guide, while the LED zones are an abstraction for recognizable structure and effects.

| Zone | Addresses | Count | Structure |
| --- | ---: | ---: | --- |
| `STAR` | 0–169 | 170 | Main star and five bastions |
| `RAVELIN` | 170–189 | 20 | Southwest ravelin |
| `OUTER` | 190–379 | 190 | Outer line beyond the moat |

The star is divided into ten directed segments, two edges for each bastion. Eight segments have 17 LEDs, with the remaining segments having 16 and 18. This supports edge scans, parallel left/right groups, and center-out firework rays while preserving one continuous physical address space.

See [LED layout](led_layout.md) for exact ranges and traversal direction. Historical dimensions, terminology, and source links are retained in the [Japanese structure document](structure.ja.md).

The documented display layout is Z-up with the model face horizontal. Tambourine performance uses Y-up with star group 5 (`line5_a` and `line5_b`) at the top. In that orientation Z is perpendicular to the model face and serves as both the shake-travel and strike axis; smooth reversals and sharp jerk distinguish the techniques. The LED addresses and structural zones do not change between orientations.
