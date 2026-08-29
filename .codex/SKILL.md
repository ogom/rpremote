---
name: rp-remote-dev
description: Develop, test, build, flash, and troubleshoot Raspberry Pi Pico PicoRuby R2P2 projects with rpremote. Use for rpremote CLI, local mrbgems, PicoModem DFU, and rpremote project configuration, not generic Ruby or Raspberry Pi development.
---

# Raspberry Pi Pico development with rpremote

Use the RubyGem or repository-workspace version of `rpremote` to develop PicoRuby R2P2 projects and operate Raspberry Pi Pico boards over USB serial.

## Route the task

- If `packages/rpremote/` exists, treat the directory as the rpremote source repository; otherwise treat it as a PicoRuby project using the published gem.
- Read [references/command.md](references/command.md) for CLI syntax and command semantics.
- Read [references/config.md](references/config.md) when `config/setting.json`, defaults, or overrides affect the task.
- Read [references/examples/picoruby/mrbgems.md](references/examples/picoruby/mrbgems.md) when creating or updating a local PicoRuby mrbgem.
- Read [references/examples/picoruby/projects.md](references/examples/picoruby/projects.md) when creating or updating a PicoRuby example project.
- Read [references/examples.md](references/examples.md) for device verification, BOOTSEL recovery, filesystem deployment, DFU, or troubleshooting.
- Read [references/document.md](references/document.md) when creating or revising user-facing documentation.

## Establish the project

- Work from the project root for `setup`, `build`, `flash`, `deploy`, and runtime commands. Inspect the configuration, dependency files, and target code relevant to the request before changing them.
- Use `rpremote --help` when the installed CLI may differ from the reference.
- PicoRuby is the implemented runtime backend. Do not imply that selecting `micropython` works merely because `language` is present in the interface.
- Keep `Mrbgems` and `Mrbgems.lock` together. Reuse locked dependencies for ordinary builds and use `mrbgems update` only for an intentional dependency update.
- Treat a successful firmware build as compile and link evidence, not proof that every Ruby method exists at runtime or that hardware timing is accurate.

## Hardware safety

- Build only unless the user requests a hardware action. `bootsel`, `flash`, `deploy`, `run`, `exec`, `reset`, `fs`, `repl`, `monitor`, and `dfu app` communicate with or change a connected board.
- Before flashing, resolve the exact UF2, board type, and intended RP2350 BOOTSEL volume. Use `--mount` when auto-detection is ambiguous. Do not flash an RP2040 volume with an RP2350 image.
- R2P2 exposes multiple serial interfaces. rpremote uses CDC 0; use `--port` when several boards are connected. Close serial monitors or other processes before retrying a busy port.
- `bootsel --reset-flash-memory` erases stored data and firmware; `dfu remove` clears both persistent application slots. Perform either only when the user requests the destructive outcome. Reinstall R2P2 after erasing flash.
- `run` is temporary. Use filesystem deployment or PicoModem DFU only when persistence is part of the requested workflow.

## Verification and failures

- Match verification to the changed layer: run the CLI suite for CLI changes, local mrbgem checks and a firmware build for dependency changes, and hardware commands only when hardware validation is requested.
- In the CLI source repository, run `bundle exec rake` from `packages/rpremote` and `bundle exec rbs -I sig validate` after CLI signature changes. Use `release:check` only for a requested pre-release check.
- For device failures, start with `rpremote ports`, then retry with an explicit CDC 0 `--port`. Check that no other process owns the port.
- Inspect `run` and `exec` output for Ruby exceptions; do not use the process exit code alone as proof that the device program succeeded.
