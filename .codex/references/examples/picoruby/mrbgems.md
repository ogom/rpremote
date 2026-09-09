# Creating a local PicoRuby mrbgem

## Scope

This reference applies to local PicoRuby mrbgems created under `examples/picoruby/mrbgems/<name>/` or a project's `mrbgems/<name>/` directory. Create an mrbgem when functionality must be compiled into PicoRuby firmware. Keep application-specific behavior in the project application; expose a small, reusable hardware or protocol API from the mrbgem.

Before implementation, inspect the closest existing mrbgem in the same directory and follow its layout. Use `my_gems` as the smallest pure-Ruby example. Use `max30102`, `mpu6050`, or `bmi270` when a Ruby API wraps native code.

## Choose the implementation boundary

- Use `mrblib/` for a pure-Ruby API or high-level behavior built on existing PicoRuby gems.
- Use `src/` only when native code, a vendor data table, or a performance-critical binding is necessary.
- For sub-millisecond GPIO timing or polling, inspect the selected runtime's clock and scheduler resolution. Use native code or PIO when interpreter overhead can materially affect correctness or measurement accuracy.
- Depend on existing PicoRuby mrbgems, such as `picoruby-i2c`, `picoruby-spi`, or `picoruby-gpio`, instead of reimplementing their transport layers.
- Keep hardware setup, pin selection, and application flow outside the mrbgem unless they are intrinsic to the reusable API.

## Required layout

Create the gem under `examples/picoruby/mrbgems/<name>/` with at least:

```text
<name>/
  mrbgem.rake
  README.md
  README.ja.md
  LICENSE
```

Add these directories when applicable:

```text
  mrblib/<require_name>.rb
  src/<require_name>.c
  sig/<require_name>.rbs
  test/<require_name>_test.rb
```

Use one require name consistently in `mrbgem.rake`, the Ruby entry file, documentation, tests, and application code. Prefer a descriptive gem name such as `picoruby-max30102` and a matching snake_case require name such as `max30102`.

### Layout for multiple Ruby files

When a gem has more than one Ruby implementation file, use the require name for both its entry point and implementation directory:

```text
<name>/
  mrbgem.rake
  mrblib/
    <require_name>.rb
    <require_name>/
      config.rb
      device.rb
      player.rb
      patterns/
        base.rb
        example.rb
```

The entry point defines the root namespace. Each implementation file defines its complete namespace rather than depending on the lexical scope or load side effects of another file:

```ruby
# mrblib/device-suite.rb
module DeviceSuite
end
```

```ruby
# mrblib/device-suite/device.rb
module DeviceSuite
  class Device
  end
end
```

For a compound require name, document the mapping when it is not a direct snake_case-to-constant conversion:

| Item | Example |
| --- | --- |
| Gem name | `picoruby-device-suite` |
| Require name | `device-suite` |
| Entry point | `mrblib/device-suite.rb` |
| Implementation directory | `mrblib/device-suite/` |
| Root namespace | `DeviceSuite` |

Do not mix a singular require name with a plural implementation directory, or place implementation files under an unrelated namespace directory. Avoid abbreviated declarations such as `module Parent::Child`; write the complete nested modules so constant lookup does not depend on which file happened to load first.

## Gem specification

Define the gem with accurate metadata, a stable require name, and only the dependencies it needs:

```ruby
MRuby::Gem::Specification.new("picoruby-device") do |spec|
  spec.license = "MIT"
  spec.author = "Your Name"
  spec.summary = "Short description of the device or protocol"
  spec.require_name = "device"

  spec.add_dependency "picoruby-i2c"
end
```

Use the actual combined license when bundled data or third-party source has a different license. Include the applicable license text in the gem directory and describe that dependency in both READMEs.

### Define Ruby load order explicitly

For a multi-file mrbgem, do not rely on filesystem traversal or alphabetical order when one file defines a constant used by another. Arrange `spec.rbfiles` from foundational definitions to consumers:

```ruby
MRuby::Gem::Specification.new("picoruby-device-suite") do |spec|
  spec.require_name = "device-suite"

  namespace_file = "#{spec.dir}/mrblib/device-suite.rb"
  library_dir = "#{spec.dir}/mrblib/device-suite"
  base_file = "#{library_dir}/patterns/base.rb"
  pattern_files = spec.rbfiles
    .select { |path| path.start_with?("#{library_dir}/patterns/") }
    .reject { |path| path == base_file }
    .sort

  ordered_files = [
    namespace_file,
    "#{library_dir}/config.rb",
    "#{library_dir}/device.rb",
    base_file,
    *pattern_files,
    "#{library_dir}/player.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
```

A useful default order is:

```text
root namespace
configuration and value definitions
hardware or transport boundary
base classes and contracts
concrete implementations
registries
controllers, players, or runners
```

Mirror this order in the host test helper. Tests that load files in a different order can hide a missing constant or create a failure that does not occur in firmware.

## API and implementation

- Define the public Ruby API before writing native bindings. Keep constructor arguments explicit, for example `i2c:` or `spi:`, rather than global pin state.
- Return documented Ruby values with stable units and names. Raise clear errors for unsupported configuration or failed device initialization.
- Put public Ruby classes and module methods in `mrblib/`. Keep C bindings narrow and private where possible.
- Add an RBS signature for every public class, initializer, reader, and method.
- Add tests for normal operation, invalid arguments, boundary values, and transport or initialization failures that can be simulated without hardware.
- Do not expose raw vendor constants unless they are part of a useful public configuration API.

## Verify runtime compatibility

Confirm every PicoRuby API used by the gem for the VM selected in `Mrbgems`. Inspect the prepared PicoRuby source under `firmware/picoruby-<version>/`, including the dependency's RBS files and `src/mrubyc` or `src/mruby` implementation when necessary.

A successful `mrbc` compilation or firmware build does not prove that a called Ruby method exists at runtime. For example, a timing method may exist in the Pico SDK or mruby implementation without being exposed to mruby/c. Prefer monotonic clocks for elapsed-time measurements and verify the actual sleep resolution before relying on fractional seconds.

For mruby/c firmware, an mrbgem's Ruby files are compiled together and exposed as the picogem named by `spec.require_name`. An internal source path such as `require "device-suite/config"` is not necessarily registered as a separate picogem on the device. External application code should require the public name:

```ruby
require "device-suite"
```

Use `spec.rbfiles` to establish the internal definition order instead of adding runtime `require` calls between the gem's own source files. Host tests may require individual files, but their order must match `spec.rbfiles`.

If the gem contains a C extension, define native classes and modules under the same hierarchy as the Ruby entry point. A matching filename or C initialization symbol alone does not establish the intended Ruby namespace.

When the user provides hardware-verified sample code, treat its formulas, timing values, and observed behavior as evidence. Preserve reusable behavior while reconciling the sample with the selected PicoRuby VM and the mrbgem's testable API.

## Test without hardware

Keep transport objects and clocks injectable when doing so makes hardware-independent behavior testable. Pure-Ruby local mrbgems can use the repository's host smoke-test helper:

```sh
ruby .codex/scripts/test_pure_ruby_mrbgem.rb examples/picoruby/mrbgems/device
```

The helper runs Picotest assertions on CRuby. It does not validate mruby/c runtime availability, native bindings, scheduler behavior, or physical hardware. For a gem with `src/`, use the applicable PicoRuby target test harness when available and always compile the selected VM. State clearly when a target or hardware test was not run.

## Add the gem to firmware

Add the local path to the project-root `Mrbgems`. Paths are relative to that file:

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/device"
```

Use the VM required by the gem and its dependencies. Do not edit extracted PicoRuby sources or official build configurations.

After changing a local mrbgem, refresh its content hash and rebuild the firmware:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

Flash the firmware and run a hardware example only when the task includes device validation.

## Documentation

Write paired English and Japanese READMEs. Follow the repository document style:

1. What the gem provides.
2. Firmware dependency and installation in `Mrbgems`.
3. A minimal working code example.
4. Wiring and electrical or safety constraints.
5. Public API and return values.
6. Supported scope, limitations, and license information.

Document pin mappings in a table when they are simple. Use ASCII `->` only for a path through multiple components. Explain the expected output or device behavior after each runnable example.

## Verification

Before handing off an mrbgem:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

- Run the repository test and signature-validation commands that actually cover the changed gem. Do not present a host smoke test as a target-runtime test.
- For a multi-file gem, verify that the entry point, implementation directory, root namespace, and `spec.rbfiles` order follow the same documented convention.
- Search for obsolete require paths and constants after moving files or changing namespaces.
- Confirm that the local gem is included in `Mrbgems.lock` and commit both files together when the dependency change is intended.
- Check both READMEs for matching headings, commands, tables, code examples, safety information, and working relative links.
- When hardware validation is in scope, flash the built UF2, run the smallest example, and record the expected serial output or physical result.
