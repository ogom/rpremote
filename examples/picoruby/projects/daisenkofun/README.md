# Daisen Kofun WS2812 sample

[日本語](README.ja.md)

This PicoRuby sample uses a Raspberry Pi Pico 2 and `ws2812-plus` to run multiple illuminations on the 572 WS2812B LEDs in a Daisen Kofun model. It clears every LED when execution ends.

## Safety

Power the 572 LEDs with an external supply designed for the LEDs and wiring. Do not power them from a Pico 2 GPIO, `3V3(OUT)`, or `VBUS`. Connect the Pico 2 and LED supply grounds, and disconnect both power sources before changing wiring.

The current brightness is set by `BRIGHTNESS_PERCENT` in [`config.rb`](mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb). Do not increase it until the supply capacity, voltage drop, wiring, connectors, and temperatures have been checked.

## Wiring

| WS2812B | Connection |
| --- | --- |
| DIN | Pico 2 GP14 (physical pin 19) |
| GND | Ground shared by the Pico 2 and external LED supply |
| VDD | External supply appropriate for the LEDs |

Use a suitable level shifter if a 5 V LED does not reliably recognize the 3.3 V DIN signal.

## Build and run

To build, flash, and run `main.rb` in one operation, run the following command from the repository root:

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

This command builds R2P2 firmware containing `ws2812-plus` and `daisenkofun-illuminations`, flashes it to the Pico 2, reconnects to the R2P2 Shell, and runs `main.rb`. Flashing replaces the firmware already installed on the Pico 2. For the first installation, when serial BOOTSEL entry is not yet available, connect the Pico 2 while holding its BOOTSEL button.

### Running each step separately

From the repository root, check the dependencies and build R2P2 firmware containing `ws2812-plus` and `daisenkofun-illuminations`.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

Flash the built firmware to the initialized Pico 2.

```sh
rpremote flash
```

After flashing the firmware, run the entry point. The illuminations are embedded in the firmware, so `lib/daisenkofun` does not need to be pushed.

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

Choose `:short`, `:long`, `:all`, or `:only` with `run_mode` in [`main.rb`](main.rb). For `:only`, set `only_key` to the pattern to run.

| Mode | Patterns |
| --- | --- |
| `:short` | `structure_guide`, `divine_light`, `launch_fireworks`, `sunrise`, `dappled_light`, `triple_moat_mirror`, `water_ripples` |
| `:long` | `structure_guide`, `sunrise`, `dappled_light`, `cherry_blossom`, `triple_moat_mirror`, `water_ripples`, `sakai_sunset`, `moonlight`, `starry_kofun`, `peekaboo`, `heartbeat`, `jewel_box`, `aurora`, `symmetric_forepart_chase`, `two_banks_clockwise`, `rainbow_comet`, `divine_light`, `attached_kofun_lights`, `launch_fireworks` |
| `:all` | `moonlight`, `starry_kofun`, `attached_kofun_lights`, `goodnight_pastel`, `dappled_light`, `green_shimmer`, `fireflies`, `sea`, `triple_moat_mirror`, `sunrise`, `sakai_sunset`, `golden_breath`, `aurora`, `divine_light`, `cherry_blossom`, `rose_garden`, `pastel_ribbon`, `princess_sparkle`, `unicorn_dream`, `peekaboo`, `heartbeat`, `jewel_box`, `symmetric_forepart_chase`, `rainbow_comet`, `two_banks_clockwise`, `color_bound`, `carnival_chase`, `torch_procession`, `fireworks`, `launch_fireworks` |
| `:only` | The one pattern selected by `only_key` |

The current `main.rb` sets `run_mode = :short` and `only_key = :structure_guide`. The `:short` mode does not use `only_key`. A run succeeds when it plays the seven selected patterns in sequence, followed by `daisenkofun: LEDs off` and then `daisenkofun: OK`.

## Illuminations

See the [illumination catalog](docs/illuminations.md) for the names and descriptions of all 32 selectable patterns.

## Configuration

Change the GPIO and brightness in [`config.rb`](mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb). Change each mode's patterns, `wait_ms`, and `loops` in [`setlist.rb`](mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb). The `:short`, `:long`, and `:all` frame intervals are set by `SHORT_FRAME_MS`, `LONG_FRAME_MS`, and `ALL_FRAME_MS`, respectively. See the [LED layout](docs/led_layout.md) for the model's LED address map. Rebuild and reflash the firmware after changing the mrbgem.

## File structure

| File | Responsibility |
| --- | --- |
| `main.rb` | Select the run mode and start the illumination. |
| `mrbgems/daisenkofun-illuminations/mrbgem.rake` | Define the local mrbgem and its `ws2812-plus` dependency. |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb` | Define GPIO and brightness. |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/color.rb` | Define the colors used by illuminations. |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/led_layout.rb` | Define the 572 LED addresses and their positions on the model. |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illumination.rb` | Initialize WS2812, run the selected illuminations in sequence, and clear the LEDs. |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb` | Manage each mode's patterns, `wait_ms`, `loops`, and the `:only` selection. |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illuminations/` | Implement all 32 selectable patterns and their common base. |
| `docs/illuminations.md` | Describe the selectable illuminations. |
| `docs/led_layout.md` | Describe how the 572 LED addresses map to the model. |
| `docs/mrbgem_migration.md` | Record the loading tests and migration to an mrbgem. |
| `docs/structure.md` | Describe Daisen Kofun and the structural elements represented by the model. |
