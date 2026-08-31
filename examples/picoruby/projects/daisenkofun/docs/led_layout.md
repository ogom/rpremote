# LED layout

[日本語](led_layout.ja.md)

This document shows how the Daisen Kofun structure described in the [structure reference](structure.md) maps to the model's 572 WS2812B LEDs. [`led_layout.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/led_layout.rb) is the single source of truth for physical addresses. Change only the Ruby file when adding LEDs or adjusting wiring order or ranges; use this document to describe the mapping.

## Mapping the structure to LED outlines

The mound is represented by three outlines—top, middle, and base—corresponding to the [three-tier construction](structure.md#three-tier-construction). Outside them, the model adds the inner bank and middle bank from the [three moats and two banks](structure.md#3-moats-and-banks). These five outlines are in the same order as the rows in `SEGMENT_RANGES`.

| Structural position | Element in the structure reference | `LedLayout` constant | LED address | LED count | Representation on the model |
| ---: | --- | --- | ---: | ---: | --- |
| 1 | Mound tier 3 (top) | `MOUND_TOP` | `0..51` | 52 | Forepart-and-circular outline at the top of the mound |
| 2 | Mound tier 2 (middle) | `MOUND_MIDDLE` | `52..131` | 80 | Middle outline of the mound |
| 3 | Mound tier 1 (base) | `MOUND_BASE` | `132..229` | 98 | Base outline of the mound |
| 4 | Inner moat | No constant | None | 0 | Represented by light on `MOUND_BASE` and `INNER_BANK` |
| 5 | Inner bank | `INNER_BANK` | `230..385` | 156 | Bank outline between the inner and second moats |
| 6 | Second moat | No constant | None | 0 | Represented by light on `INNER_BANK` and `MIDDLE_BANK` |
| 7 | Middle bank | `MIDDLE_BANK` | `386..569` | 184 | Bank outline between the second and outer moats |
| 7a | Chayama Kofun | `CHAYAMA` | `570` | 1 | Attached kofun on the circular-section side of the middle bank |
| 7b | Daianjiyama Kofun | `DAIANJIYAMA` | `571` | 1 | Attached kofun on the circular-section side of the middle bank |
| 8 | Outer moat | No constant | None | 0 | Represented by light on the inner shore at `MIDDLE_BANK` |

`LED_COUNT` is 572: 570 LEDs across the five outlines plus two attached-kofun LEDs. No LEDs are assigned directly to the moats or the outer area in the structure reference. Water effects illuminate adjacent outlines defined by `MOAT_BOUNDARIES` as the shores.

```text
Center
  Mound tier 3  MOUND_TOP       0..51
  Mound tier 2  MOUND_MIDDLE   52..131
  Mound tier 1  MOUND_BASE    132..229
  Inner moat    No LEDs         boundary [MOUND_BASE, INNER_BANK]
  Inner bank    INNER_BANK    230..385
  Second moat   No LEDs         boundary [INNER_BANK, MIDDLE_BANK]
  Middle bank   MIDDLE_BANK   386..569
  Outer moat    No LEDs         boundary [MIDDLE_BANK]
Outside
```

As described in the [structure reference](structure.md#4-round-attached-kofun-on-the-middle-bank), Chayama Kofun and Daianjiyama Kofun are treated as round kofun on the middle bank. They are excluded from the main `MIDDLE_BANK` outline and defined as independent accent LEDs on the circular-section side.

## Orientation and wiring order

View the model with the circular section of Daisen Kofun to the north and the forepart to the south.

```text
     NNW (Chayama Kofun)  NNE (Daianjiyama Kofun)
                    North (circular section)
                              ↑
                   Left (west)  Right (east)
                              ↓
                    South (forepart)
```

The wiring for each main outline starts at the tip of the forepart, passes along the left side to the circular section, and returns along the right side to the tip of the forepart.

```text
lower left -> upper left -> circle (rear circular section) -> upper right -> lower right
```

`SEGMENT_RANGES` defines every outline using these five sections. Each row position corresponds to the constant values `0..4`, from `MOUND_TOP` through `MIDDLE_BANK`.

| Outline | Lower left | Upper left | Circle (rear circular section) | Upper right | Lower right |
| --- | ---: | ---: | ---: | ---: | ---: |
| `MOUND_TOP` | `0..1` | `2..17` | `18..33` | `34..49` | `50..51` |
| `MOUND_MIDDLE` | `52..57` | `58..74` | `75..108` | `109..125` | `126..131` |
| `MOUND_BASE` | `132..140` | `141..159` | `160..201` | `202..220` | `221..229` |
| `INNER_BANK` | `230..248` | `249..282` | `283..333` | `334..367` | `368..385` |
| `MIDDLE_BANK` | `386..407` | `408..446` | `447..509` | `510..547` | `548..569` |

The complete outline ranges, left and right traversal order, circular-section order, and north-to-south rows are generated from `SEGMENT_RANGES` at startup. Effect code can therefore use constants and APIs that describe the structure instead of individual LED numbers.

## Effect APIs

| API | Purpose |
| --- | --- |
| `outline_range(outline)` | Returns the complete LED range for an outline. |
| `outline_order(outline)` | Returns an array that follows an outline in wiring order. |
| `inside_to_outside_order` | Traverses from the top mound tier to the middle bank, following the structure reference from center to outside. |
| `outside_to_inside_order` | Traverses from the middle bank to the top mound tier, following the structure reference from outside to center. |
| `forepart_to_circle_order(outline, side)` | Traverses a selected side from the forepart to the circular section. |
| `circle_to_forepart_order(outline, side)` | Traverses a selected side from the circular section to the forepart. |
| `scene_rows` | Returns the array mapping the scene to 21 rows from north to south. |
| `north_to_south_order` | Traverses `scene_rows` from north to south. |
| `attached_scene_position(index)` | Returns the effect position of Chayama Kofun or Daianjiyama Kofun. |

This mapping lets the structure guide and water effects consistently translate the structure reference's three mound tiers, three moats, two banks, and two round kofun on the middle bank into LED outlines on the model.
