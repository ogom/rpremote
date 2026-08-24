# 08 local mrbgem

Language: PicoRuby, Board: Raspberry Pi Pico 2, Custom mrbgem: local `picoruby-my_gems` from `examples/picoruby/mrbgems/my_gems`

[日本語](README.ja.md)

Loads the project-local `my_gems` mrbgem and uses `MyGems` to blink the Pico 2 onboard LED five times.

## Prerequisites

The project-root `Mrbgems` declares the local gem by a path relative to `Mrbgems`:

```ruby
gem path: "examples/picoruby/mrbgems/my_gems"
```

Validate and lock dependencies, then build and flash custom R2P2 firmware.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

`Mrbgems.lock` records a SHA-256 hash of the local gem contents. Run `rpremote mrbgems lock` again after changing the local gem.

## Wiring

No wiring is needed for Pico 2.

## Run

```sh
rpremote run examples/picoruby/education/08_my_gems/main.rb --timeout 15
```

The example succeeds when the onboard LED blinks five times and `my_gems: OK` is printed.
