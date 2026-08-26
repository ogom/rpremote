# Custom firmware for 04_ws2812

`examples/picoruby/education/04_ws2812/main.rb` uses the `picoruby-ws2812-plus` gem, which is not included in the standard R2P2 firmware. Build and flash the custom firmware below only when running this example on a Pico 2.

See [Mrbgems and Mrbgems.lock](mrbgems.md) for the `Mrbgems` and `Mrbgems.lock` formats and update procedure.

## 1. Prepare the source

From the repository root, fetch PicoRuby 4.0.3.

```sh
rpremote setup --language picoruby --language-version 4.0.3 --cache firmware
```

The source is extracted to `firmware/picoruby-4.0.3/`. The official source does not include `picoruby-ws2812-plus`; the project `Mrbgems` declares it instead.

### PicoRubySourcePatch

`PicoRubySourcePatch` is bundled with rpremote and applies the required R2P2 Shell patch to the extracted PicoRuby source.
When a Ruby program raises, the patch makes R2P2 emit a private status marker.
This lets `rpremote run` and `rpremote exec` exit nonzero without guessing from exception text.

`rpremote setup` applies the patch after preparing the source, and `rpremote build` applies it again before building.
The operation is idempotent, so updating the gem and rebuilding an existing source cache also applies the current patch.

Bundled patches target PicoRuby 4.0.3 and 3.4.5; PicoRuby 3.4.2 uses the compatible 3.4.5 patch.
These are source-patch targets, not a guarantee that every R2P2 version starts successfully on every board.

If patch application fails, the cached source differs from the expected PicoRuby release.
Recreate that version's cache with `rpremote setup --force --language-version VERSION`, then build again.

```ruby
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
```

`picoruby-ws2812-plus` is an mruby/c C extension, so it also requires `vm :mrubyc`. rpremote maps that VM to the official `femtoruby` build configuration for PicoRuby 4 and to `picoruby` for PicoRuby 3.

Check the definition and its pinned commit with the following commands.

```sh
rpremote mrbgems check
rpremote mrbgems list
```

The pinned commit is recorded in `Mrbgems.lock`. Run `rpremote mrbgems update` only when updating to the latest version.

## 2. Build a UF2 for Pico 2

```sh
rpremote build --language picoruby --language-version 4.0.3 --board pico2 --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

`rpremote build` auto-detects `Mrbgems` and generates a temporary build configuration that adds the gem to the official PicoRuby configuration.
There is no need to edit the official source manually; `PicoRubySourcePatch` is the managed exception for R2P2 exception-status support.

The completed UF2 is saved to `firmware/r2p2-picoruby-4.0.3-pico2.uf2` and intermediate files are created under `build/`. If `--firmware` is omitted, `firmware/picoruby-4.0.3-pico2.uf2` is also the default output path.

## 3. Flash Pico 2

Hold the Pico 2 BOOTSEL button while connecting USB, then specify the mounted volume.

```sh
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

## 4. Wire and run WS2812B

- Connect WS2812B DIN to GP14 (physical pin 19).
- Connect WS2812B GND to a Pico 2 GND pin.
- Connect WS2812B VDD to 3V3(OUT).
- Connect a button between GP15 (physical pin 20) and GND.

```sh
rpremote run examples/picoruby/education/04_ws2812/main.rb --timeout 15
```

Each button press selects one of seven colors; the example prints `ws2812: OK` at the end. For a 5 V-only WS2812B module, confirm the supply voltage and whether a level shifter is required.
