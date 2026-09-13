# Why the Daisen Kofun project uses mrbgems

[日本語](mrbgem_migration.ja.md)

## Decision

The Daisen Kofun project's Ruby code is embedded in the PicoRuby firmware as local mrbgems instead of being loaded incrementally from the device filesystem at runtime.

This is more than a file-layout preference. It keeps the illuminations, Oximeter, music, and runtime control stable on a Raspberry Pi Pico 2 and makes the firmware composition reproducible.

## Problem being solved

The illumination component contains many Ruby classes. Loading them as `.rb` files makes PicoRuby compile code and create Sandboxes while the application is running. That can work for a small example, but consecutive execution of a long setlist is affected by limited memory, fragmentation, and the lifetime of the loading operation.

Precompiling files as `.mrb` avoids compilation on the device, but the loaded instruction sequence must remain valid for as long as its methods are used. With the PicoRuby 4.0.3 and mruby/c configuration evaluated for this project, this did not provide stable consecutive execution.

## Approaches considered

| Approach | Benefit | Problem for this project |
| --- | --- | --- |
| Load every `.rb` file at startup | Few additional loads during playback | Compilation and memory use are concentrated at startup |
| Load one `.rb` file per pattern | Spreads startup work | Repeats device-side compilation and Sandbox creation |
| Load `.mrb` files as needed | Avoids device-side compilation | The loaded instruction sequence is difficult to retain safely for the full playback lifetime |
| Embed code as mrbgems | Compiles at build time and retains instructions in firmware | Requires a firmware rebuild when embedded code changes |

The project therefore favors stable long-setlist playback and embeds the code as mrbgems.

## Why mrbgems fit

- Ruby code is compiled by the host-side build process.
- Instructions remain in firmware and do not depend on a temporary Sandbox or loaded file contents.
- Dependencies between components are explicit in each `mrbgem.rake`.
- The root `Mrbgems` and `Mrbgems.lock` files make the embedded composition checkable and reproducible.
- Runtime code loads only public require names, hiding internal file layout from the application.

## Current components

| mrbgem | Responsibility |
| --- | --- |
| `daisenkofun-application` | Configuration validation and component composition |
| `daisenkofun-runtime` | Clock, logging, and event loop |
| `daisenkofun-oximeter` | MAX30102 measurements and event publication |
| `daisenkofun-musical` | Translation from heartbeat events to PWM sound |
| `daisenkofun-illumination` | LED layout, patterns, setlists, and heartbeat-driven display |

This split separates responsibilities while fixing dependency and load order during the build. See [operating modes and settings](modes.md) for the user-facing configuration.

## Loading rule

External code loads only each mrbgem's public name.

```ruby
require "daisenkofun-application"
```

Files within one mrbgem are compiled together. Production code therefore does not load an internal path such as `require "daisenkofun-application/config"`. Dependencies on another mrbgem are declared in `mrbgem.rake`.

The mrbgem-loading RSpec examples enforce this rule.

## Development workflow

Rebuild and deploy the firmware after changing an mrbgem's Ruby code, its `mrbgem.rake`, or the root `Mrbgems` file.

```sh
rpremote deploy examples/picoruby/projects/daisenkofun --build
```

When embedded code is unchanged and only public settings in `main.rb` have changed, a regular `rpremote run` is sufficient. See the [development workflow](development.md) for details.

## Tradeoffs and reasons to reconsider

The mrbgem approach requires a build and firmware flash for Ruby code changes, and embedded code consumes firmware space. The project currently values long-running stability and reproducibility more than runtime loading flexibility.

Dynamic loading should be evaluated again if PicoRuby changes its filesystem-load and Sandbox lifetime behavior, or if adding patterns after deployment becomes a project requirement.
