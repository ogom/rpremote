# rpremote development examples

Inspect project configuration and dependency files before running commands. Build without touching hardware unless the user asks for device execution.

## Reproducible custom firmware

A PicoRuby project can combine public and local mrbgems in `Mrbgems`:

```ruby
# frozen_string_literal: true
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

The local path is relative to `Mrbgems` and must contain `mrbgem.rake`.

```sh
rpremote setup --language picoruby --language-version 4.0.3
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --board pico2
```

Commit `Mrbgems` and `Mrbgems.lock` together. Ordinary builds reuse the locked GitHub commit and local-content hash. Use `mrbgems update` only for an intended dependency update.

## Device checks and troubleshooting

```sh
rpremote ports
rpremote exec 'p PICORUBY_VERSION' --port /dev/cu.usbmodem101
rpremote fs ls :/home --port /dev/cu.usbmodem101
```

- If no port is found, confirm that custom R2P2 firmware is installed and that the board has restarted after flashing.
- PicoRuby 3.4 typically exposes two CDC interfaces and 4.x exposes three. Select CDC 0, normally the macOS callout device ending in `1`.
- If several devices are found, use an explicit `--port`. Do not guess which attached board should be modified.
- For `Resource busy`, close serial monitors, terminals, and stale rpremote processes before retrying.
- For a Shell or PicoModem timeout, reset the intended board, confirm its port, then increase `--timeout` only if the operation legitimately needs longer.
- When `run` output contains `NameError`, `NoMethodError`, or another Ruby exception, treat the hardware check as failed even if the local process exits successfully.

## BOOTSEL flashing

Use the correct completed UF2 and an RP2350 volume:

```sh
rpremote build --language-version 4.0.3 --board pico2 --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
rpremote bootsel
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

For the first R2P2 installation, use the physical BOOTSEL button instead of `rpremote bootsel`. If auto-detection fails, inspect `INFO_UF2.TXT`. Do not flash a Pico/Pico W RP2040 volume with a Pico 2/Pico 2 W RP2350 image.

To erase external flash deliberately, use the recovery image prepared by `setup`:

```sh
rpremote bootsel --reset-flash-memory
# Wait until the RP2350 BOOTSEL drive appears again.
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

## Temporary and persistent applications

Use `run` for a temporary source file:

```sh
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

It uploads, executes, and removes the temporary file. For a persistent source file, copy it explicitly only when persistent installation is requested:

```sh
rpremote fs cp main.rb :/home/app.rb
```

An existing `/home/app.rb` or `/home/app.mrb` may take precedence over DFU slots, so remove an obsolete legacy application before a DFU boot test.

## Safe DFU application update

A candidate application confirms itself after startup checks:

```ruby
require "dfu"
# Initialize hardware and run self-checks.
DFU.confirm
# Enter the application loop.
```

Stage and activate it as follows:

```sh
rpremote dfu status
rpremote dfu app examples/picoruby/education/07_dfu/main.rb
rpremote reset
rpremote dfu status
```

Preserve at least one `confirmed` slot. Use an application that deliberately omits `DFU.confirm` only for an explicit rollback test.

When returning from a persistent DFU application to interactive development, clear the slots and reset. Removal changes storage; reset stops a boot application already running in RAM.

```sh
rpremote dfu remove
rpremote reset
```

## Version-matched bytecode

PicoRuby 3.x bytecode starts with `RITE0300`; PicoRuby 4.x starts with `RITE0400`. Compile from the source cache matching the installed device:

```sh
rpremote exec 'p PICORUBY_VERSION'
rpremote dfu compile examples/picoruby/education/07_dfu/main.rb --language-version 4.0.3 --output build/dfu/app.mrb
rpremote dfu app build/dfu/app.mrb
```

rpremote checks `PICORUBY_VERSION` and rejects a mismatched `.mrb` before transfer. Use a `.rb` application when the connected R2P2 cannot report its PicoRuby version.
