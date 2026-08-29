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
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/picoruby-4.0.3-pico2.uf2",
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
rpremote config show --config config/pico2.json --board pico2_w
```

For example, `--no-mrbgems` disables automatic Mrbgems detection. `{version}` in `cache` expands to the selected language version, and the default firmware path expands from the resolved cache, language, language version, and board.

```text
language=picoruby
language_version=4.0.3
board=pico2_w
cache=firmware
firmware=firmware/picoruby-4.0.3-pico2_w.uf2
mrbgems=false
mount=auto
port=auto
baud=115200
timeout=20.0
```

## Configuration keys

| Key | Corresponding option | Default | Purpose |
| --- | --- | --- | --- |
| `language` | `--language` | `picoruby` | Language for `setup`, `build`, `deploy`, `flash`, and run commands (currently only `picoruby`). |
| `language_version` | `--language-version` | `4.0.3` | PicoRuby/R2P2 version used by `setup`, `build`, `deploy`, and `flash`. |
| `cache` | `--cache` | `firmware` | Stores PicoRuby sources and custom UF2 files. `{version}` expands to the language version. |
| `board` | `--board` | `pico2` | Board for `build`, `deploy`, and `flash` (`pico2`, `pico2_w`). |
| `firmware` | `--firmware` | `{cache}/{language}-{language_version}-{board}.uf2` | Build output and UF2 used by `deploy` or `flash`. |
| `mrbgems` | `--mrbgems` | Auto-detected | Mrbgems definition for `build` or `deploy`; set to `false` to disable it. |
| `mount` | `--mount` | Auto-detected | RP2350 BOOTSEL volume used by `bootsel`, `deploy`, or `flash`. |
| `port` | `--port` | Automatically selected CDC 0 | R2P2 serial port. |
| `baud` | `--baud` | `115200` | Serial communication speed. |
| `timeout` | `--timeout` | Per command | Connection and communication timeout in seconds. During `run` and `exec`, this is the maximum interval without output. |

`language_version` uses `--language-version`, rather than `--version`, so it is not confused with `rpremote --version`.

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
| `deploy PATH` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mrbgems`, `--no-mrbgems`, `--mount`, `--port`, `--baud`, `--timeout` |
| `bootsel` | `--mount`, `--port`, `--baud`, `--timeout` |
| `dfu app FILE` | `--type ruby\|rite`, `--port`, `--baud`, `--timeout` |
| `dfu compile FILE` | `--output`, `--language`, `--language-version`, `--cache` |
| `dfu status` | `--port`, `--baud`, `--timeout` |
| `mrbgems check/list/lock/update` | `--file`, `--lockfile` |
| `flash` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mount`, `--port`, `--timeout` |
| `config show` | `--language`, `--language-version`, `--board`, `--cache`, `--firmware`, `--mrbgems`, `--no-mrbgems`, `--mount`, `--port`, `--baud`, `--timeout` |
| `ports` | None. |
| `run`, `exec` | `--port`, `--baud`, `--timeout`, `--language` |
| `monitor`, `repl`, `reset` | `--port`, `--baud`, `--timeout` |
| `fs cp/push/cat/ls/rm/mkdir` | `--port`, `--baud`, `--timeout`; `fs cp` also accepts `--recursive` |

The default timeout for every command is 20 seconds. For `run` and `exec`, output from the running program resets this timeout. `flash` uses a custom UF2 already created by `build`; `deploy` builds that UF2 before flashing it. When `--firmware` is omitted, both use `{cache}/{language}-{language-version}-{board}.uf2`.

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
rpremote run examples/picoruby/education/01_blink/main.rb
```

To change only the PicoRuby version once, override it on the command line without changing the configuration file.

```sh
rpremote setup --language-version 3.4.2
rpremote build --language-version 3.4.2 --firmware firmware/r2p2-picoruby-3.4.2-pico2.uf2
```
