# rpremote configuration

rpremote reads `config/setting.json` from the project root. Use `--config FILE`
to select another file. Keys use `snake_case`, and command-line values override
configuration.

All keys are validated even when the selected command ignores them. Unknown
keys, empty strings, wrong types, and non-positive `baud` or `timeout` values
are errors.

```json
{
  "port": "/dev/cu.usbmodem101",
  "baud": 115200,
  "timeout": 10,
  "language": "picoruby",
  "cache": "firmware",
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/picoruby-4.0.3-pico2.uf2",
  "mount": "/Volumes/RP2350",
  "mrbgems": "Mrbgems"
}
```

| Key | Type | Default | Commands | CLI option |
| --- | --- | --- | --- | --- |
| `language` | non-empty string | `picoruby` | `setup`, `build`, `flash`, `run`, `exec` | `--language` |
| `language_version` | non-empty string | `4.0.3` | `setup`, `build`, `flash`, `dfu compile` | `--language-version` |
| `cache` | non-empty string | `firmware` | `setup`, `build`, `flash`, `dfu compile` | `--cache` |
| `board` | non-empty string | `pico2` | `build`, `flash` | `--board` |
| `firmware` | non-empty string | `{cache}/{language}-{language_version}-{board}.uf2` | `build`, `flash` | `--firmware` |
| `mrbgems` | non-empty string or `false` | automatic `Mrbgems` discovery | `build` | `--mrbgems`, `--no-mrbgems` |
| `mount` | non-empty string | auto-detect | `flash` | `--mount` |
| `port` | non-empty string | auto-select CDC 0 | `flash`, runtime, `dfu` | `--port` |
| `baud` | positive integer | `115200` | runtime, `dfu` | `--baud` |
| `timeout` | positive number in seconds | `10` | `flash`, runtime, `dfu` | `--timeout` |

`cache` may contain `{version}`, which expands to `language_version`. Without an
explicit `firmware`, the target is
`{cache}/{language}-{language_version}-{board}.uf2`.

`mrbgems: false` disables automatic dependency injection for a build. An
explicit `--mrbgems FILE` overrides the configured path.

Keep machine-specific `port` and `mount` values out of shared configuration
unless every user has the same hardware layout.
