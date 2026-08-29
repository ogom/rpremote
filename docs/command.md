# Command reference

[日本語](command.ja.md)

This page summarizes the `rpremote` commands. Use `rpremote --help` for the complete command list, and `rpremote <command> --help` for the current syntax, defaults, and effects of an individual command.

## 1. Prepare a project

| Command | Description |
| --- | --- |
| `rpremote setup` | Create project configuration and prepare language sources. |
| `rpremote config show` | Show the effective configuration after file and command-line options are resolved. |

## 2. Add mrbgems and build firmware

| Command | Description |
| --- | --- |
| `rpremote mrbgems …` | Check, list, lock, or update mrbgem dependencies. |
| `rpremote build` | Build a custom UF2, including project mrbgems. |
| `rpremote build clean` | Remove generated intermediate build files. |

## 3. Install or recover firmware

| Command | Description |
| --- | --- |
| `rpremote flash` | Flash a built UF2 through an RP2350 BOOTSEL volume. |
| `rpremote bootsel` | Ask the running R2P2 firmware to enter BOOTSEL and wait for its USB volume. Use physical BOOTSEL for the first install. |
| `rpremote bootsel --reset-flash-memory` | Enter BOOTSEL and erase all Pico 2 external flash memory. Run `rpremote flash` afterward to reinstall R2P2. |

## 4. Develop and operate daily

| Command | Description |
| --- | --- |
| `rpremote ports` | List detected R2P2 serial ports after flashing. |
| `rpremote deploy PATH` | Build and flash firmware, copy `PATH/lib/NAME` to `:/lib/NAME`, then temporarily run `PATH/main.rb`. |
| `rpremote fs cp SOURCE DESTINATION [--recursive]` | Transfer one file between the local computer and R2P2. Exactly one path uses the `:` remote-path prefix. With `--recursive`, create missing remote directories and upload a local directory tree. |
| `rpremote fs push LOCAL_DIR :/REMOTE_DIR` | Alias of `fs cp --recursive`. It recursively uploads a local directory tree without deleting remote-only files. |
| `rpremote fs cat/ls/rm/mkdir` | Print, list, permanently remove, or create remote files and directories. |
| `rpremote run FILE` | Upload and run a Ruby file, relay output lines in real time, then remove it; exit nonzero on a Ruby exception. Use `--reset-on-timeout` to reset R2P2 after a run timeout. |
| `rpremote exec CODE` | Run short Ruby code and exit nonzero on a Ruby exception. |
| `rpremote monitor` | Open a serial monitor. |
| `rpremote repl` | Open PicoIRB. |
| `rpremote reset` | Reboot R2P2 and wait for reconnection. |

## 5. Update a DFU boot application

| Command | Description |
| --- | --- |
| `rpremote dfu compile FILE` | Compile `.rb` to matching PicoRuby bytecode for DFU. |
| `rpremote dfu app FILE` | Stage a Ruby or version-checked bytecode application through PicoModem DFU. Run `rpremote reset` to boot it. |
| `rpremote dfu status` | Show the active and candidate DFU slots. |
| `rpremote dfu remove` | Remove both DFU boot applications; use `rpremote reset` to stop one already running. |

Ruby-exception exit statuses for `run` and `exec` require R2P2 firmware with Ruby exception status support. UF2 files built with `rpremote build` from this repository's PicoRuby sources include that support.
