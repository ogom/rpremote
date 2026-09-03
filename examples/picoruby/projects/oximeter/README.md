# MAX30102 oximeter with SPI NeoPixels

[日本語](README.ja.md)

This sample estimates heart rate and SpO2 with a MAX30102 and shows the measurement state on eight WS2812/NeoPixel LEDs. Check the estimated heart rate and SpO2 in the serial log.

> This sample is for learning only. It is not a medical device and must not be used for diagnosis, treatment decisions, or safety monitoring.

## Wiring

Connect the MAX30102 over I2C.

| MAX30102 | Raspberry Pi Pico 2 |
| --- | --- |
| VIN | Voltage accepted by the breakout board |
| GND | GND |
| SDA | GP16 |
| SCL | GP17 |

Connect the WS2812/NeoPixel LEDs over SPI.

| WS2812/NeoPixel | Raspberry Pi Pico 2 |
| --- | --- |
| DIN | GP3 (`RP2040_SPI0` COPI) |
| GND | GND, shared by the Pico and the LED power supply |
| LED power | An external supply sized for eight LEDs |

GP2 is configured as SPI SCK but is not connected to the LEDs.

Do not power LEDs from a GPIO. When the LEDs use a 5 V supply, a 3.3 V-to-5 V logic-level shifter is recommended. Also confirm the MAX30102 breakout board's accepted input voltage and whether it includes I2C level shifting.

## Build and run

The project `Mrbgems` defines the required local [max30102](../../mrbgems/max30102/README.md) and [ws2812_spi](../../mrbgems/ws2812_spi/README.md) mrbgems.

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote bootsel
rpremote flash
rpremote fs push examples/picoruby/projects/oximeter/lib/oximeter :/lib/oximeter
rpremote run examples/picoruby/projects/oximeter/main.rb
```

`main.rb` contains hardware composition, the measurement loop, and cleanup. During normal development, edit `main.rb` and repeat only `rpremote run`; that command uploads only `main.rb`.

`lib/oximeter` contains reusable measurement and LED-display components. Repeat `fs push` only after changing one of those files.

The application runs for 60 seconds, then shuts down the MAX30102 and turns off the LEDs. To change that duration, edit `RUN_DURATION_MS` in `lib/oximeter/config.rb`. The `rpremote run` timeout measures idle time and resets while the application continues to write logs.

## How to use it

1. Run the application and wait for a dim white point to appear on the LEDs.
2. Rest a fingertip lightly on the MAX30102 sensor surface.
3. When the LEDs change to the blue measuring display, keep the finger still and in place.
4. When the serial log prints `OXIMETER_DATA,...,RESULT`, check the estimated heart rate and SpO2.

Removing the finger during measurement resets the result and returns the application to the waiting state. Place the fingertip steadily on the sensor again to restart the measurement.

## Measurement events

`Measurement::Processor` does not control LEDs directly. It publishes `finger_detected`, `finger_removed`, `beat`, `measurement_updated`, and `measurement_completed` events through `Dispatcher`. `StatusLed::Presenter` subscribes to them and translates them into state for the eight-LED display.

See [the Pub/Sub implementation](docs/pub_sub.md) for its implementation and rationale, and [time-driven processing with `tick`](docs/tick.md) for how animation advances separately from event delivery.

## Status display

### LEDs

| State | LED display |
| --- | --- |
| Waiting for a finger | A dim white point moves. |
| Measuring | A blue point moves with a dim green trail. |
| Measurement complete (SpO2 at least 97%) | A green point moves in phase with the most recently detected beat. |
| Measurement complete (SpO2 below 97%) | A red point moves in phase with the most recently detected beat. |
| Sensor initialization error | All LEDs briefly turn red. |

The 97% threshold only selects the LED color in this sample. It is not a medical decision threshold.

### Serial log

| Log | Meaning |
| --- | --- |
| `OXIMETER_START,...` | The MAX30102 was detected and measurement started. It includes the I2C address and duration. |
| `Place a fingertip steadily over the MAX30102.` | Prompts you to hold a fingertip steadily on the sensor. |
| `OXIMETER_WAIT,...` | Waiting for a finger. `red` and `ir` are the raw red-light and infrared readings. |
| `OXIMETER_FINGER,...,DETECTED,...` | A finger was detected and measurement started. |
| `OXIMETER_FINGER,...,REMOVED,...` | The finger was removed and the measurement result was reset. |
| `OXIMETER_BEAT,...,BUFFERING,...` | Collecting sensor values required for the SpO2 estimate. |
| `OXIMETER_BEAT,...,SKIPPED,...` | A candidate beat interval was outside the valid range and was excluded. |
| `OXIMETER_DATA,...,MEASURING` | An interim estimate. Keep the finger still. |
| `OXIMETER_DATA,...,RESULT` | The measurement result after eight accepted beat intervals. |
| `OXIMETER_DONE,...` | The duration ended. It reports the heart rate and SpO2 at that time. |
| `OXIMETER_ERROR,...` / `OXIMETER_WARN,...` | A problem occurred during sensor initialization or shutdown. |

Measurements use this format:

```text
OXIMETER_DATA,timestamp_ms,red,ir,bpm,spo2,MEASURING|RESULT
```

- `timestamp_ms`: Milliseconds since the board booted
- `red`, `ir`: Raw red-light and infrared readings
- `bpm`: Estimated beats per minute
- `spo2`: Estimated SpO2 (%)
- `MEASURING` / `RESULT`: Interim estimate or completed measurement

Continue holding the finger steadily if `SKIPPED` appears. If it repeats and no result appears, adjust the finger position, pressure, or ambient light.

## Estimation method and limitations

Beat detection uses an eight-sample IR moving average, a 50-sample baseline, and hysteresis-based threshold detection. Intervals from 350 to 1500 ms are valid, and the heart rate is calculated from the average of up to eight intervals. The finger threshold is an IR value of 20,000 with 3,000 counts of hysteresis.

The SpO2 estimate uses 100 red-light and 100 infrared samples. It derives a ratio of ratios from each channel's DC mean and AC standard deviation, then applies `110 - 25 × ((red_ac / red_dc) / (ir_ac / ir_dc))`, limited to 0–100%.

The coefficients in this calculation are not calibrated for this hardware. Movement, ambient light, sensor pressure, skin and circulation differences, LED current, and breakout-board characteristics can significantly affect the result. Compare results with an appropriately validated device when evaluating algorithm changes.

## File structure

| File | Role |
| --- | --- |
| `main.rb` | Owns hardware initialization, component composition, the measurement loop, and cleanup. |
| `lib/oximeter/config.rb` | Defines hardware, measurement, runtime, and LED-display settings together. |
| `lib/oximeter/board_clock.rb` | Provides board elapsed time and waiting to the application. |
| `lib/oximeter/console_logger.rb` | Writes runtime messages to the console. |
| `lib/oximeter/dispatcher.rb` | Registers subscribers and delivers events synchronously. |
| `lib/oximeter/sensor_factory.rb` | Initializes I2C and the MAX30102. |
| `lib/oximeter/measurement/` | Handles finger and beat detection, statistics, SpO2 estimation, and measurement sessions. |
| `lib/oximeter/measurement/processor.rb` | Accepts one sample, coordinates measurement processing, and publishes events. |
| `lib/oximeter/measurement/events.rb` | Defines measurement event names. |
| `lib/oximeter/status_led/` | Translates measurement events into display state and renders NeoPixels. |
| `test/main_test.rb` | Verifies `main.rb` component composition, measurement-loop execution, and cleanup. |
| `test/measurement_processor_test.rb` | Verifies measurement events and public class names. |
| `docs/pub_sub.md` | Explains the Pub/Sub implementation, event contract, and rationale. |
| `docs/tick.md` | Explains time-driven processing with `tick` and its implementation constraints. |
