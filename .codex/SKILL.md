---
name: rp-remote-dev
description: Develop, build, flash, and troubleshoot Raspberry Pi Pico PicoRuby R2P2 projects with rpremote. Use for rpremote CLI, Mrbgems, PicoModem DFU, and project configuration work, not generic Ruby or Raspberry Pi development.
---

# Raspberry Pi Pico development with rpremote

Use the RubyGem or repository-workspace version of `rpremote` to build custom PicoRuby R2P2 firmware, flash Raspberry Pi Pico boards, and operate R2P2 over USB serial.

## Establish the project

- If `packages/rpremote/` exists, treat the directory as the rpremote source repository; otherwise treat it as a PicoRuby project using the published gem.
- Work from the project root for `setup`, `build`, `flash`, and runtime commands. Inspect `README.md`, `config/setting.json`, `Mrbgems`, `Mrbgems.lock`, and the target Ruby files before changing code or running a device command.
- Use `rpremote --help` when the installed CLI may differ from this skill.
- Read [references/command.md](references/command.md) for command syntax and [references/config.md](references/config.md) when configuration affects the task. Read [references/examples.md](references/examples.md) for Mrbgems layouts, device verification, DFU, or troubleshooting.

## Build custom firmware

- PicoRuby is the implemented runtime backend. Do not imply that selecting `micropython` works merely because `language` is present in the interface.
- `rpremote setup` prepares versioned PicoRuby source below `cache`. `rpremote build` requires that prepared source and selects the build configuration from the PicoRuby version, VM, and board.
- Use project-root `Mrbgems` for public and local build-time mrbgems. Local paths are relative to `Mrbgems` and must contain `mrbgem.rake`.
- Keep `Mrbgems.lock` with `Mrbgems`. Reuse the lock during ordinary builds; run `rpremote mrbgems update` only when intentionally advancing dependencies.
- `--firmware` is both the `build` destination and `flash` input. `build --output` and a positional UF2 argument to `flash` are not supported.
- `rpremote build clean` removes generated `build/` intermediates only. It does not remove `firmware/`, PicoRuby source caches, `Mrbgems`, or `Mrbgems.lock`.

## Hardware safety

- Build only unless the user requests a hardware action. `flash`, `run`, `exec`, `reset`, `fs`, `repl`, `monitor`, and `dfu app` communicate with or change a connected board.
- Before flashing, resolve the exact UF2 and intended RP2350 BOOTSEL volume. Use `--mount` when auto-detection is ambiguous. Do not flash an RP2040 volume with an RP2350 image.
- R2P2 exposes multiple serial interfaces. rpremote uses CDC 0; use `--port` when several boards are connected. Close serial monitors or other processes before retrying a busy port.
- `run` uploads a temporary Ruby file, executes it, and removes it; it is not a persistent deployment. Use `fs cp` or PicoModem DFU only when persistence is part of the requested workflow.
- `monitor` and `repl` are interactive and exit with `Ctrl-]`.

## PicoModem DFU

- `dfu app` updates an application in R2P2's A/B slots without BOOTSEL. It does not update PicoRuby, R2P2 itself, or embedded mrbgems; use a custom UF2 and `flash` for those changes.
- A candidate application should call `DFU.confirm` only after initialization and self-checks succeed. Check `rpremote dfu status` before rollback or power-loss tests and preserve at least one confirmed slot.
- A `.mrb` must match the connected PicoRuby RITE format. Prefer `rpremote dfu compile` with the installed PicoRuby version; rpremote rejects a mismatched `RITE0300` or `RITE0400` before transfer.

## Verification and failures

- In the CLI source repository, run `bundle exec rake` from `packages/rpremote`. Also run `bundle exec rbs -I sig validate` after type signature changes. Use `bundle exec rake release:check` only for a requested pre-release check; it does not publish.
- For device failures, start with `rpremote ports`, then retry with an explicit CDC 0 `--port`. Check that no other process owns the port.
- If R2P2 Shell synchronization times out, confirm that the intended custom firmware is installed, reset the board, and retry before increasing timeout.
- Inspect `run` and `exec` output for Ruby exceptions; do not use the process exit code alone as proof that the device program succeeded.
