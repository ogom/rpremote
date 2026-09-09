# Repository changelog

Notable changes to the examples, local mrbgems, firmware support files, and repository-level documentation are recorded here. Changes to the `rpremote` RubyGem are recorded separately in [`packages/rpremote/CHANGELOG.md`](packages/rpremote/CHANGELOG.md).

## Unreleased

- Refactor the Daisen Kofun application and local mrbgems to follow their require-name CoC, with dedicated `Application`, `Runtime`, `Oximeter`, `Musical`, and singular `Illumination` namespaces, callable runners, explicit ownership and cleanup, configurable WS2812/I2C/SPI/PWM pins, and mruby/c-compatible loading.
- Add event-driven MAX30102 measurement and live biometric PWM music, including pulse translation, a synchronized three-moat canon, repeatable eight-beat heartbeat signatures, performance verification, and physical Pico 2 validation.
- Improve real-time combined operation with C-backed 572-pixel transfers, indexed fills, frame caching, and uninterrupted PWM across `sleep_ms`, while preserving all 32 illumination pattern checksums.
- Add continuous setlist and pattern playback, clarify the `illumination`, `oximeter`, and `combined` modes, and consolidate the bilingual setup, hardware, safety, development, and verification documentation.

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
