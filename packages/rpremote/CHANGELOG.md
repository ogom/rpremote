# Changelog

All notable changes to this project will be documented in this file.

## 0.4.0 - 2026-08-31

- Add the Daisen Kofun PicoRuby project, with 32 WS2812 illumination patterns, a firmware-embedded local mrbgem, LED layout and setlist definitions, bilingual documentation, and host-side regression tests.
- Check R2P2 filesystem connectivity before non-recursive `fs cp` transfers, and report Shell synchronization timeouts as filesystem connection failures.

## 0.3.0 - 2026-08-28

- Add `bootsel` to ask supported R2P2 firmware to enter USB BOOTSEL mode without pressing the button.
- Add `bootsel --reset-flash-memory` to erase Raspberry Pi Pico external flash memory with the official universal erase UF2, whether BOOTSEL is already mounted or entered through R2P2.
- Have `setup` download Raspberry Pi's official `nuke_universal.uf2` into `firmware/`; `--force` refreshes the downloaded file.
- Change `deploy FILE` to `deploy PATH`: build and flash mrbgem-enabled firmware, recursively copy `PATH/lib/NAME` to `:/lib/NAME`, then temporarily run `PATH/main.rb`.
- Add `fs cp --recursive LOCAL_DIR :/REMOTE_DIR` and its `fs push` alias to create missing remote directories and upload a local directory tree in one command.
- Add `dfu remove` to permanently clear both DFU boot-application slots; a separate `reset` stops an application already running in RAM.
- Improve `run`: accept a project directory and run its `main.rb`, treat `--timeout` as an idle timeout while output continues, add `--reset-on-timeout`, and print upload, execution, cleanup, and error diagnostics to stderr.
- Reuse one temporary remote path for `run` and `exec`, so a failed cleanup cannot accumulate temporary files on the device.
- Read mrbgem `require_name` values from `Mrbgems.lock` and automatically prepend the corresponding `require` calls to `run`, `exec`, and `deploy`; allow `Mrbgems` entries to specify `require:` explicitly.
- Change `flash` to accept an explicit UF2 only through `--firmware FILE`; positional UF2 arguments are no longer supported.
- Improve RP2350 BOOTSEL flashing on macOS by accepting the expected `ENXIO` volume-detach race after a successful copy.
- Add PicoRuby mrbgem examples for BMI270, HC-SR04 temperature, MAX30102, MPU6050, and WS2812 SPI, plus oximeter and Processing project examples.

## 0.2.0 - 2026-08-26

- Make `run` and `exec` exit nonzero when compatible R2P2 firmware reports a Ruby exception, while preserving real-time program output.
- Increase the default command timeout from 10 to 20 seconds.
- Add a bilingual education example for practical PicoModem DFU application updates, startup confirmation, and A/B-slot rollback.

## 0.1.0 - 2026-08-24

- Add `setup`, `build`, and RP2350 BOOTSEL `flash` commands for custom PicoRuby R2P2 firmware on Raspberry Pi Pico 2 and Pico 2 W.
- Add target configuration for language, language version, board, cache, firmware path, serial port, and timeouts, with command-line precedence.
- Add `Mrbgems` and `Mrbgems.lock` support for reproducible public and local mrbgems, including automatic regeneration of PicoRuby build output when a custom mrbgem changes.
- Add PicoModem DFU staging, status, compatible bytecode compilation, and A/B-slot rollback support for Ruby and `.mrb` applications.
- Add binary-safe file transfer and remote filesystem commands, plus `run`, `exec`, `monitor`, `repl`, and reset with reconnect waiting.
- Add macOS R2P2 serial-port detection for Raspberry Pi Pico 2 and Pico 2 W.
- Add bilingual repository, package, configuration, firmware, mrbgem, DFU, and electronic-craft example documentation.
- Add RBS signatures, automated tests, macOS CI, and release validation with isolated gem installation and CLI smoke testing.

### Limitations

- rpremote currently supports PicoRuby only.
- Supported boards are Raspberry Pi Pico 2 and Pico 2 W; serial commands currently require macOS.
- `rpremote run` and `exec` are temporary R2P2 executions, not persistent deployments. Use `build` and `flash` to replace firmware.
- `rpremote deploy` requires PicoRuby 4.x firmware; use `build`, `flash`, `fs push`, and `run` separately with PicoRuby 3.4.x.
- PicoModem DFU updates only the boot application. Changes to PicoRuby, R2P2, or embedded mrbgems require rebuilding and flashing a UF2.
- DFU retains the complete application in RAM before writing flash. Verify available memory, bytecode compatibility, boot confirmation, and rollback on target hardware.
