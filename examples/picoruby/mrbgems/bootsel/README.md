# picoruby-bootsel

[Japanese](README.ja.md)

`picoruby-bootsel` adds `Machine.enter_bootsel` to PicoRuby firmware for RP2040 and RP2350 boards. Calling it immediately restarts the board into ROM USB BOOTSEL mode.

## Include in firmware

Add this mrbgem to the PicoRuby build configuration used for your firmware:

```ruby
vm :mrubyc
gem path: "path/to/picoruby-bootsel"
```

The gem must be compiled into the firmware. Loading `bootsel.rb` from the board's filesystem is not sufficient because the implementation calls the Pico SDK boot ROM from native code.

## Usage

```ruby
require "bootsel"

Machine.enter_bootsel
```

The call does not return. The serial connection disappears and the board re-enumerates as an `RPI-RP2` or `RP2350` USB BOOTSEL volume.

## API

| Method | Description |
| --- | --- |
| `Machine.enter_bootsel` | Reboot an RP2040 or RP2350 board into USB BOOTSEL mode. It accepts no arguments and does not return. |

## Safety and limitations

- Finish filesystem writes and other persistent operations before calling `Machine.enter_bootsel`; the method resets the board immediately.
- BOOTSEL mode exposes firmware replacement interfaces to the connected host. Call the method only from an appropriately trusted application.
- The implementation targets RP2040 and RP2350 firmware. POSIX builds raise `NotImplementedError`.

## License

MIT License. See [LICENSE](LICENSE).
