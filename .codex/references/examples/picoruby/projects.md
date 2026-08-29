# Creating a PicoRuby example project

## Scope

This reference applies to applications created under `examples/picoruby/projects/<name>/`. Create a project for a runnable hardware example or application that combines devices, presentation, logging, and project-specific behavior. Put reusable hardware or protocol APIs in an mrbgem instead.

Before implementation, inspect the closest project in the same directory. Use `oximeter` as the reference for a PicoRuby application with local libraries, hardware initialization, status output, cleanup, and paired documentation. Follow [../../document.md](../../document.md) for user-facing documentation.

## Choose the project boundary

- Keep hardware composition, pin selection, application flow, logging, and project-specific configuration in the project.
- Reuse existing PicoRuby APIs and mrbgems. Create or extend an mrbgem when a driver or protocol API should be reusable outside the project.
- Keep `main.rb` focused on dependency loading, hardware initialization, the main loop, error handling, and cleanup.
- Move configuration and substantial application behavior into classes or modules under `lib/<name>/`.
- Use a project module with a name derived from the directory, such as `Oximeter` for `oximeter`.
- Match class and module names to snake_case filenames so device-side require paths remain predictable.

## File structure

Create the project with at least:

```text
<name>/
  README.md
  README.ja.md
  main.rb
```

Add project libraries when the application no longer fits clearly in `main.rb`:

```text
<name>/
  lib/
    <name>/
      config.rb
      <feature>.rb
```

The `oximeter` project demonstrates this division:

| File | Responsibility |
| --- | --- |
| `main.rb` | Loads dependencies, initializes hardware, runs the application, and guarantees shutdown and output cleanup. |
| `lib/oximeter/config.rb` | Defines pin assignments, sampling values, thresholds, display settings, and execution duration. |
| `lib/oximeter/monitor.rb` | Owns the measurement state and application behavior. |
| `lib/oximeter/rolling_statistics.rb` | Provides a small project-specific calculation helper. |
| `lib/oximeter/status_leds.rb` | Converts application state into the physical status display. |

Use only the files the new project needs. Do not copy oximeter-specific classes or split a small application into unnecessary files.

## Dependencies and runtime compatibility

Add required build-time mrbgems to the project-root `Mrbgems`. Keep local drivers under `examples/picoruby/mrbgems/` and follow [mrbgems.md](mrbgems.md) when creating or changing one.

Confirm that APIs used by `main.rb` and `lib/` exist for the VM selected in `Mrbgems`. A successful firmware build compiles embedded mrbgems but does not execute the project's uploaded Ruby files. Inspect the prepared PicoRuby source or compile the project files with a version-matched compiler when runtime compatibility is uncertain.

## Application behavior

- Require embedded mrbgems by their stable require names.
- When local project libraries are installed under `/lib/<name>`, require them with the matching device path, such as `require "/lib/oximeter/config"`.
- Report startup, state changes, results, warnings, and errors with stable messages that the README can explain.
- Handle initialization failures visibly. Release sensors, buses, LEDs, or other outputs in `ensure` when the hardware needs a safe shutdown state.
- For a bounded example, keep the duration in project configuration and set the `rpremote run --timeout` value longer than the intended run time.
- Keep an interactive or persistent application responsive to the R2P2 environment when its design requires continued shell access.

## Build and run

Build without touching hardware unless the user requests device execution. When the project adds or changes mrbgem dependencies, validate and rebuild them from the repository root:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

Flash the resulting firmware only when the connected board does not already contain the required mrbgems and the user requested installation:

```sh
rpremote bootsel
rpremote flash
```

For a project with `lib/<name>/`, install that directory before running `main.rb`:

```sh
rpremote fs push examples/picoruby/projects/my_project/lib/my_project :/lib/my_project
rpremote run examples/picoruby/projects/my_project/main.rb
```

Run `fs push` again after changing a project library. A change limited to `main.rb` only requires running the entry point again. Project-source changes do not require a firmware rebuild unless `Mrbgems` or an embedded mrbgem also changed. `fs push` preserves remote-only files, so do not describe it as synchronization or deletion.

Use `rpremote dfu app` instead of `run` only when persistent A/B boot installation is part of the requested project. Confirm a DFU candidate only after initialization and self-checks succeed.

## Documentation

Write paired `README.md` and `README.ja.md` files around the user's path to a working result. Use the sections that apply, normally in this order:

1. Purpose and important limitations or safety warnings.
2. Wiring and power constraints.
3. `ビルドと実行` / `Build and run` with all required deployment commands.
4. `使用方法` / `How to use it` for physical interaction.
5. State, output, or log interpretation and the expected successful result.
6. Algorithm, configuration, troubleshooting, or other relevant limitations.
7. `ファイル構成` / `File structure` with each file's responsibility.

Keep both languages equivalent in commands, tables, safety information, and expected behavior. Explain what each deployment command changes on the device and what the user should observe after execution.

## Verification

Before handing off a project:

- Confirm that every documented file and relative link exists.
- Check the Ruby syntax and selected PicoRuby VM compatibility of `main.rb` and project libraries.
- Run `rpremote mrbgems check`, refresh `Mrbgems.lock`, and build when dependencies changed.
- Verify that README deployment paths match the local `lib/<name>/` and device `/lib/<name>` paths.
- Compare the Japanese and English headings, commands, tables, and examples.
- If hardware validation was not requested or performed, state that clearly. Do not infer success from a firmware build because it does not execute the project.
- When hardware validation is requested, install the libraries, run the smallest useful entry point, and record the observed serial output or physical result.

## Processing project

The Processing project is a persistent application with an external desktop visualization, so it uses PicoModem DFU rather than the temporary `run` workflow. Install its shared libraries before the launcher:

```sh
rpremote fs push examples/picoruby/projects/processing/lib/processing :/lib/processing
rpremote dfu app examples/picoruby/projects/processing/main.rb
rpremote reset
```

The device library must contain `/lib/processing/config`, `/lib/processing/unit`, `/lib/processing/stream`, and the selected files below `/lib/processing/units`. Preserve at least one confirmed DFU slot, and remove the persistent application before returning to temporary `rpremote run` development.
