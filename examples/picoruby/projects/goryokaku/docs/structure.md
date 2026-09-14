# Structure

[日本語](structure.ja.md)

> **Goryokaku** | Goryokaku-cho, Hakodate, Hokkaido

## Overview

Goryokaku is a Western-style earthwork fort built by the Edo shogunate to defend the Hakodate Magistrate's Office. Rangaku scholar Takeda Ayasaburo designed it. Construction began in 1857, and the magistrate's office moved there in 1864.

Five projecting bastions form its star-shaped pentagon. Low, thick earthworks, stonework, and a surrounding water moat allow defenders on one projection to cover an adjacent wall. A single ravelin protects the southwest main entrance.

| Item | Description |
| ---- | ----------- |
| Type | Western-style bastioned earthwork |
| Main structures | Five bastions, main and lower ramparts, stonework, water moat |
| Main front | Southwest |
| Entrance outwork | One ravelin |
| Area inside moat | About 125,500 m² |
| Moat area | About 56,400 m² |
| Moat width and depth | Up to about 30 m; about 4–5 m deep |
| Moat perimeter | About 1.8 km |
| Designation | National Special Historic Site, Goryokaku Fort |

## Star earthworks

A bastion projects outward from a defensive wall. Goryokaku links five bastions with straight ramparts to form its star outline. Earthworks dominate instead of high stone walls, reducing both the exposed target area and dangerous stone fragments under artillery fire.

The main rampart is about 27–30 m wide and 5–7 m high. Soil excavated from the moat was compacted in layers. Parts of the three entrances use stonework; the southwest front includes overhanging stones intended to impede climbing.

A lower rampart, about 10 m wide and 2 m high, lies between the main rampart and the moat. The model represents the five directions as ten segments, with two edges for each bastion.

## Moat, ravelin, and interior

The water moat follows the star-shaped main rampart and has a perimeter of about 1.8 km. From the center outward, the relationship is:

```text
Interior and magistrate's office → ramparts and stonework → lower rampart → moat → outer perimeter
```

The triangular ravelin protects the southwest entrance. Five were originally planned, but only one was built. Because it is a defensive structure distinct from the star body, it is also an independent LED zone in the model.

There are now three entrances, at the southwest, east, and north. Screening ramparts inside them prevented a direct view into the fort. Most of the central Hakodate Magistrate's Office was dismantled in 1871; part of it was later reconstructed from archaeological and documentary research and opened in 2010.

## Translation to the model

The project treats a representative length of about 535 m as 276 mm on the model.

```text
535,000 mm ÷ 276 mm ≒ 1,938
```

The nominal scale is therefore about 1:1,938. It guides relative proportions and relief rather than serving as construction dimensions for an exact historical reproduction. The 535 m representative length and the roughly 1.8 km moat perimeter measure different features.

| Full-size structure | Full-size dimension | Approximate model dimension |
| ------------------- | ------------------: | --------------------------: |
| Main rampart height | About 5–7 m | About 2.6–3.6 mm |
| Main rampart width | About 27–30 m | About 13.9–15.5 mm |
| Lower rampart height and width | About 2 m and 10 m | About 1.0 mm and 5.2 mm |
| Maximum moat width and depth | About 30 m and 4–5 m | About 15.5 mm and 2.1–2.6 mm |

The 380 LEDs are divided into three zones so the model can identify and animate the principal structures.

| Zone | Addresses | Count | Model feature |
| ---- | --------: | ----: | ------------- |
| `STAR` | `0..169` | 170 | Star body and five bastions |
| `RAVELIN` | `170..189` | 20 | Southwest ravelin |
| `OUTER` | `190..379` | 190 | Outline beyond the moat |

The winter event “Hoshi no Yume” inspired the model, but the LEDs are not a literal scaled copy of its bulbs. The zones abstract recognizable historic features so that the ravelin and outer line can be controlled independently. See [LED layout](led_layout.md) for exact wiring ranges.

## Orientation

The display and structural diagrams use Z-up, with the model face horizontal. Tambourine performance turns the face upright into Y-up with group 5 at the top. In that position the Z axis is perpendicular to the model face and describes both shake and strike motion.

Changing orientation does not change LED addresses or structural zones. Y-up is the reference for interpreting performance gestures and light travel.

## References

- City of Hakodate, “[Special Historic Site: Goryokaku](https://www.city.hakodate.hokkaido.jp/docs/2014011601161/)” (Japanese)
- City of Hakodate, “[History of Goryokaku: construction to restoration of imperial rule](https://www.city.hakodate.hokkaido.jp/docs/2014011700352/)” (Japanese)
- City of Hakodate, “[Buildings and remains inside Goryokaku](https://www.city.hakodate.hokkaido.jp/docs/2014012100380/)” (Japanese)
- Hakodate Housing and Urban Facilities Public Corporation, “[Scenes in Goryokaku Park](https://www.hakodate-jts-kosya.jp/park/goryokaku/scenery/)” (Japanese)
