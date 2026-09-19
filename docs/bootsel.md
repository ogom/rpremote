# Entering BOOTSEL mode

`rpremote bootsel` asks a running R2P2 firmware to restart a Raspberry Pi Pico 2 in USB BOOTSEL mode, then waits for the `RP2350` volume. Use it before `rpremote flash` when replacing firmware.

## Prerequisites

The firmware running on the board must include the local `picoruby-bootsel` mrbgem from the project-root `Mrbgems` file. Build and install it once while holding the physical BOOTSEL button:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

The physical button is required for the first installation and for recovery when R2P2 is unavailable.

## Enter BOOTSEL mode

```sh
rpremote bootsel
```

The command transfers a temporary Ruby script through PicoModem, then starts it through the R2P2 shell. The script requires `bootsel` and calls `Machine.enter_bootsel`. The serial device disconnects and the command prints the mounted BOOTSEL volume, for example:

```text
BOOTSEL ready: /Volumes/RP2350
```

Then flash the intended UF2:

```sh
rpremote flash --firmware firmware/picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

No PicoRuby source patch or built-in R2P2 `/bin/bootsel` command is used.

## Call from `rpremote exec`

For a firmware built with this project's `Mrbgems` file, `rpremote exec` automatically requires `bootsel` before the supplied code. Call the API directly:

```sh
rpremote exec 'Machine.enter_bootsel'
```

To make the dependency explicit, use:

```sh
rpremote exec 'require "bootsel"; Machine.enter_bootsel'
```

`Machine.enter_bootsel` disconnects the serial device before the R2P2 shell can return a prompt. A connection-closed error from `rpremote exec` is therefore expected after the reset request. Use `rpremote bootsel` when the command should wait for the BOOTSEL volume.

## Reset external flash memory

```sh
rpremote bootsel --reset-flash-memory
```

This writes the universal reset UF2 after BOOTSEL is entered. It permanently erases the Pico 2 external flash, including R2P2 firmware and stored data. Reinstall R2P2 with `rpremote flash` afterward.

## Troubleshooting

If `rpremote bootsel` cannot enter BOOTSEL mode, hold the physical BOOTSEL button while connecting the board and flash a UF2 built with the current `Mrbgems` file. Check `rpremote ports` and pass `--port` when more than one R2P2 board is connected.
