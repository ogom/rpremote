# Repository changelog

Notable changes to the examples, local mrbgems, firmware support files, and repository-level documentation are recorded here. Changes to the `rpremote` RubyGem are recorded separately in [`packages/rpremote/CHANGELOG.md`](packages/rpremote/CHANGELOG.md).

## Unreleased

- Rename the Daisen Kofun illumination setlists from duration-based modes to `highlights`, `story`, and `showcase`, and add explicit APIs for playing a setlist or one pattern.
- Add a prepared `daisenkofun-oximeter` mrbgem with injectable sensor, clock, logger, and status display dependencies plus explicit `start`, `tick`, and `stop` lifecycle methods.
- Decouple Oximeter measurement from LED rendering through finger, beat, and measurement events that can be consumed by the eight-LED display, the Daisen Kofun LEDs, or future musical behavior.
- Include MAX30102, WS2812 SPI, and `daisenkofun-oximeter` in the firmware manifest, with explicit mrbgem dependencies for the sensor and eight-LED status display.
- Add `Daisenkofun::Application` to select illumination or Oximeter execution, validate program-specific settings, standardize lifecycle logs and status, and guarantee hardware cleanup on errors.

## 0.4.0 - 2026-08-31

- Add the Daisen Kofun PicoRuby project, with 32 WS2812 illumination patterns, a firmware-embedded local mrbgem, LED layout and setlist definitions, bilingual documentation, and host-side regression tests.

## 0.3.0 - 2026-08-28

- Add PicoRuby mrbgem examples for BMI270, HC-SR04 temperature, MAX30102, MPU6050, and WS2812 SPI.
- Add PicoRuby projects demonstrating an oximeter and Processing integration.

## 0.2.0 - 2026-08-26

- Add a bilingual educational example for practical PicoModem DFU application updates, startup confirmation, and A/B-slot rollback.

## 0.1.0 - 2026-08-24

- Establish the repository layout with the `rpremote` RubyGem under `packages/rpremote`, firmware support files, and electronic-craft examples.
- Add bilingual repository and example documentation.
