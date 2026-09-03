# Development workflow

[日本語](development.ja.md)

Use a Raspberry Pi Pico 2 with the wiring and external LED power described in [hardware and safety](hardware.md). From the repository root, build, flash, and run the sample:

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

This builds firmware with the local Daisen Kofun mrbgems, flashes it to the Pico 2, reconnects to the R2P2 Shell, and runs `main.rb`. Flashing replaces the firmware installed on the Pico 2. On the first installation, when serial BOOTSEL entry is unavailable, connect the Pico 2 while holding its BOOTSEL button.

The default `main.rb` runs the `:illumination` mode and `:tests` setlist. The run is successful when the selected pattern completes and `DAISENKOFUN mode=illumination event=done status=ok` appears. After the firmware is on the Pico 2, choose the workflow that matches the files you changed.

| Changed files | What to do |
| --- | --- |
| `main.rb` only | Run the application script again. |
| `mrbgems/`, `Mrbgems`, or a hardware driver | Check dependencies, rebuild, flash, then run the application script. |

## Fastest device check: `rpremote exec`

`rpremote exec` sends one Ruby expression directly to the R2P2 Shell. It is the lightest way to verify functionality already included in the flashed firmware: there is no `main.rb` upload and no firmware rebuild.

For example, run only `structure_guide` from the repository root:

```sh
rpremote exec 'require "daisenkofun-illuminations"; Daisenkofun::Illumination.new.play_pattern(:structure_guide)' --timeout 120
```

The illumination mrbgem is not auto-required, so the expression loads it explicitly. Use `rpremote exec` for focused checks of an embedded component or pattern; use `rpremote run` when verifying the `main.rb` configuration, mode selection, and full application lifecycle.

The selected pattern runs, turns the LEDs off, and returns to the R2P2 Shell. `DAISENKOFUN mode=illumination event=led_off` confirms that the illumination cleaned up.

## Edit and run `main.rb`

Use this loop for mode selection, setlist selection, pattern selection, and measurement duration changes.

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

`rpremote run` uploads only the execution copy of `main.rb` to `/home/.rpremote-run.rb`; no `fs push` or `lib/daisenkofun` synchronization is needed. See [operating modes and settings](modes.md) for the available settings.

On success, the application writes `DAISENKOFUN mode=<selected mode> event=done status=ok`. If it reports `status=error`, use the error class and message in the same line to correct the configuration or hardware issue before running it again.

`--timeout 120` is the maximum time without R2P2 Shell output, not the total application runtime. The Oximeter default measurement duration is 60 seconds, and continuing measurement logs reset the timeout.

## Rebuild firmware

When changing an mrbgem, `Mrbgems`, or a hardware driver, run the following from the repository root:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

Flashing replaces the firmware installed on the Pico 2. After flashing, use the edit-and-run command above.

## Capture serial logs

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined-10min.log
```

Use a separate filename for each run. During long tests, correlate `event=fifo_backlog`, `event=loop_warning`, `event=error`, and `event=done` with the time at which LED corruption is observed.
