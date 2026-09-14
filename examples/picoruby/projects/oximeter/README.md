# MAX30102 oximeter with SPI NeoPixels

[日本語](README.ja.md)

This PicoRuby sample estimates heart rate and SpO2 from a MAX30102 and displays measurement state on eight WS2812/NeoPixel LEDs. Estimated values are reported in the serial log.

> This sample is for learning only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

## Wiring and safety

| MAX30102 | Raspberry Pi Pico 2 |
| -------- | ------------------- |
| VIN | Voltage accepted by the breakout board |
| GND | GND |
| SDA | GP16 |
| SCL | GP17 |

| WS2812/NeoPixel | Raspberry Pi Pico 2 |
| ---------------- | ------------------- |
| DIN | GP3 (`RP2040_SPI0` COPI) |
| GND | Common ground for the Pico and external LED supply |
| LED power | External supply sized for eight LEDs |

GP2 is configured as SPI SCK but is not connected to the LEDs. Do not power LEDs from a GPIO. For LEDs powered at 5 V, a 3.3 V-to-5 V logic-level shifter is recommended. Confirm the MAX30102 breakout board's accepted input voltage and whether it includes I2C level shifting.

## Build and run

Enable [max30102](../../mrbgems/max30102/README.md) and [ws2812_spi](../../mrbgems/ws2812_spi/README.md) in the root `Mrbgems`, then deploy from the repository root.

```sh
rpremote mrbgems lock
rpremote deploy --build examples/picoruby/projects/oximeter --timeout 120
```

`deploy` flashes the firmware, copies `lib/oximeter`, and runs `main.rb`. If only `main.rb` changes, run it against the embedded firmware and previously copied library:

```sh
rpremote run examples/picoruby/projects/oximeter --timeout 120
```

The application runs for 60 seconds, then shuts down the MAX30102 and turns off the LEDs.

## Measurement procedure

1. Run the application and wait for a dim white point on the LEDs.
2. Rest a fingertip lightly on the MAX30102 sensor surface.
3. When the LEDs turn blue, keep the finger still and in place.
4. Check the estimates when the log reports `OXIMETER_DATA,...,RESULT`.

Removing the finger resets the measurement and returns to the waiting state. If `SKIPPED` repeats, adjust finger position, pressure, or ambient light.

## Status display

| State | LED display |
| ----- | ----------- |
| Waiting for a finger | A dim white point moves |
| Measuring | A blue point moves with a dim green trail |
| Complete, SpO2 at least 97% | A green point moves in phase with the last beat |
| Complete, SpO2 below 97% | A red point moves in phase with the last beat |
| Sensor initialization error | Every LED briefly turns red |

The 97% value selects a display color in this sample. It is not a medical decision threshold.

The principal log categories are `OXIMETER_WAIT` (waiting), `OXIMETER_FINGER` (finger arrival or removal), `OXIMETER_BEAT` (beat or buffering), `OXIMETER_DATA` (estimate), `OXIMETER_DONE` (completion), and `OXIMETER_ERROR`/`OXIMETER_WARN` (failure).

```text
OXIMETER_DATA,timestamp_ms,red,ir,bpm,spo2,MEASURING|RESULT
```

## Estimation method and limitations

Beat detection uses an IR moving average, a baseline, and hysteresis. Heart rate is estimated from beat intervals greater than 350 ms and less than 1500 ms. SpO2 uses a ratio of ratios derived from the DC mean and AC standard deviation of red and infrared light, then limits the result to 0–100%.

The calculation is not calibrated for this hardware. Movement, ambient light, finger pressure, skin and circulation differences, LED current, and breakout-board characteristics can significantly affect the result. Compare algorithm changes with an appropriately validated device.

## Design guides and tests

- [Pub/Sub design](docs/pub_sub.md) — why measurement and display processing are separated
- [Time-driven processing with `tick`](docs/tick.md) — how LEDs move while no event occurs

Run host specifications from the repository root:

```sh
rake spec:examples:picoruby:oximeter
```

RSpec verifies configuration, calculation, event, display, and documentation contracts. Picotest under `test/` checks loading and composition on PicoRuby/mruby/c. Verify physical power, sensor accuracy, light, and timing on hardware.
