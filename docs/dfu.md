# PicoModem DFU application updates

`rpremote dfu app` updates a boot application through PicoModem without putting R2P2 into BOOTSEL mode.

It does not replace the R2P2 UF2 itself. Continue to use `rpremote flash` and BOOTSEL flashing for a custom UF2 that changes PicoRuby, R2P2, or embedded mrbgems.

## What can be updated

DFU stores either of these in R2P2's file system as an A/B slot.

- `.rb`: PicoRuby source; DFU type `RUBY`.
- `.mrb`: mruby bytecode; DFU type `RITE`.

Received data is verified with CRC32 and saved to the inactive slot. A failed transfer keeps the active slot. If a newly updated application repeatedly fails to boot, R2P2 returns to the previously confirmed slot.

## Update an application

The file extension selects the type automatically.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v1.rb
rpremote dfu app app.mrb --timeout 30
```

Specify the type for a file without an extension.

```sh
rpremote dfu app dist/application --type rite
```

After transfer, the new application becomes the boot candidate on the next R2P2 restart. Restart with `rpremote reset` or by cycling power.

## Confirm a boot

After verifying successful startup, a new application calls `DFU.confirm`.

```ruby
require "dfu"
# Initialization and self-checks.
DFU.confirm
# Application body.
```

Without `DFU.confirm`, R2P2 treats the boot as failed and automatically rolls back to the previously confirmed application after the configured number of attempts. Do not call it before an initialization and self-check that might fail or enter an infinite loop.

## Check status

`rpremote dfu status` shows a short A/B slot status.

```sh
rpremote dfu status
# active_slot=a
# try_slot=a
# boot_count=0/3
# slot_a=confirmed mrb
# slot_b=confirmed mrb
```

## Check rollback

`examples/picoruby/education/07_dfu/app_broken.rb` simulates a failed startup self-check and intentionally does not call `DFU.confirm`. Stage it, restart, and check the status as follows.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_broken.rb
rpremote reset
rpremote dfu status
```

Repeat the last two commands. `boot_count` increases while the test slot is retried. After the retry limit, `active_slot` returns to the preceding `confirmed` slot and `boot_count` returns to `0`. `rpremote reset` does not relay application serial output; start `rpremote monitor` in another terminal first to see output.

## Check recovery after power loss

First use `rpremote dfu status` to confirm that at least one slot is `confirmed`. In this example, disconnect USB power after staging `app_v1.rb`, **without running `rpremote reset`**. Once `slot_b=ready` and `try_slot=b` are shown, the boot candidate remains until an explicit restart, so it need not be immediately after the `staged ...` message.

```sh
rpremote dfu status
rpremote dfu app examples/picoruby/education/07_dfu/app_v1.rb
# After "staged ...", disconnect USB power here without running
rpremote reset.
```

Reconnect USB power, allow R2P2 to start, then check the status.

```sh
rpremote dfu status
```

If the application calls `DFU.confirm`, its candidate slot becomes `confirmed`, `active_slot` matches `try_slot`, and `boot_count=0/3`. If it cannot boot, R2P2 returns to the earlier confirmed slot after three attempts. This pre-release check does not cover disconnecting power during transfer or flash writes because hardware timing cannot be controlled precisely.

## Transfer an `.mrb`

You can transfer mruby bytecode produced by a PicoRuby compiler. **Use a compiler matching the PicoRuby version on the device.** PicoRuby 3.4 uses `RITE0300`, while PicoRuby 4 uses `RITE0400`; the formats are incompatible.

```sh
# PicoRuby 3.4.5 (picorbc)
firmware/picoruby-3.4.5/build/host/bin/picorbc -o app.mrb app.rb
# PicoRuby 4.0.3 (mrbc)
firmware/picoruby-4.0.3/build/host/bin/mrbc -o app.mrb app.rb
rpremote dfu app app.mrb
rpremote reset
```

For a `.mrb` file, the type is automatically `RITE`. rpremote reads `PICORUBY_VERSION` from the connected R2P2 and compares it with the leading `RITE0300` or `RITE0400` bytecode header. A mismatched `.mrb` is rejected before transfer. Use `--type rite` only for a file without an extension.

## Compile an `.mrb`

`rpremote dfu compile` automatically selects the host compiler from the chosen PicoRuby source and creates an `.mrb`. First run `rpremote setup` for the same version and make a build containing the compiler.

```sh
# Create RITE0300 for PicoRuby 3.4.5 R2P2.
rpremote dfu compile examples/picoruby/education/07_dfu/app_v1.rb --language-version 3.4.5 --output build/dfu/app.mrb
rpremote dfu app build/dfu/app.mrb
# PicoRuby 4.0.3 creates RITE0400.
rpremote dfu compile examples/picoruby/education/07_dfu/app_v1.rb --language-version 4.0.3
```

Without `--output`, the `.mrb` is created beside its input file. Use `--cache` to select the directory containing PicoRuby sources.

## Limitations

- An existing `/home/app.rb` or `/home/app.mrb` takes precedence over a DFU slot. Remove an unneeded legacy application before booting a DFU application.
- R2P2 retains a whole DFU application in RAM before saving it to flash. Check the available memory and target PicoRuby version with real hardware.
- Verify A/B updates, boot confirmation, and rollback on real hardware with both 3.4.2 and 4.0.3 before release.
