# rpremote commands

Run project commands from the project root. For the authoritative installed
syntax, run `rpremote --help`.

## Set up PicoRuby source

```sh
rpremote setup [--language picoruby] [--language-version VERSION] \
  [--cache DIR] [--force]
```

`setup` creates `config/setting.json` without replacing an existing file and
downloads the selected PicoRuby source to
`{cache}/picoruby-{language_version}/`. Use `--force` only to replace the
prepared source deliberately.

## Manage mrbgems

```sh
rpremote mrbgems check [--file FILE] [--lockfile FILE]
rpremote mrbgems list [--file FILE] [--lockfile FILE]
rpremote mrbgems lock [--file FILE] [--lockfile FILE]
rpremote mrbgems update [--file FILE] [--lockfile FILE]
```

`check` validates the definition and local paths. `lock` creates or refreshes
`Mrbgems.lock` while reusing recorded GitHub commits. `update` intentionally
resolves branch dependencies again.

## Build

```sh
rpremote build [--language picoruby] [--language-version VERSION] \
  [--board pico2|pico2_w] [--firmware FILE] [--cache DIR] \
  [--mrbgems FILE|--no-mrbgems]
rpremote build clean
```

```sh
rpremote setup --language-version 4.0.3
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language-version 4.0.3 --board pico2 \
  --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

The project-root `Mrbgems` is auto-detected. `--firmware` names the completed
UF2. `build --output` is not supported. `build clean` removes only generated
`build/` intermediates.

## Flash

```sh
rpremote flash [--firmware FILE] [--language picoruby] \
  [--language-version VERSION] [--board pico2|pico2_w] [--cache DIR] \
  [--mount DIR] [--port PORT] [--timeout SEC]
```

```sh
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 \
  --mount /Volumes/RP2350
```

Hold BOOTSEL while connecting the Pico and select its RP2350 volume. A
positional UF2 argument is not supported. After copying the UF2, rpremote waits
for the R2P2 serial port to return.

## Run and inspect

```sh
rpremote ports
rpremote run FILE [--port PORT] [--baud RATE] [--timeout SEC]
rpremote exec CODE [--port PORT] [--baud RATE] [--timeout SEC]
rpremote reset [--port PORT] [--baud RATE] [--timeout SEC]
rpremote monitor [--port PORT] [--baud RATE] [--timeout SEC]
rpremote repl [--port PORT] [--baud RATE] [--timeout SEC]
```

`run` and `exec` use a temporary `/home/.rpremote-run-*.rb` and remove it after
execution. `monitor` and `repl` exit with `Ctrl-]`.

## Filesystem

Remote paths use a leading `:`. Exactly one `fs cp` path must be remote.

```sh
rpremote fs cp FILE :/home/FILE [--port PORT]
rpremote fs cp :/home/FILE FILE [--port PORT]
rpremote fs cat :/home/FILE [--port PORT]
rpremote fs ls :/home [--port PORT]
rpremote fs mkdir :/home/DIR [--port PORT]
rpremote fs rm :/home/FILE [--port PORT]
```

## PicoModem DFU

```sh
rpremote dfu app FILE [--type ruby|rite] [--port PORT] \
  [--baud RATE] [--timeout SEC]
rpremote dfu compile FILE [--output FILE] [--language picoruby] \
  [--language-version VERSION] [--cache DIR]
rpremote dfu status [--port PORT] [--baud RATE] [--timeout SEC]
```

```sh
rpremote dfu status
rpremote dfu app examples/dfu/app.rb
rpremote reset
rpremote dfu status
```

Use `dfu compile` to create bytecode matching the target PicoRuby version.
`dfu app` infers `RUBY` from `.rb` and `RITE` from `.mrb`.

## Common options

| Option | Purpose |
| --- | --- |
| `--config FILE` | Select a file other than `config/setting.json`. |
| `--language picoruby` | Select the implemented runtime backend. |
| `--language-version VERSION` | Select the PicoRuby/R2P2 source version. |
| `--board BOARD` | Select `pico2` or `pico2_w`; default: `pico2`. |
| `--cache DIR` | Store versioned sources and default UF2 output; default: `firmware`. |
| `--firmware FILE` | UF2 output for `build` or input for `flash`. |
| `--mount DIR` | Select the RP2350 BOOTSEL volume. |
| `--port PORT` | Select an R2P2 CDC 0 serial port. |
| `--baud RATE` | Serial speed; default: `115200`. |
| `--timeout SEC` | Timeout in seconds; default: `10`. |

## Validate the CLI

Run from `packages/rpremote` in the source repository.

```sh
bundle install
bundle exec rake
bundle exec rbs -I sig validate
bundle exec ruby exe/rpremote --help
```
