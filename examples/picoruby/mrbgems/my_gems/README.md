# my_gems local mrbgem

Language: PicoRuby, Board: Raspberry Pi Pico 2, Custom mrbgem: this directory provides `picoruby-my_gems`

[日本語](README.ja.md)

This pure-Ruby local mrbgem wraps an output GPIO in `MyGems`. The project-root `Mrbgems` loads it with a path relative to that file:

```ruby
gem path: "examples/picoruby/mrbgems/my_gems"
```

The gem declares `my_gems` as its require name and depends on `picoruby-gpio`.

## Usage

```ruby
require "my_gems"
led = MyGems.new(pin: 25)
led.led_on
led.led_off
led.led_loop
```

See [08_my_gems](../../education/08_my_gems/README.md) for a finite hardware check.
See [09_my_gems_dfu](../../education/09_my_gems_dfu/README.md) for updating only the application after embedding the mrbgem.
