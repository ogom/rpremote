# rpremote

[日本語](README.ja.md)

Command-line tools for preparing, building, flashing, and controlling custom
PicoRuby R2P2 firmware on Raspberry Pi Pico boards.

The main goal of rpremote is to make public mrbgems such as
[`picoruby-ws2812-plus`](https://github.com/ksbmyk/picoruby-ws2812-plus) and
project-local mrbgems easy to embed in reproducible Raspberry Pi Pico firmware.
The repository contains the `rpremote` RubyGem under `packages/rpremote` and
hardware examples under `examples`.

## Requirements

- macOS
- Ruby 4.0 or later
- Git, GNU Make, CMake, and the Arm GNU Toolchain
- A Raspberry Pi Pico board supported by the selected R2P2 build configuration
- A PicoRuby version providing the R2P2 build configuration

rpremote uses macOS `stty` and Ruby's standard IO API, so it does not require a
third-party serial-port gem. The R2P2 CDC 0 port must not be open in another
terminal while a command is running.

## Installation

Install the published gem:

```sh
gem install rpremote
```

To use the examples, clone this repository and run commands from its root.

## Quick start

Download and prepare the default PicoRuby source:

```sh
rpremote setup
```

Build the custom UF2. A project-level `Mrbgems` file is detected automatically:

```sh
rpremote build
```

The defaults prepare `firmware/picoruby-4.0.3/`, keep intermediate output under
`build/`, and create `firmware/picoruby-4.0.3-pico2.uf2`.

Hold BOOTSEL while connecting the Pico 2, then flash and run a Ruby program:

```sh
rpremote flash --mount /Volumes/RP2350
rpremote run examples/education/01_blink/main.rb
```

Use `rpremote ports` to find the R2P2 serial ports. When more than one board is
connected, select CDC 0 with `--port`.

## Add mrbgems

Define public or local build-time gems in `Mrbgems`. Local paths are resolved
relative to this file.

```ruby
vm :mrubyc

gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

Validate and lock dependencies before building:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

`Mrbgems.lock` pins GitHub commits and hashes local gem contents. Existing locks
are reused by `build`; run `rpremote mrbgems update` only when dependencies
should advance.

## Select a target

Language, language version, board, cache, and firmware path can be selected
explicitly. Command-line options override `config/setting.json`.

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 \
  --mount /Volumes/RP2350
```

PicoRuby is implemented today. `language` and `board` keep the command-line
interface ready for future MicroPython and additional Pico board support.

## Commands

| Command | Description |
| --- | --- |
| `rpremote setup` | Create project configuration and prepare language sources. |
| `rpremote build` | Build a custom UF2, including project mrbgems. |
| `rpremote build clean` | Remove generated intermediate build files. |
| `rpremote dfu app FILE` | Stage a Ruby or version-checked bytecode application through PicoModem DFU. |
| `rpremote dfu compile FILE` | Compile `.rb` to matching PicoRuby bytecode for DFU. |
| `rpremote dfu status` | Show the active and candidate DFU slots. |
| `rpremote mrbgems …` | Check, list, lock, or update mrbgem dependencies. |
| `rpremote flash` | Flash a built UF2 through an RP2350 BOOTSEL volume. |
| `rpremote ports` | List detected R2P2 serial ports. |
| `rpremote run FILE` | Upload and run a Ruby file, then remove it. |
| `rpremote exec CODE` | Run a short Ruby expression. |
| `rpremote monitor` | Open a serial monitor. |
| `rpremote repl` | Open PicoIRB. |
| `rpremote reset` | Reboot R2P2 and wait for reconnection. |
| `rpremote fs …` | Copy, print, list, remove, or create remote files. |

Run `rpremote --help` for the complete command syntax. Interactive commands
exit with `Ctrl-]`.

## Documentation

- [Configuration and options](docs/config.md) / [日本語](docs/config.ja.md)
- [Custom firmware for the WS2812 example](docs/firmware.md) / [日本語](docs/firmware.ja.md)
- [Mrbgems and Mrbgems.lock](docs/mrbgems.md) / [日本語](docs/mrbgems.ja.md)
- [PicoModem DFU application updates](docs/dfu.md) / [日本語](docs/dfu.ja.md)
- [Examples](examples/README.md)
- [RubyGem package guide](packages/rpremote/README.md)

## Related projects

- [mbremote](https://github.com/ogom/mbremote) is a tool with the same concept
  for building, flashing, and controlling MicroPython and PicoRuby projects on
  BBC micro:bit boards.

## Development

Install dependencies and run the checks from the package directory:

```sh
cd packages/rpremote
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

Before publishing, run `bundle exec rake release:check` and follow the
[release checklist](packages/rpremote/RELEASING.md). The check does not publish
the gem or push a Git tag.

## License

[MIT](LICENSE). See [Third-Party Notices](packages/rpremote/THIRD_PARTY_NOTICES.md)
for externally downloaded software.
