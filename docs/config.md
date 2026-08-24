# Options and configuration files

`rpremote` is configured by command-line options and a project configuration
file. Command-line options take precedence over the configuration file.

## Configuration file

The default configuration file is `config/setting.json` in the project root.
On first use, the following command creates an empty file without replacing an
existing one.

```sh
rpremote setup
```

Pass `--config FILE` to any command to use a different configuration file.

```sh
rpremote build --config config/pico2.json
```

The file is a JSON object. Keys use snake_case; their corresponding CLI options
use hyphens.

```json
{
  "port": "/dev/cu.usbmodem101",
  "baud": 115200,
  "timeout": 10,
  "language": "picoruby",
  "cache": "firmware",
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/picoruby-4.0.3-pico2.uf2",
  "mount": "/Volumes/RP2350",
  "mrbgems": "Mrbgems"
}
```

All keys are validated even when the current command does not use them. Unknown
keys, empty strings, values of the wrong type, and `baud` or `timeout` values
of zero or less are errors.

## Configuration keys

| Key | Corresponding option | Default | Purpose |
| --- | --- | --- | --- |
| `language` | `--language` | `picoruby` | Language for `setup`, `build`, `flash`, and run commands (currently only `picoruby`). |
| `language_version` | `--language-version` | `4.0.3` | PicoRuby/R2P2 version used by `setup`, `build`, and `flash`. |
| `cache` | `--cache` | `firmware` | Stores PicoRuby sources and custom UF2 files. `{version}` expands to the language version. |
| `board` | `--board` | `pico2` | Board for `build` and `flash` (`pico2`, `pico2_w`). |
| `firmware` | `--firmware` | `{cache}/{language}-{language_version}-{board}.uf2` | Build output and UF2 used by `flash`. |
| `mrbgems` | `--mrbgems` | Auto-detected | Mrbgems definition for `build`; set to `false` to disable it. |
| `mount` | `--mount` | Auto-detected | RP2350 BOOTSEL volume used by `flash`. |
| `port` | `--port` | Automatically selected CDC 0 | R2P2 serial port. |
| `baud` | `--baud` | `115200` | Serial communication speed. |
| `timeout` | `--timeout` | Per command | Connection and communication timeout in seconds. |

`language_version` uses `--language-version`, rather than `--version`, so it is
not confused with `rpremote --version`.

## Common options

| Option | Purpose |
| --- | --- |
| `--config FILE` | Use a configuration file other than `config/setting.json`. |
| `-h`, `--help` | Show commands and options. |
| `-V`, `--version` | Show the rpremote version. |

## Options by command

| Command | Options |
| --- | --- |
| `setup` | `--language`, `--language-version`, `--cache`, `--force` |
| `build` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mrbgems`, `--no-mrbgems` |
| `build clean` | None. Removes only the project `build/` directory. |
| `dfu app FILE` | `--type ruby\|rite`, `--port`, `--baud`, `--timeout` |
| `dfu compile FILE` | `--output`, `--language`, `--language-version`, `--cache` |
| `dfu status` | `--port`, `--baud`, `--timeout` |
| `mrbgems check/list/lock/update` | `--file`, `--lockfile` |
| `flash` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mount`, `--port`, `--timeout` |
| `ports` | None. |
| `run`, `exec` | `--port`, `--baud`, `--timeout`, `--language` |
| `monitor`, `repl`, `reset` | `--port`, `--baud`, `--timeout` |
| `fs cp/cat/ls/rm/mkdir` | `--port`, `--baud`, `--timeout` |

The default timeout for every command is 10 seconds. `flash` uses a custom UF2
already created by `build`. When `--firmware` is omitted, it flashes
`{cache}/{language}-{language-version}-{board}.uf2`.

## Common configuration examples

This example pins the Pico 2 port and build output.

```json
{
  "port": "/dev/cu.usbmodem101",
  "cache": "firmware",
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/r2p2-picoruby-4.0.3-pico2.uf2"
}
```

With `firmware` set, both build and flash can omit their output option.

```sh
rpremote setup
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run examples/education/01_blink/main.rb
```

To change only the PicoRuby version once, override it on the command line
without changing the configuration file.

```sh
rpremote setup --language-version 3.4.2
rpremote build --language-version 3.4.2 \
  --firmware firmware/r2p2-picoruby-3.4.2-pico2.uf2
```
