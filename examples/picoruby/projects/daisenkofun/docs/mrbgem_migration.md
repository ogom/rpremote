# Evaluating how to load PicoRuby illuminations

[日本語](mrbgem_migration.ja.md)

The Daisen Kofun project evaluated the following ways to load many illuminations with PicoRuby 4.0.3, in this order:

1. Load every Ruby source file at startup (eager loading)
2. Load each Ruby source file immediately before execution (lazy loading)
3. Load host-compiled `.mrb` files (precompilation)
4. Embed the illuminations in the firmware

Both eager and lazy loading required the device to compile many `.rb` files and were unstable. Precompilation avoided compilation on the device, but the lifetime of the loaded files caused consecutive execution to fail. The final approach removed Sandbox-based file loading and embedded the illuminations in the firmware as an mrbgem; this successfully ran `Setlist::SHORT` from beginning to end.

The commands, paths, logs, and `wait_ms` values in this document record the configuration at the time each approach was evaluated. See the project [`README.md`](../README.md) and current [`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb) for the present configuration.

## 1. Eager loading

The first approach called `require` for every illumination at startup.

As the number of files increased, compilation failed partway through the list.

```text
Exception(vm_id=23): in `load_file':
/lib/daisenkofun/illuminations/fireworks.rb: compile failed (RuntimeError)
```

After the target file was corrected, the failure moved to the next file, `golden_breath.rb`. This indicated that the problem involved resource consumption from consecutive compilation on the device, rather than only Ruby syntax in one specific file.

Eager loading reduces the number of `require` calls after execution starts. For a project with this many files, however, compilation and memory consumption are concentrated at startup.

## 2. Lazy loading

The next approach stopped loading every file at startup and loaded only the corresponding file immediately before executing each pattern.

```ruby
require "/lib/daisenkofun/illuminations/#{key}"
Illuminations.const_get(Setlist.class_name(key))
```

This reduced the startup load, but execution stopped while loading the second pattern when several patterns ran consecutively.

```text
daisenkofun: pattern 1/30 moonlight wait_ms=15 loops=1
daisenkofun: pattern 2/30 starry_kofun wait_ms=15 loops=1
rpremote: run event=ERROR,class=Rpremote::Shell::TimeoutError,
message=timed out waiting for the R2P2 Shell after 20.0 seconds
```

The pattern-start log is written before `require`. Seeing the `starry_kofun` log therefore does not mean that its class finished loading.

### Why lazy loading stops

PicoRuby 4.0.3 loads a library from the filesystem through `picoruby-require/mrblib/require.rb`, broadly in this order:

1. Check `$LOADED_FEATURES`
2. Look for files with the same name in `.mrb`, then `.rb`, order
3. Create a loading Sandbox with `Sandbox.new("require")`
4. Execute `sandbox.load_file(path)`
5. Call `sandbox.terminate`

For an `.rb` file, the Sandbox in `picoruby-sandbox/mrblib/sandbox.rb` performs the following sequence:

```text
Load the .rb file
  -> Compile it on the device
  -> Run the Sandbox task
  -> Wait for completion with wait(timeout: nil)
```

`wait(timeout: nil)` has no internal timeout. If the Sandbox task does not enter `DORMANT` or `SUSPENDED`, the calling `require` does not return.

The mruby/c Sandbox implementation in `picoruby-sandbox/src/mrubyc/sandbox.c` sets `flag_permanence = 1` on the Sandbox VM. This retains IREP referenced by methods so that methods on loaded classes can be called later. In addition, `terminate` moves the task to a terminated state, but unlike `close`, it does not release all Sandbox resources immediately.

Every sequential `.rb` load therefore compiles on the device, creates a Sandbox task, and retains IREP. Loading several illuminations consecutively is affected by memory consumption and fragmentation.

### The 20-second timeout is not the cause

When no output is received for the specified interval, `rpremote run` sends `Ctrl-C` and returns `Shell::TimeoutError`. The sequence in this test was:

```text
Pattern-start log
  -> Lazy require
  -> Wait indefinitely for the child Sandbox to finish
  -> Serial output and LED updates stop
  -> rpremote times out after 20 seconds
```

The 20-second limit was therefore not the reason execution stopped. The device failed to return from `require` and did not return control to the R2P2 Shell, causing the outer `rpremote` command to time out. Increasing `--timeout` does not address the underlying problem.

### The path and string interpolation are correct

The following code produces the expected absolute path from `key`:

```ruby
require "/lib/daisenkofun/illuminations/#{key}"
```

The first pattern, `moonlight`, loaded and reached its lighting code. An incorrect path or interpolation would have produced `LoadError` on the first load.

### Locating where execution stops

The lazy-loading investigation temporarily added the following logs to distinguish loading from execution:

```ruby
puts "load start: #{key}"
require "/lib/daisenkofun/illuminations/#{key}"
puts "load done: #{key}"

klass = Illuminations.const_get(Setlist.class_name(key))
puts "call start: #{key}"
klass.new(display, wait_ms, loops).call
puts "call done: #{key}"
```

If `load done` does not appear after `load start`, execution stopped while loading. If `call done` does not appear after `call start`, it stopped while running the pattern. On builds that expose mruby/c memory information, the `used`, `free`, and `fragmentation` values from `memory_statistics(false)` can also be recorded before and after each `require`.

## 3. Precompilation

Based on the eager- and lazy-loading results, the next test loaded host-generated `.mrb` files instead of compiling `.rb` files on the device.

The evaluation was limited to `Setlist::SHORT`: its seven patterns plus the shared `base` class.

```text
base
structure_guide
divine_light
launch_fireworks
sunrise
dappled_light
triple_moat_mirror
water_ripples
```

Each `.rb` file was compiled for the same PicoRuby 4.0.3 version as the device. For example:

```console
$ rpremote dfu compile \
    examples/picoruby/projects/daisenkofun/mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illuminations/structure_guide.rb \
    --language-version 4.0.3 \
    --output examples/picoruby/projects/daisenkofun/mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illuminations/structure_guide.mrb
```

When files with the same base name are present, PicoRuby 4.0.3 `require` looks for `.mrb` before `.rb`. Existing extensionless `require` calls therefore require no changes.

```text
/lib/daisenkofun/illuminations/structure_guide.mrb
/lib/daisenkofun/illuminations/structure_guide.rb
```

The eight generated files were verified as PicoRuby 4.0.3 `RITE0400` files and placed under `:/lib/daisenkofun/illuminations` on the device. This avoided compiling Ruby source on the device, but still created one Sandbox per pattern.

### Result

When `Setlist::SHORT` ran, the first pattern, `structure_guide`, completed, but the second, `divine_light`, raised an exception.

```text
daisenkofun: pattern 1/7 structure_guide wait_ms=10 loops=1
daisenkofun: pattern 2/7 divine_light wait_ms=10 loops=1
daisenkofun: LEDs off

Unimplemented opcode (0x20) found (Exception)
rpremote: run event=ERROR,class=Rpremote::Shell::CommandError,
message=Ruby exception reported by R2P2
```

This run used `--timeout 120`, but returned a Ruby exception before 120 seconds elapsed. The precompilation failure was therefore not caused by a timeout either.

### Why precompilation failed

In the PicoRuby 4.0.3 instruction table, `0x20` is `OP_SETMCNST`. The mruby/c VM treats this instruction as unimplemented in `picoruby-mrubyc/lib/mrubyc/src/vm.c`.

However, disassembling the generated `divine_light.mrb` showed that its valid instruction sequence did not contain `OP_SETMCNST`. The Ruby code did not generate an unsupported instruction; instead, the VM read memory other than the valid instruction sequence and interpreted a `0x20` byte there as an opcode.

Loading an `.mrb` file has the following characteristics:

1. `picoruby-sandbox/mrblib/sandbox.rb` reads the complete file into a string retained in the Sandbox's `@code`
2. `exec_mrb` passes the VM a pointer into the string without copying the instruction sequence
3. IREP in `picoruby-mrubyc/lib/mrubyc/src/load.c` also directly references the `.mrb` contents without copying the instruction sequence
4. The local Sandbox reference disappears when `require` finishes
5. If GC collects the Sandbox and `@code`, the class method's instruction pointer refers to released memory

The sequence is:

```text
require divine_light.mrb
  -> Define the class inside the Sandbox
  -> require finishes
  -> Sandbox and @code become collectible
  -> DivineLight#call refers to an invalid instruction pointer
  -> Detect 0x20 as an unimplemented opcode
```

The Sandbox's `@code` retains the `.mrb` while that Sandbox task is running. It does not retain it for the period in which methods defined by `require` are called after the Sandbox has ended. Lazy-loading individual `.mrb` files was therefore not safe for consecutive execution.

## 4. Embedding in the firmware

The final test moved all illuminations into the local `mrbgems/daisenkofun-illuminations` mrbgem and embedded them in the firmware. This approach does not use a Sandbox to load `.rb` or `.mrb` files from the filesystem.

The test embedded the `Setlist::SHORT` patterns and verified that:

1. `require "daisenkofun-illuminations"` made every embedded class available
2. Patterns from `structure_guide` through `water_ripples` ran consecutively
3. Execution did not depend on a Sandbox or source files on the filesystem

After registering the mrbgem, generating the lock, and building and flashing firmware for PicoRuby 4.0.3 and Raspberry Pi Pico 2, the following command was used for verification:

```console
$ rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

### Result

All seven `Setlist::SHORT` patterns ran in their configured order.

The following log records the test with `wait_ms=10`. The current `Setlist::SHORT` uses `SHORT_FRAME_MS`.

```text
daisenkofun: start
daisenkofun: pattern 1/7 structure_guide wait_ms=10 loops=1
daisenkofun: pattern 2/7 divine_light wait_ms=10 loops=1
daisenkofun: pattern 3/7 launch_fireworks wait_ms=10 loops=1
daisenkofun: pattern 4/7 sunrise wait_ms=10 loops=1
daisenkofun: pattern 5/7 dappled_light wait_ms=10 loops=1
daisenkofun: pattern 6/7 triple_moat_mirror wait_ms=10 loops=1
daisenkofun: pattern 7/7 water_ripples wait_ms=10 loops=3
daisenkofun: LEDs off
daisenkofun: OK
rpremote: run event=EXECUTE_DONE,bytes=466
rpremote: run event=CLEANUP_START,path=/home/.rpremote-run.rb
rpremote: run event=CLEANUP_DONE
```

No compilation failure, hang, `Shell::TimeoutError`, or `Unimplemented opcode` occurred. The run turned off the LEDs and reached `daisenkofun: OK`, `EXECUTE_DONE`, and `CLEANUP_DONE`, confirming successful completion.

### Why this approach succeeded

An mrbgem's instruction sequence is retained in the firmware as a prebuilt gem. It does not reference a temporary string loaded from the filesystem, so it avoids the invalid instruction pointer after GC that affected the precompiled-file approach.

It also avoids compiling each pattern's `.rb` file at runtime and does not create a Sandbox per pattern. `Illuminations.const_get` retrieves and executes classes embedded in the firmware, avoiding the device-side compilation load that affected eager and lazy loading.

For these reasons, this project embeds the illuminations in the firmware as an mrbgem.
