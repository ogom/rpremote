# Options and configuration files

`rpremote` is configured by command-line options and a project configuration file. Command-line options take precedence over the configuration file.

## Configuration file

The default configuration file is `config/setting.json` in the project root. On first use, the following command creates an empty file without replacing an existing one.

```sh
rpremote setup
```

Pass `--config FILE` to any command to use a different configuration file.

```sh
rpremote build --config config/pico2.json
```

The file is a JSON object. Keys use snake_case; their corresponding CLI options use hyphens.

```json
{
  "port": "/dev/cu.usbmodem101",
  "baud": 115200,
  "timeout": 20,
  "language": "picoruby",
  "cache": "firmware",
  "language_version": "latest",
  "board": "pico2",
  "firmware": "firmware/picoruby-latest-pico2.uf2",
  "mount": "/Volumes/RP2350",
  "mrbgems": "Mrbgems"
}
```

All keys are validated even when the current command does not use them. Unknown keys, empty strings, values of the wrong type, and `baud` or `timeout` values of zero or less are errors.

## Precedence

| Priority | Source | Effect |
| --- | --- | --- |
| 1 | Command-line option | Overrides a configuration value for the selected command. |
| 2 | `--config FILE`, or `config/setting.json` when omitted | Supplies project defaults. |
| 3 | Built-in default | Used when neither the command line nor configuration provides a value. |

## Show effective configuration

`rpremote config show` resolves the configuration file, defaults, and command-line options without connecting to a board or changing project state. It prints the selected language, language version, board, cache, firmware path, mrbgems setting, mount, port, baud rate, and timeout.

```sh
rpremote config show --config config/pico2.json
```

For example, `--no-mrbgems` disables automatic Mrbgems detection. `{version}` in `cache` expands to the selected language version, and the default firmware path expands from the resolved cache, language, language version, and board.

```text
language=picoruby
language_version=latest
board=pico2_w
cache=firmware
firmware=firmware/picoruby-latest-pico2_w.uf2
mrbgems=false
mount=auto
port=auto
baud=115200
timeout=20.0
```

## Configuration keys

`config/setting.json` is the normal place to select the target. Keep `language`, `language_version`, `board`, and `mount` there rather than passing them on every command.

| Key | Default | Purpose |
| --- | --- | --- |
| `language` | `picoruby` | Language for firmware and run commands (currently only `picoruby`). |
| `language_version` | `latest` | PicoRuby/R2P2 version used for firmware operations. `latest` tracks the `master` branch. |
| `cache` | `firmware` | Stores PicoRuby sources and custom UF2 files. `{version}` expands to the language version. |
| `board` | `pico2` | Board for firmware operations (`pico2`, `pico2_w`). |
| `firmware` | `{cache}/{language}-{language_version}-{board}.uf2` | Build output and UF2 used by `deploy` or `flash`. |
| `mrbgems` | Auto-detected | Mrbgems definition for `build` or `deploy`; set to `false` to disable it. |
| `mount` | Auto-detected | RP2350 BOOTSEL volume used by `bootsel`, `deploy`, or `flash`. |
| `port` | Automatically selected CDC 0 | R2P2 serial port. |
| `baud` | `115200` | Serial communication speed. |
| `timeout` | Per command | Connection and communication timeout in seconds. During `run` and `exec`, this is the maximum interval without output. |

## Common options

| Option | Purpose |
| --- | --- |
| `--config FILE` | Use a configuration file other than `config/setting.json`. |
| `-h`, `--help` | Show commands and options. |
| `-V`, `--version` | Show the rpremote version. |

## Options by command

Use this table when comparing configuration and execution choices. Current syntax, defaults, and effects for an individual command are also available from `rpremote <command> --help`.

| Command | Main available options |
| ------- | ---------------------- |
| `setup` | `--language`, `--language-version`, `--cache`, `--force` |
| `build` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mrbgems`, `--no-mrbgems` |
| `build clean` | None; removes only the project's `build/` directory |
| `bootsel` | `--reset-flash-memory`, `--mount`, `--port`, `--baud`, `--timeout` |
| `deploy PATH` | `--build`, `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mrbgems`, `--no-mrbgems`, `--mount`, `--port`, `--baud`, `--timeout` |
| `dfu app FILE` | `--type ruby\|rite`, `--port`, `--baud`, `--timeout` |
| `dfu compile FILE` | `--output`, `--language`, `--language-version`, `--cache` |
| `dfu status` / `dfu remove` | `--port`, `--baud`, `--timeout` |
| `mrbgems check/list/lock/update` | `--file`, `--lockfile` |
| `flash` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mount`, `--port`, `--timeout` |
| `config show` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mrbgems`, `--no-mrbgems`, `--mount`, `--port`, `--baud`, `--timeout` |
| `ports` | None |
| `run FILE` | `--port`, `--baud`, `--timeout`, `--reset-on-timeout`, `--language` |
| `exec CODE` | `--port`, `--baud`, `--timeout`, `--language` |
| `monitor` / `repl` / `reset` | `--port`, `--baud`, `--timeout` |
| `fs cp` | `--recursive`, `--port`, `--baud`, `--timeout` |
| `fs push/cat/ls/rm/mkdir` | `--port`, `--baud`, `--timeout` |

```sh
rpremote deploy --help
rpremote dfu app --help
rpremote fs cp --help
```

`run` and `exec` treat the timeout as the maximum interval without program output. `flash` and `deploy` use the selected custom UF2, while `deploy --build` rebuilds it before flashing.

## Common configuration examples

This example pins the Pico 2 port and build output.

```json
{
  "port": "/dev/cu.usbmodem101",
  "cache": "firmware",
  "language_version": "latest",
  "board": "pico2",
  "firmware": "firmware/r2p2-picoruby-latest-pico2.uf2"
}
```

With `firmware` set, both build and flash can omit their output option.

```sh
rpremote setup
rpremote build
rpremote flash
rpremote run examples/picoruby/education/01_blink/main.rb
```

The PicoRuby version can be changed with `language_version` in `config/setting.json` or the `--language-version` option. After updating the configuration file, run `rpremote setup --force` before building. For a temporary override, pass the same `--language-version VERSION` to both `setup` and `build`.
