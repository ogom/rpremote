# 09 Local mrbgem with PicoModem DFU

[日本語](README.ja.md)

This example flashes R2P2 firmware containing a local mrbgem once, then uses PicoModem DFU to update only an application that calls that mrbgem.
Separating the mrbgem from the application keeps shared code in firmware while behavior and settings can be updated quickly without pressing BOOTSEL.

## How it works

- `MyGems` is embedded in the firmware and provides GPIO control for the onboard LED.
- `app_v1.rb` and `app_v2.rb` are stored in the DFU A/B slots and call the embedded `MyGems` class.
- Changing only the application does not require rebuilding firmware or reflashing the UF2.
- Changing `MyGems` itself requires locking the mrbgem, rebuilding firmware, and reflashing the UF2.

## 1. Embed the mrbgem

The project-root `Mrbgems` defines `examples/picoruby/mrbgems/my_gems` as a local mrbgem.
Skip this step if you already flashed the same firmware while completing `08_my_gems`.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

## 2. Deploy v1 through DFU

Stage v1 in the inactive DFU slot. This command does not start the application.

```sh
rpremote dfu app examples/picoruby/education/09_my_gems_dfu/app_v1.rb
```

Restart R2P2. `MyGems` initializes GPIO and slowly blinks the onboard LED three times.

```sh
rpremote reset
rpremote dfu status
```

The v1 boot succeeds when `rpremote dfu status` shows `confirmed rb` and `boot_count=0/3`.

## 3. Update only the application to v2

Keep `MyGems` unchanged and update to v2, which repeats a short double-blink pattern three times.
No mrbgem lock, firmware rebuild, or UF2 reflash is needed.

```sh
rpremote dfu app examples/picoruby/education/09_my_gems_dfu/app_v2.rb
```

Restart R2P2, then check the updated behavior and status.

```sh
rpremote reset
rpremote dfu status
```

The update succeeds when the LED double-blinks and the status shows `confirmed rb` and `boot_count=0/3`.

## Development cycle

- Changes to `app_v1.rb` or `app_v2.rb`: update with `rpremote dfu app` and `rpremote reset`.
- Changes to `examples/picoruby/mrbgems/my_gems`: update the firmware with `rpremote mrbgems lock`, `rpremote build`, and `rpremote flash`.

See [07 PicoModem DFU](../07_dfu/README.md) for A/B slots and rollback, and [08 local mrbgem](../08_my_gems/README.md) for the local mrbgem basics.
