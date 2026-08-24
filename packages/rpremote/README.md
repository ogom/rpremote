# rpremote

[日本語](README.ja.md)

Command-line tools for preparing, building, flashing, and controlling custom
PicoRuby R2P2 firmware on Raspberry Pi Pico boards.

rpremote embeds public and local mrbgems in reproducible firmware, flashes the
generated UF2 through BOOTSEL, and provides binary-safe file transfer and Ruby
execution through R2P2.

## Requirements

- macOS and Ruby 4.0 or later
- Git, GNU Make, CMake, and the Arm GNU Toolchain for firmware builds
- A Raspberry Pi Pico board supported by the selected R2P2 build configuration
- A PicoRuby version providing the R2P2 build configuration

## Installation

```sh
gem install rpremote
```

## Quick start

Run these commands in a project directory:

```sh
rpremote setup
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run main.rb
```

The defaults prepare `firmware/picoruby-4.0.3/` and create
`firmware/picoruby-4.0.3-pico2.uf2`. Use `rpremote ports` to locate the R2P2
CDC 0 port when a board must be selected explicitly.

## Add mrbgems

Create a project-level `Mrbgems` file. Local paths are relative to that file.

```ruby
vm :mrubyc

gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

Then validate, lock, and build the dependencies:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

`Mrbgems.lock` pins GitHub commits and hashes local gem contents. Existing
locks are reused by `build`; `rpremote mrbgems update` deliberately resolves
new commits.

## Select a target

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 \
  --mount /Volumes/RP2350
```

Command-line options override `config/setting.json`. PicoRuby is implemented
today; `language` and `board` are retained for planned MicroPython and
additional Pico board support.

## Commands

| Command | Description |
| --- | --- |
| `rpremote setup` | Create configuration and prepare language sources. |
| `rpremote build` | Build a custom UF2 with project mrbgems. |
| `rpremote build clean` | Remove intermediate build files. |
| `rpremote dfu app FILE` | Stage a Ruby or version-checked bytecode app through PicoModem DFU. |
| `rpremote dfu compile FILE` | Compile `.rb` to matching PicoRuby bytecode for DFU. |
| `rpremote dfu status` | Show the active and candidate DFU slots. |
| `rpremote mrbgems …` | Check, list, lock, or update mrbgems. |
| `rpremote flash` | Flash the selected UF2 through BOOTSEL. |
| `rpremote ports` | List detected R2P2 serial ports. |
| `rpremote run FILE` | Upload and run a Ruby file. |
| `rpremote exec CODE` | Run a short Ruby expression. |
| `rpremote monitor` / `repl` | Open an interactive serial session. |
| `rpremote reset` | Reboot R2P2 and wait for reconnection. |
| `rpremote fs cp/cat/ls/rm/mkdir` | Operate on the R2P2 filesystem. |

Run `rpremote --help` for complete syntax. `monitor` and `repl` exit with
`Ctrl-]`.

## Documentation and examples

The [GitHub repository](https://github.com/ogom/rpremote) contains the full
English and Japanese guides, configuration reference, Mrbgems.lock reference,
custom firmware guide, and electronic-craft examples.

## Related projects

- [mbremote](https://github.com/ogom/mbremote) is a tool with the same concept
  for building, flashing, and controlling MicroPython and PicoRuby projects on
  BBC micro:bit boards.

## Development

```sh
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

Before publishing, run `bundle exec rake release:check` and follow
[RELEASING.md](RELEASING.md).

## License

[MIT](LICENSE). See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for
externally downloaded software.
