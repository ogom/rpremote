# rpremote commands

Run commands from the project root. Use `rpremote --help` as the authority for the installed CLI syntax.

## 1. Prepare source and dependencies

```sh
rpremote setup [--language picoruby] [--language-version VERSION] [--cache DIR] [--force]
rpremote mrbgems check [--file FILE] [--lockfile FILE]
rpremote mrbgems lock [--file FILE] [--lockfile FILE]
rpremote mrbgems update [--file FILE] [--lockfile FILE]
```

`setup` creates `config/setting.json` without replacing an existing file, downloads the selected PicoRuby source to `{cache}/picoruby-{language_version}/`, and saves the official `nuke_universal.uf2` recovery image in `firmware/`. `--force` deliberately replaces prepared source and refreshes recovery assets.

`check` validates mrbgem definitions and local paths. `lock` refreshes `Mrbgems.lock` while retaining recorded GitHub commits; `update` intentionally resolves branch dependencies again.

## 2. Build custom firmware

```sh
rpremote build [--language picoruby] [--language-version VERSION] [--board pico2|pico2_w] [--firmware FILE] [--cache DIR] [--mrbgems FILE|--no-mrbgems]
rpremote build clean
```

```sh
rpremote setup --language-version 4.0.3
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language-version 4.0.3 --board pico2 --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

The project-root `Mrbgems` is auto-detected. `--firmware` names the completed UF2. `build --output` is not supported. `build clean` removes only generated `build/` intermediates.

## 3. Install or recover board firmware

```sh
rpremote bootsel [--reset-flash-memory] [--mount DIR] [--port PORT] [--baud RATE] [--timeout SEC]
rpremote flash [--firmware FILE] [--language picoruby] [--language-version VERSION] [--board pico2|pico2_w] [--cache DIR] [--mount DIR] [--port PORT] [--timeout SEC]
```

For the first R2P2 installation, hold the physical BOOTSEL button while connecting the Pico, then run `flash`. With a working PicoRuby 4.x R2P2 installation, `bootsel` requests USB BOOTSEL mode through CDC 0; it waits for the RP2350 volume before `flash` copies the UF2.

```sh
rpremote bootsel
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

`bootsel --reset-flash-memory` copies `nuke_universal.uf2` to the BOOTSEL volume and erases the Pico's external flash. It removes stored data and firmware. Wait for BOOTSEL again, then run `rpremote flash` to reinstall R2P2.

## 4. Daily development and filesystem deployment

```sh
rpremote ports
rpremote run FILE [--port PORT] [--baud RATE] [--timeout SEC]
rpremote exec CODE [--port PORT] [--baud RATE] [--timeout SEC]
rpremote reset [--port PORT] [--baud RATE] [--timeout SEC]
rpremote monitor [--port PORT] [--baud RATE] [--timeout SEC]
rpremote repl [--port PORT] [--baud RATE] [--timeout SEC]
```

`run` and `exec` use a temporary `/home/.rpremote-run-*.rb` and remove it after execution. `--timeout` is the Shell-operation timeout; it is not a program run-duration limit. `monitor` and `repl` exit with `Ctrl-]`.

Remote paths start with `:`. Exactly one `fs cp` path must be remote.

```sh
rpremote fs cp FILE :/home/FILE [--port PORT]
rpremote fs cp :/home/FILE FILE [--port PORT]
rpremote fs cp --recursive LOCAL_DIR :/REMOTE_DIR [--port PORT]
rpremote fs push LOCAL_DIR :/REMOTE_DIR [--port PORT]
rpremote fs cat :/home/FILE [--port PORT]
rpremote fs ls :/home [--port PORT]
rpremote fs mkdir :/home/DIR [--port PORT]
rpremote fs rm :/home/FILE [--port PORT]
```

`fs push` is the recursive-copy alias for a local directory. It creates missing destination directories and copies its contents, but does not remove remote-only files.

## 5. Build, activate, and remove DFU applications

```sh
rpremote dfu app FILE [--type ruby|rite] [--port PORT] [--baud RATE] [--timeout SEC]
rpremote dfu compile FILE [--output FILE] [--language picoruby] [--language-version VERSION] [--cache DIR]
rpremote dfu status [--port PORT] [--baud RATE] [--timeout SEC]
rpremote dfu remove [--port PORT] [--baud RATE] [--timeout SEC]
```

```sh
rpremote dfu status
rpremote dfu app examples/picoruby/education/07_dfu/main.rb
rpremote reset
rpremote dfu status
```

`dfu app` infers `RUBY` from `.rb` and `RITE` from `.mrb`; it stages an A/B boot application, not PicoRuby firmware or embedded mrbgems. Candidate code must call `DFU.confirm` only after startup checks succeed. `dfu remove` permanently clears both slots. Reset after removal to stop an application already executing in RAM before `run` or other Shell work.

## Common options

| Option | Purpose |
| --- | --- |
| `--config FILE` | Select a file other than `config/setting.json`. |
| `--language picoruby` | Select the implemented runtime backend. |
| `--language-version VERSION` | Select the PicoRuby/R2P2 source version. |
| `--board BOARD` | Select `pico2` or `pico2_w`; default: `pico2`. |
| `--cache DIR` | Store versioned sources and default UF2 output; default: `firmware`. |
| `--firmware FILE` | UF2 output for `build` or input for `flash`/`deploy`. |
| `--mount DIR` | Select the RP2350 BOOTSEL volume. |
| `--port PORT` | Select an R2P2 CDC 0 serial port. |
| `--baud RATE` | Serial speed; default: `115200`. |
| `--timeout SEC` | Timeout in seconds; default: `20`. |

## Validate the CLI

Run from `packages/rpremote` in the source repository.

```sh
bundle install
bundle exec rake
bundle exec rbs -I sig validate
bundle exec ruby exe/rpremote --help
```
