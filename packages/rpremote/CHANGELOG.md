# Changelog

All notable changes to this project will be documented in this file.

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
- PicoModem DFU updates only the boot application. Changes to PicoRuby, R2P2, or embedded mrbgems require rebuilding and flashing a UF2.
- DFU retains the complete application in RAM before writing flash. Verify available memory, bytecode compatibility, boot confirmation, and rollback on target hardware.
