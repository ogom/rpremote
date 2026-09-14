# rpremote

[日本語](README.ja.md)

Command-line tools for preparing, building, flashing, and controlling custom PicoRuby R2P2 firmware on Raspberry Pi Pico boards.

rpremote embeds public and local mrbgems in reproducible firmware, flashes the generated UF2 through BOOTSEL, and provides binary-safe file transfer and Ruby execution through R2P2.

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

`setup` also downloads the official Raspberry Pi `nuke_universal.uf2` reset firmware into `firmware/`.

For a project that stores reusable Ruby code in `lib/NAME`, `deploy` flashes the existing firmware, copies that directory to R2P2, and then temporarily runs its entry file. Add `--build` to build the firmware first:

```sh
rpremote deploy path/to/project
rpremote deploy path/to/project --build
```

The defaults prepare `firmware/picoruby-4.0.3/` and create `firmware/picoruby-4.0.3-pico2.uf2`. Use `rpremote ports` to locate the R2P2 CDC 0 port when a board must be selected explicitly.

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

`Mrbgems.lock` pins GitHub commits and hashes local gem contents. Existing locks are reused by `build`; `rpremote mrbgems update` deliberately resolves new commits.

Set `auto_require: false` for a gem that should remain embedded in firmware without being loaded before every `run`, `exec`, or `deploy`. Require that gem explicitly from the application when needed.

## Select a target

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 --mount /Volumes/RP2350
```

Command-line options override `config/setting.json`. PicoRuby is implemented today; `language` and `board` are retained for planned MicroPython and additional Pico board support.

## Choose a workflow

- Prepare a project with `setup`, inspect resolved settings with `config show`, then use `build` and `flash` for the first firmware installation.
- Use `deploy PATH` during project development. It flashes the selected firmware, copies `PATH/lib/NAME` when present, and runs `PATH/main.rb`; add `--build` when the firmware must be rebuilt first.
- Use `run` or `exec` for temporary Ruby execution, and `monitor` or `repl` for an interactive serial session. `monitor` and `repl` exit with `Ctrl-]`.
- Use `fs` commands for persistent R2P2 files, and use `dfu` commands when an A/B boot application must survive a restart.

Run `rpremote --help` for the complete command list. Command help is the executable reference for current syntax, defaults, processing order, and effects.

```sh
rpremote deploy --help
rpremote dfu app --help
rpremote fs cp --help
```

### Safety boundaries

- `flash` replaces persistent R2P2 firmware. `bootsel --reset-flash-memory` erases all Pico 2 external flash and requires R2P2 to be flashed again.
- `dfu remove` permanently clears both DFU A/B application slots. Reset separately to stop an application already running in RAM.
- `fs rm` permanently deletes the selected remote path. Recursive uploads do not delete files that exist only on the board.
- `run` and `exec` remove their temporary remote file. Their nonzero Ruby-exception status requires compatible R2P2 firmware; UF2 files built from this repository include that support.

## Documentation and examples

- [Choose commands by workflow](https://github.com/ogom/rpremote/blob/main/docs/command.md)
- [Configure a project](https://github.com/ogom/rpremote/blob/main/docs/config.md)
- [Build custom firmware](https://github.com/ogom/rpremote/blob/main/docs/firmware.md)
- [Manage Mrbgems and Mrbgems.lock](https://github.com/ogom/rpremote/blob/main/docs/mrbgems.md)
- [Update a boot application with PicoModem DFU](https://github.com/ogom/rpremote/blob/main/docs/dfu.md)
- [Browse electronic-craft examples](https://github.com/ogom/rpremote/tree/main/examples)

## Related projects

- [mbremote](https://github.com/ogom/mbremote) is a tool with the same concept for building, flashing, and controlling MicroPython and PicoRuby projects on BBC micro:bit boards.

## Development

Install dependencies, then run the test and static checks:

```sh
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

To try the local gem without publishing it, install it into the current Ruby environment:

```sh
bundle exec rake install:local
rpremote --version
```

Before publishing, run `bundle exec rake release:check` and follow [RELEASING.md](RELEASING.md).

## License

[MIT](LICENSE). See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for externally downloaded software.
