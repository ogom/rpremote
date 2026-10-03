# rpremote configuration

rpremote reads `config/setting.json` from the project root. Use `--config FILE` to select another file. Keys use `snake_case`, and command-line values override configuration.

All keys are validated even when the selected command ignores them. Unknown keys, empty strings, wrong types, and non-positive `baud` or `timeout` values are errors.

```json
{
  "port": "/dev/cu.usbmodem101",
  "baud": 115200,
  "timeout": 20,
  "language": "picoruby",
  "cache": "firmware",
  "language_version": "latest",
  "board": "pico2",
  "firmware": "firmware/picoruby-latest-pico2.uf2",
  "mount": "/Volumes/RP2350",
  "mrbgems_lock": "config/production.lock"
}
```

| Key | Type | Default | Commands | CLI option |
| --- | --- | --- | --- | --- |
| `language` | non-empty string | `picoruby` | `setup`, `build`, `flash`, `deploy`, `run`, `exec` | `--language` |
| `language_version` | non-empty string | `latest` | `setup`, `build`, `flash`, `deploy`, `dfu compile` | `--language-version`; `latest` tracks `master` |
| `cache` | non-empty string | `firmware` | `setup`, `build`, `flash`, `deploy`, `dfu compile` | `--cache` |
| `board` | non-empty string | `pico2` | `build`, `flash`, `deploy` | `--board` |
| `firmware` | non-empty string | `{cache}/{language}-{language_version}-{board}.uf2` | `build`, `flash`, `deploy` | `--firmware` |
| `mrbgems_lock` | non-empty string or `false` | automatic `Mrbgems.lock` discovery | `build`, `deploy`, `run`, `exec` | `--lockfile`, `--no-mrbgems` |
| `mount` | non-empty string | auto-detect | `bootsel`, `flash`, `deploy` | `--mount` |
| `port` | non-empty string | auto-select CDC 0 | `bootsel`, `flash`, `deploy`, runtime, `dfu` | `--port` |
| `baud` | positive integer | `115200` | runtime, `dfu` | `--baud` |
| `timeout` | positive number in seconds | `20` | `bootsel`, `flash`, `deploy`, runtime, `dfu` | `--timeout` |

`cache` may contain `{version}`, which expands to `language_version`. Without an explicit `firmware`, the target is `{cache}/{language}-{language_version}-{board}.uf2`.

`mrbgems_lock: false` disables locked dependency injection. An explicit `--lockfile FILE` overrides the configured path.

Keep machine-specific `port` and `mount` values out of shared configuration unless every user has the same hardware layout.
