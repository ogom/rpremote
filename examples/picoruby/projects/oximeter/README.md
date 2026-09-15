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

## Change settings

The main operator-adjustable values are in [`lib/oximeter/config.rb`](lib/oximeter/config.rb).

| Setting | Default | When to change it |
| ------- | ------: | ----------------- |
| `RUN_DURATION_MS` | `60_000` | Lengthen or shorten the measurement run |
| `I2C_SDA_PIN` / `I2C_SCL_PIN` | `16` / `17` | Change MAX30102 wiring |
| `SPI_SCK_PIN` / `SPI_COPI_PIN` | `2` / `3` | Change status-LED SPI wiring |
| `LED_BRIGHTNESS` | `12` | Adjust status-LED brightness |
| `FINGER_THRESHOLD` | `20_000` | Tune finger detection for the sensor being used |
| `MIN_BEAT_INTERVAL_MS` / `MAX_BEAT_INTERVAL_MS` | `350` / `1_500` | Change the accepted beat-interval range |
| `RESULT_SAMPLES` | `8` | Change how many accepted beats are averaged before a result |
| `SPO2_GREEN_LIMIT` | `97.0` | Change the presentation boundary between green and red results |

After changing `lib/oximeter`, transfer the library again without rebuilding firmware:

```sh
rpremote fs push examples/picoruby/projects/oximeter/lib/oximeter :/lib/oximeter
rpremote run examples/picoruby/projects/oximeter --timeout 120
```

After tuning a threshold, verify both finger detection and the return to the waiting state after the finger is removed.

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

## Read the log

| Log | Meaning and check |
| --- | ----------------- |
| `OXIMETER_START,address=0x57,duration_ms=...` | The MAX30102 was found and measurement started; check the I2C address and duration |
| `OXIMETER_WAIT,...` | The application is waiting for a finger; `red` and `ir` are raw readings |
| `OXIMETER_FINGER,...,DETECTED,...` | A finger was detected and a new measurement began |
| `OXIMETER_FINGER,...,REMOVED,...` | The finger was removed and the partial measurement was reset |
| `OXIMETER_BEAT,...,BUFFERING,...` | Signal samples needed for the SpO₂ estimate are still being collected |
| `OXIMETER_BEAT,...,SKIPPED,...` | A candidate beat interval was outside the accepted range |
| `OXIMETER_DATA,...,MEASURING` | An intermediate estimate; keep the finger still |
| `OXIMETER_DATA,...,RESULT` | A result after the required accepted beats |
| `OXIMETER_DONE,bpm=...,spo2=...` | Final values when the run duration ended |
| `OXIMETER_ERROR,...` / `OXIMETER_WARN,...` | Sensor initialization or shutdown encountered a problem |

```text
OXIMETER_DATA,timestamp_ms,red,ir,bpm,spo2,MEASURING|RESULT
```

| Field | Meaning |
| ----- | ------- |
| `timestamp_ms` | Elapsed time since board startup, in milliseconds |
| `red` / `ir` | Raw red-light and infrared readings from the MAX30102 |
| `bpm` | Estimated beats per minute |
| `spo2` | Estimated SpO₂ percentage |
| `MEASURING` / `RESULT` | Intermediate estimate / result after the required beats |

A few `SKIPPED` lines do not stop measurement. If they repeat and no `RESULT` appears, adjust finger position, pressure, or ambient light.

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
