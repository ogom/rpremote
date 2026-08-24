# PicoModem DFU application

Language: PicoRuby<br>
Board: Raspberry Pi Pico boards running R2P2 with PicoModem DFU<br>
Custom mrbgem: none

[日本語](README.ja.md)

This minimal application confirms a successful DFU boot. Run commands from the
repository root.

```sh
rpremote dfu app examples/dfu/app.rb
rpremote reset
```

The next boot runs the application and confirms its slot. To see its output,
open `rpremote monitor` before resetting; `rpremote reset` itself does not
relay serial output.

`DFU.confirm` is deliberately placed after initialization. Move it after the
real application's own startup checks when using this pattern in a project.

When compiling to `.mrb`, use the compiler from the same PicoRuby version as
the installed R2P2 firmware. PicoRuby 3.4.x emits `RITE0300` with `picorbc`;
PicoRuby 4.x emits `RITE0400` with `mrbc`. The formats are not compatible.

## Rollback test

`unconfirmed.rb` deliberately does not call `DFU.confirm`. It is safe to use
for checking automatic rollback: after the configured number of boots, R2P2
returns to the previously confirmed application.

```sh
rpremote dfu app examples/dfu/unconfirmed.rb
rpremote reset
rpremote exec 'require "dfu"; p DFU.status'
```

Repeat the last two commands until `active_slot` returns to the earlier
confirmed slot. `boot_count` increases while the test slot is retried and is
reset to `0` after rollback.
