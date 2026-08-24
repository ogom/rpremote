# my_gems local mrbgem

Language: PicoRuby<br>
Board: Raspberry Pi Pico 2<br>
Custom mrbgem: this directory provides `picoruby-my_gems`

[日本語](README.ja.md)

This pure-Ruby local mrbgem wraps an output GPIO in `MyGems`. The project-root
`Mrbgems` loads it with a path relative to that file:

```ruby
gem path: "examples/mrbgems/my_gems"
```

The gem declares `my_gems` as its require name and depends on
`picoruby-gpio`.

## Usage

```ruby
require "my_gems"

led = MyGems.new(pin: 25)
led.led_on
led.led_off
led.led_loop
```

See [08_my_gems](../../education/08_my_gems/README.md) for a finite hardware
check that can be run with `rpremote`.
