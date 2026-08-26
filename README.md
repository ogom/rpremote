# rpremote

[日本語](README.ja.md)

Command-line tools for preparing, building, flashing, and controlling custom PicoRuby R2P2 firmware on Raspberry Pi Pico boards.

The main goal of rpremote is to make public mrbgems such as [`picoruby-ws2812-plus`](https://github.com/ksbmyk/picoruby-ws2812-plus) and project-local mrbgems easy to embed in reproducible Raspberry Pi Pico firmware. The repository contains the `rpremote` RubyGem under `packages/rpremote` and hardware examples under `examples`.

## Requirements

- macOS and Ruby 4.0 or later
- Git, GNU Make, CMake, and the Arm GNU Toolchain
- A Raspberry Pi Pico board supported by the selected R2P2 build configuration
- A PicoRuby version providing the R2P2 build configuration

rpremote uses macOS `stty` and Ruby's standard IO API, so it does not require a third-party serial-port gem. The R2P2 CDC 0 port must not be open in another terminal while a command is running. To use the examples, clone this repository and run commands from its root.

## Quick start

Install the published gem, clone this repository, and download and prepare the default PicoRuby source and official Raspberry Pi `nuke_universal.uf2` reset firmware:

```sh
gem install rpremote
git clone https://github.com/ogom/rpremote.git
cd rpremote
rpremote setup
```

Build the custom UF2. A project-level `Mrbgems` file is detected automatically:

```sh
rpremote build
```

The defaults prepare `firmware/picoruby-4.0.3/`, keep intermediate output under `build/`, and create `firmware/picoruby-4.0.3-pico2.uf2`.

Hold BOOTSEL while connecting the Pico 2, then flash and run a Ruby program:

```sh
rpremote flash --mount /Volumes/RP2350
rpremote run examples/picoruby/education/01_blink/main.rb
```

For a project that keeps reusable Ruby code in `lib/NAME`, `deploy` builds and flashes the firmware, copies that directory to R2P2's `/lib/NAME`, and runs its `main.rb`. If the directory is absent, the copy step is skipped:

```sh
rpremote deploy examples/picoruby/projects/oximeter --timeout 70
```

Use `rpremote ports` to find the R2P2 serial ports. When more than one board is connected, select CDC 0 with `--port`.

## Run code and use the console

`rpremote run` and `rpremote exec` are temporary execution commands: they upload Ruby code, relay its output, and remove the temporary remote file. They exit nonzero when compatible R2P2 firmware reports a Ruby exception.

```sh
rpremote run examples/picoruby/education/01_blink/main.rb
rpremote exec 'puts 1 + 2'
rpremote monitor
rpremote repl
rpremote reset
```

`monitor` and `repl` exit with `Ctrl-]`. `reset` reboots R2P2 and waits for it to reconnect.

## Work with remote files

Prefix an R2P2 path with `:`. `fs cp` accepts exactly one remote path. Use `fs push LOCAL_DIR :/REMOTE_DIR`, an alias of `fs cp --recursive`, to create missing remote directories and upload a local directory tree; remote-only files are not deleted. `fs rm` permanently deletes the selected remote path.

```sh
rpremote fs ls :/
rpremote fs cp local.txt :/local.txt
rpremote fs push local/lib :/lib
rpremote fs cat :/local.txt
rpremote fs rm :/local.txt
```

## Inspect effective configuration

Check the settings that will apply before building or flashing. The command resolves file settings, command-line overrides, and defaults without connecting to a board.

```sh
rpremote config show --board pico2_w
```

## Update a DFU application

`flash` replaces persistent R2P2 firmware. `dfu app` instead stages a Ruby source or matching bytecode app in the inactive DFU slot; the next restart tries that app and it must call `DFU.confirm` after a successful boot.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/main.rb
rpremote reset
```

Remove both persistent DFU application slots and stop the running boot application before using `run` alone:

```sh
rpremote dfu remove
rpremote reset
```

## Add mrbgems

Define public or local build-time gems in `Mrbgems`. Local paths are resolved relative to this file.

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

`Mrbgems.lock` pins GitHub commits and hashes local gem contents. Existing locks are reused by `build`; run `rpremote mrbgems update` only when dependencies should advance.

## Select a target

Language, language version, board, cache, and firmware path can be selected explicitly. Command-line options override `config/setting.json`.

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 --mount /Volumes/RP2350
```

PicoRuby is implemented today. `language` and `board` keep the command-line interface ready for future MicroPython and additional Pico board support.

See the [command reference](docs/command.md) for the complete command list, grouped filesystem commands, and their effects.

## Examples

- [01 blink](examples/picoruby/education/01_blink/README.md): verify the Pico 2 onboard LED and serial output.
- [04 WS2812](examples/picoruby/education/04_ws2812/README.md): build custom firmware and control a WS2812B with a button.
- [07 PicoModem DFU](examples/picoruby/education/07_dfu/README.md): update a deployed application and verify A/B-slot rollback.
- [10 Wi-Fi](examples/picoruby/education/10_wifi/README.md): connect Pico 2 W to a WPA2-PSK access point.
- [All examples](examples/README.md)

## Documentation

- [Configuration and options](docs/config.md) / [日本語](docs/config.ja.md)
- [Command reference](docs/command.md) / [日本語](docs/command.ja.md)
- [Custom firmware for the WS2812 example](docs/firmware.md) / [日本語](docs/firmware.ja.md)
- [Mrbgems and Mrbgems.lock](docs/mrbgems.md) / [日本語](docs/mrbgems.ja.md)
- [PicoModem DFU application updates](docs/dfu.md) / [日本語](docs/dfu.ja.md)
- [CLI reference and RubyGem package guide](packages/rpremote/README.md)

## Development

Install dependencies and run the checks from the package directory:

```sh
cd packages/rpremote
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

Before publishing, run `bundle exec rake release:check` and follow the [release checklist](packages/rpremote/RELEASING.md). The check does not publish the gem or push a Git tag.

## Related projects

- [mbremote](https://github.com/ogom/mbremote) is a tool with the same concept for building, flashing, and controlling MicroPython and PicoRuby projects on BBC micro:bit boards.

## License

[MIT](LICENSE). See [Third-Party Notices](packages/rpremote/THIRD_PARTY_NOTICES.md) for externally downloaded software.
