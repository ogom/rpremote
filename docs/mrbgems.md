# Mrbgems and Mrbgems.lock

`rpremote` can add mrbgems that are not part of the standard PicoRuby build configuration to custom firmware. Define dependencies in the project-root `Mrbgems` file and record their resolved versions in `Mrbgems.lock`.

This workflow does not edit extracted PicoRuby sources or official `build_config` files. `rpremote build` generates a temporary build configuration that adds the gems.
The managed `PicoRubySourcePatch` for R2P2 Ruby exception statuses is the only source-patch exception; see [Custom firmware](firmware.md).

## First steps

Prepare the PicoRuby source, validate the definition, and create the lock file.

```sh
rpremote setup
rpremote mrbgems check
rpremote mrbgems lock
```

Then build the custom firmware.

```sh
rpremote build --firmware firmware/r2p2-picoruby-latest-pico2.uf2
```

After changing an mrbgem, rebuild and flash the custom firmware before running an example:

```sh
rpremote build
rpremote bootsel
rpremote flash
rpremote run examples/picoruby/education/06_mpu6050/main.rb
```

`deploy PATH --build` performs this firmware build, BOOTSEL transition, and flash automatically. Without `--build`, `deploy PATH` flashes the existing UF2. After the board reconnects, both forms copy `PATH/lib/NAME` to `:/lib/NAME` and temporarily run `PATH/main.rb`.

`Mrbgems.lock` in the project root is auto-detected by build and runtime commands. Use `--lockfile FILE` for a different lock or `--no-mrbgems` to build and run without locked gems. A project `Mrbgems` without `Mrbgems.lock` is an error during build; run `rpremote mrbgems lock` explicitly first.

## Mrbgems format

`Mrbgems` is Ruby source. Select the target VM first, then add public or local gems.

```ruby
# frozen_string_literal: true
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

### Groups

Use Bundler-style `group` blocks for gems needed only in particular firmware variants. Gems outside a group are common to every variant.

```ruby
gem path: "../mrbgems/device"

group :development, :test do
  gem path: "../mrbgems/debug-console"
end

group :production do
  gem github: "owner/telemetry", require: "telemetry"
end

gem path: "../mrbgems/test-helper", group: :test
```

The `group:` option is equivalent to placing the gem in a group block and also accepts an array. Group selection happens when creating the lock. Without `--with`, only ungrouped common gems are locked. Add groups with `--with` and remove groups with `--without`; both accept comma-separated names:

```sh
rpremote mrbgems lock --with production
rpremote mrbgems lock --with production,test
rpremote mrbgems lock --with production --without test
```

The lock contains ungrouped gems plus gems belonging to any selected group, except gems belonging to an excluded group. `--without` takes precedence when a gem belongs to both included and excluded groups. `build`, `deploy`, `run`, and `exec` do not select groups again; they use exactly the gems recorded in the lock. Use separate lock files for concurrently maintained firmware variants.

### VM selection

Specify `vm` once as either `:mrubyc` or `:mruby`. rpremote selects the official build configuration appropriate for the selected PicoRuby version.

| PicoRuby | `vm :mrubyc` | `vm :mruby` |
| --- | --- | --- |
| 4.x | `femtoruby` | `picoruby` |
| 3.x | `picoruby` | `microruby` |

For example, `picoruby-ws2812-plus` is an mruby/c C extension, so it uses `vm :mrubyc`.

### GitHub gems

Specify a public gem with its `owner/repository` and branch.

```ruby
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
```

An explicit commit is also supported.

```ruby
gem github: "owner/repository", commit: "a commit SHA of at least 40 characters"
```

A gem specified by branch is resolved to a GitHub commit SHA by the first `lock` command.

### Local gems

Specify a local gem as a path relative to `Mrbgems`. The target requires `mrbgem.rake`.

```ruby
gem path: "../mrbgems/my-device"
```

The local gem contents are recorded as SHA-256. Files below `.git`, `build`, and `tmp` are excluded from the hash.

## Automatic requires

When a local gem declares `spec.require_name` in `mrbgem.rake`, `lock` records it as `require_name`. `rpremote run`, `exec`, and `deploy` prepend `require "NAME"` for every recorded name, so application files do not need to repeat those requires.

For a GitHub gem, specify the name explicitly because its `mrbgem.rake` is not available while creating the lock file.

```ruby
gem github: "owner/repository", branch: "main", require: "device_driver"
```

Use `auto_require: false` for a gem that should be embedded in firmware without being loaded before every `run`, `exec`, or `deploy`. The application must explicitly `require` it when needed. This is useful when several applications share one firmware or when limiting symbol-table and RAM usage.

```ruby
gem path: "../mrbgems/my-application", auto_require: false
```

The gem remains part of the build, but its auto-loading `require_name` is omitted from the lock file. The gem's own `spec.require_name` is unchanged, so applications can still require it explicitly. Omitting this option preserves the existing `auto_require: true` behavior.

## Mrbgems.lock

`Mrbgems.lock` version 2 is JSON and records selected and excluded groups in `with` and `without`. Its `gems` array contains common gems and gems selected by `--with`, after applying `--without`. GitHub gems record the resolved commit; local gems record their content SHA-256 and, when available, their `require_name`. The local checksum covers files recursively except files under `.git`, `build`, and `tmp` directories.

```json
{
"version": 2,
"vm": "mrubyc",
"with": ["production"],
"without": ["test"],
"gems": [
{
"type": "github",
"source": "ksbmyk/picoruby-ws2812-plus",
"branch": "main",
"commit": "16699f8eb163df3fad86cfe826590bf890d0bb58"
}
]
}
```

Commit `Mrbgems` and `Mrbgems.lock` together as the custom-firmware configuration. `rpremote build` reads only the lock, does not evaluate `Mrbgems`, does not resolve branch heads, and does not rewrite the lock. It also verifies each local gem against its locked SHA-256 before building. The underlying PicoRuby build may fetch a repository at its pinned commit or set up the SDK when the corresponding cache is missing.

## Commands

```sh
# Validate the definition and local-gem layout.
rpremote mrbgems check
# List dependencies from the definition and lock file.
rpremote mrbgems list
# Lock common gems; existing GitHub commits are reused.
rpremote mrbgems lock
# Lock common and production gems.
rpremote mrbgems lock --with production --without test
# Resolve selected GitHub branches again and update the lock.
rpremote mrbgems update --with production --without test
```

Run `rpremote mrbgems update` only to move selected dependencies to their latest versions, then review and commit the changed lock file. `lock` validates local gems selected for that lock; `check` validates every local gem in the definition, including unselected groups. Version 1 locks must be regenerated before they can be consumed.

You can also specify the definition and lock-file paths explicitly.

```sh
rpremote mrbgems check --file config/Mrbgems
rpremote mrbgems lock --file config/Mrbgems --lockfile config/production.lock --with production
rpremote build --lockfile config/production.lock
```

## Differences from Gemfile and Gemfile.lock

Mrbgems borrows Bundler's DSL style, but its groups and lock files have different meanings. Bundler normally resolves every group into one lock, whereas Mrbgems locks only groups selected by `--with` and not excluded by `--without`.

| Aspect | Gemfile / Gemfile.lock | Mrbgems / Mrbgems.lock |
| --- | --- | --- |
| Primary purpose | Fetch and install gems used by CRuby and other Ruby runtimes | Select and pin mrbgems embedded in PicoRuby firmware |
| Definition | Gem names, version constraints, sources, platforms, groups, and related settings | GitHub or local paths, branches, commits, VM, require settings, and groups |
| Lock scope | All groups and transitive dependencies derived from the Gemfile | Direct mrbgems that are ungrouped or selected by `--with`, except those excluded by `--without` |
| Role of groups | Vary install, setup, and require behavior by environment | Determine which mrbgems are recorded and embedded in firmware |
| Stored group data | Group structure normally remains in the Gemfile rather than Gemfile.lock | Top-level `with` and `without`, plus each entry's `groups` |
| Version resolution | Resolve gem versions and transitive dependencies from constraints | Pin a GitHub commit or the SHA-256 of local path contents |
| Platform data | Ruby platforms, Ruby version, Bundler version, and related data | The mruby or mrubyc VM |
| Definition use with a lock | Uses the Gemfile for group and `require` declarations | Builds use only Mrbgems.lock and do not evaluate Mrbgems |
| Missing lock | `bundle install` normally resolves dependencies and creates Gemfile.lock | A build fails when Mrbgems exists without an explicit lock |
| Updating | Install or `bundle lock --update` can update resolution | `mrbgems lock` retains commits; `mrbgems update` resolves them again |
| Build/install network access | May download unresolved gems or resolve dependencies | A build never resolves a branch or rewrites the lock; underlying build tools may fetch a pinned repository or SDK when its cache is missing |
| Local dependencies | Handles versions and dependencies of path gems | Verifies the SHA-256 of path files, excluding `.git`, `build`, and `tmp` directories |
| Automatic loading | The Gemfile contains `require` settings and `Bundler.require` selects groups | Lock entries contain `require_name` and `auto_require`; only locked gems are automatically required |

### Group semantics

In a Gemfile, groups do not remove dependencies from the lock.

```ruby
gem "rack"

group :development, :test do
  gem "rspec"
end
```

Even when `without` excludes an install group, Bundler normally resolves both `rack` and `rspec` into one Gemfile.lock. This prevents environments from producing different version resolutions. Gemfile.lock normally does not record that rspec belongs to the development and test groups.

Mrbgems uses groups to select a firmware configuration.

```ruby
gem github: "example/common"
gem path: "mrbgems/production", group: :production
gem path: "mrbgems/debug", group: [:production, :test]
```

```sh
rpremote mrbgems lock --with production --without test
```

This records only `common` and `production` in Mrbgems.lock. Although `debug` belongs to production, it also belongs to the excluded test group, so it is omitted. Locking without `--with production` records only `common`. Mrbgems.lock is therefore a selected input for one firmware configuration, not a shared resolution of every available dependency.

### Lock contents

Gemfile.lock records a complete dependency graph, including dependencies of directly declared gems. It stores each resolved version and, as appropriate, source, platform, and checksum information.

Mrbgems.lock records selected mrbgems declared directly in Mrbgems. It does not resolve RubyGems version constraints or a transitive dependency graph. GitHub dependencies are pinned to commits, while path dependencies are pinned to content SHA-256 values. Recursively locking an mrbgem's internal build dependencies as Bundler does is outside this specification.

### Consumption

Bundler uses Gemfile together with Gemfile.lock. It reads group, platform, and `require` declarations from Gemfile and resolved versions from Gemfile.lock. A normal `bundle install` may update the lock after the Gemfile changes.

`rpremote build` does not evaluate Mrbgems and uses only Mrbgems.lock as input. It does not select groups, resolve commits, obtain require settings, or update the lock while building. This produces the same build overlay from the same lock without executing DSL code during a build.

### Command comparison

| Bundler | rpremote | Notes |
| --- | --- | --- |
| `bundle lock` | `rpremote mrbgems lock` | Creates a lock; Mrbgems selects only ungrouped gems by default |
| `bundle config set --local with GROUPS` | `rpremote mrbgems lock --with GROUPS` | Adds matching gems to the Mrbgems lock itself |
| `bundle config set --local without GROUPS` | `rpremote mrbgems lock --without GROUPS` | Removes matching gems from the Mrbgems lock itself |
| `bundle lock --update` | `rpremote mrbgems update` | Updates a resolved version or commit |
| `bundle install` | `rpremote build` | Bundler installs gems; rpremote embeds locked mrbgems in firmware |
| `Bundler.require(:group)` | Automatic require from the lock | rpremote does not select groups again at runtime |

### Intended trade-offs

- Gemfile.lock can serve multiple environments from one lock while keeping version resolution consistent across all groups.
- Mrbgems.lock shows only what enters the firmware, making its contents easy to audit and a build reproducible from the lock alone.
- Maintaining development and production firmware configurations concurrently requires separate lock files generated with the appropriate `--with` and `--without` selections.
- Changing group selection and overwriting the same Mrbgems.lock discards the previous configuration. Use `--lockfile` to maintain configurations in parallel.

## Files generated by builds

`rpremote build` and the build stage of `rpremote deploy` create these project files.

- `build/mrbgems/<fingerprint>/build_config.rb`: temporary configuration that combines the original official configuration and dependencies.
- `build/`: intermediate files such as CMake output.
- `firmware/*.uf2`: completed UF2 selected by `--firmware`; without it, the file is saved to `{cache}/{language}-{language_version}-{board}.uf2`.

The fingerprint reflects `Mrbgems.lock` and the original build configuration. Builds with different settings or locked dependencies do not share intermediate output.

Remove only intermediate output with the command below. It does not remove `firmware/`, `Mrbgems`, or `Mrbgems.lock`.

```sh
rpremote build clean
```
