# 07 PicoModem DFU

Language: PicoRuby, Board: Raspberry Pi Pico 2, Custom mrbgem: none

[日本語](README.ja.md)

This example updates an application on a deployed Pico 2 without pressing the BOOTSEL button. It deploys an onboard-LED "classroom beacon," updates stable v1 to v2, and then demonstrates automatic rollback from an application that fails its startup self-check.

PicoModem DFU updates the PicoRuby application. Changes to PicoRuby itself, R2P2, or embedded mrbgems still require rebuilding and flashing a UF2 with `rpremote build` and `rpremote flash`.

## Prerequisites

- The Pico 2 runs R2P2 firmware that includes PicoModem DFU.
- Only one Pico 2 is connected over USB.
- `rpremote ports` detects its R2P2 CDC 0 port.

A legacy `/home/app.rb` or `/home/app.mrb` takes priority over the DFU slots. Inspect `/home` first and remove any legacy application that exists.

```sh
rpremote fs ls :/home
rpremote fs rm :/home/app.rb
rpremote fs rm :/home/app.mrb
```

Run only the remove commands for files that exist. No wiring is required.

## DFU samples

`app_v1.rb` is a stable application that calls `DFU.confirm` after GPIO initialization succeeds. `app_broken.rb` simulates a failed startup self-check and checks rollback without calling `DFU.confirm`. See the [DFU guide](../../../docs/dfu.md) for the basic DFU workflow.

## 1. Deploy stable v1

Version 1 slowly blinks the onboard LED three times. Stage the application in the inactive DFU slot and restart R2P2.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v1.rb
rpremote reset
rpremote dfu status
```

Startup succeeds when the LED blinks three times and the status includes `confirmed rb` and `boot_count=0/3`. The application calls `DFU.confirm` only after GPIO initialization succeeds.

## 2. Update to v2

Version 2 adds a visible double-blink pattern repeated three times. It updates only the application, without pressing BOOTSEL or reflashing the UF2.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v2.rb
rpremote reset
rpremote dfu status
```

The update succeeds when the LED double-blinks and the destination slot becomes `confirmed rb`. Version 1 remains in the other A/B slot as the previously confirmed application.

## 3. Roll back after a failed startup

`app_broken.rb` simulates detecting that a required device failed its startup self-check. It leaves the output safe and exits without calling `DFU.confirm`. It can become the boot candidate but cannot replace the confirmed application, and the R2P2 Shell remains available for diagnosis.

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_broken.rb
rpremote reset
rpremote dfu status
```

While `boot_count` increases, repeat `rpremote reset` and `rpremote dfu status`. After the configured attempts are exhausted, the next boot returns `active_slot` and `try_slot` to the v2 slot. Rollback succeeds when the v2 double-blink pattern returns and the status shows `boot_count=0/3`.

If a real faulty application stops responding and prevents access to the R2P2 Shell, disconnect and reconnect USB power repeatedly. Rollback is evaluated before the candidate application is loaded, so the boot after the configured attempts are exhausted returns to the confirmed slot.

## Practical guidance

- Call `DFU.confirm` only after required GPIO, sensors, and configuration have initialized and passed their startup checks.
- Confirm when the application is safe to operate, not merely when execution has entered the main file.
- A failed DFU transfer preserves the currently confirmed slot.
- When distributing `.mrb`, compile it with the PicoRuby version installed on the device. See the [PicoModem DFU guide](../../../docs/dfu.md) for details.
