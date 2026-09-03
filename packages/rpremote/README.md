# rpremote CLI reference

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

For a project that stores reusable Ruby code in `lib/NAME`, `deploy` builds and flashes the firmware, copies that directory to R2P2, and then runs its entry file:

```sh
rpremote deploy path/to/project
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

## Commands

| Command | Description |
| --- | --- |
| `rpremote setup` | Create configuration and prepare language sources. |
| `rpremote build` | Build a custom UF2 with project mrbgems. |
| `rpremote build clean` | Remove intermediate build files. |
| `rpremote bootsel` | Ask the running R2P2 firmware to enter BOOTSEL and wait for its USB volume. |
| `rpremote deploy PATH` | Build and flash firmware, copy `PATH/lib/NAME` to `:/lib/NAME` when present, then run `PATH/main.rb` while preserving its hardware output until the next command. |
| `rpremote dfu app FILE` | Stage a Ruby or version-checked bytecode app through PicoModem DFU. |
| `rpremote dfu compile FILE` | Compile `.rb` to matching PicoRuby bytecode for DFU. |
| `rpremote dfu status` | Show the active and candidate DFU slots. |
| `rpremote dfu remove` | Remove both DFU boot applications; reset separately to stop one already running. |
| `rpremote mrbgems …` | Check, list, lock, or update mrbgems. |
| `rpremote flash` | Flash the selected UF2 through BOOTSEL. |
| `rpremote bootsel --reset-flash-memory` | Enter BOOTSEL and erase all Pico 2 external flash memory. |
| `rpremote config show` | Show the effective configuration after file and command-line options are resolved. |
| `rpremote ports` | List detected R2P2 serial ports. |
| `rpremote run FILE` | Upload and run a Ruby file, or `main.rb` when FILE is a directory, with real-time output; exit nonzero on a Ruby exception. The timeout measures idle time without output. Use `--reset-on-timeout` to reset R2P2 after a run timeout. |
| `rpremote exec CODE` | Run short Ruby code and exit nonzero on a Ruby exception. |
| `rpremote monitor` / `repl` | Open an interactive serial session. |
| `rpremote reset` | Reboot R2P2 and wait for reconnection. |
| `rpremote fs cp/push/cat/ls/rm/mkdir` | Operate on the R2P2 filesystem. |

Run `rpremote --help` for the complete command list. Run `rpremote <command> --help` for command-specific syntax, defaults, and effects.

```sh
rpremote flash --help
rpremote dfu app --help
```

`monitor` and `repl` exit with `Ctrl-]`.

Ruby-exception exit statuses for `run` and `exec` require R2P2 firmware with Ruby exception status support.
UF2 files built with `rpremote build` from the [GitHub repository](https://github.com/ogom/rpremote) include that support.

## Operation model

- `run` and `exec` upload Ruby code temporarily, relay output, then remove the temporary remote file. A Ruby exception reported by compatible R2P2 firmware makes the command exit nonzero.
- `deploy PATH` builds the selected firmware, enters BOOTSEL, flashes it, waits until the R2P2 Shell is ready, copies `PATH/lib/NAME` to `:/lib/NAME` when present, then runs the current contents of `PATH/main.rb`. Its Shell job is retained so hardware output remains active until the next command. It reports successful completion and the output byte count; an R2P2 Ruby exception remains a command failure. If the library directory is absent, the copy step is skipped. It requires PicoRuby 4.x firmware.
- `flash` copies a UF2 to the RP2350 BOOTSEL volume and replaces persistent R2P2 firmware.
- `dfu app` stages a Ruby source or matching bytecode app in the inactive DFU slot. Restart R2P2 to try it; a successful app must call `DFU.confirm`.
- `dfu remove` permanently clears both DFU A/B application slots. The application already loaded in RAM continues until you run `rpremote reset`; use both commands before `rpremote run` when boot-app output would be unwanted. It does not remove other `/home` files or R2P2 firmware.
- Remote paths use `:/REMOTE/PATH`. `fs cp` transfers between one local and one remote path. `fs push LOCAL_DIR :/REMOTE_DIR` is an alias of `fs cp --recursive`; it creates missing remote directories and uploads the local directory contents. It does not delete remote files. `fs rm` permanently deletes the selected remote path.

## Documentation and examples

The [GitHub repository](https://github.com/ogom/rpremote) contains the full English and Japanese guides, configuration reference, Mrbgems.lock reference, custom firmware guide, and electronic-craft examples.

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
