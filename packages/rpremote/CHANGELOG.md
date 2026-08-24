# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## [0.1.0] - 2026-08-24

- Add `setup`, `build`, and RP2350 BOOTSEL `flash` commands for custom
  PicoRuby R2P2 firmware on Raspberry Pi Pico 2 and Pico 2 W.
- Add target configuration for language, language version, board, cache,
  firmware path, serial port, and timeouts, with command-line precedence.
- Add `Mrbgems` and `Mrbgems.lock` support for reproducible public and local
  mrbgems, including automatic regeneration of PicoRuby build output when a
  custom mrbgem changes.
- Add PicoModem DFU staging, status, compatible bytecode compilation, and
  A/B-slot rollback support for Ruby and `.mrb` applications.
- Add binary-safe file transfer and remote filesystem commands, plus `run`,
  `exec`, `monitor`, `repl`, and reset with reconnect waiting.
- Add macOS R2P2 serial-port detection for Raspberry Pi Pico 2 and Pico 2 W.
- Add bilingual repository, package, configuration, firmware, mrbgem, DFU,
  and electronic-craft example documentation.
- Add RBS signatures, automated tests, macOS CI, and release validation with
  isolated gem installation and CLI smoke testing.
