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
rpremote run examples/picoruby/projects/oximeter/main.rb --timeout 70
```

`fs push` copies the application classes to R2P2's `/lib/oximeter`. Run it again after changing a file in local `lib/oximeter`.

The application runs for 60 seconds, then shuts down the MAX30102 and turns off the LEDs. To change that duration, edit `RUN_DURATION_MS` in `lib/oximeter/config.rb`. Set `rpremote run --timeout` longer than the application duration.

## How to use it

1. Run the application and wait for a dim white point to appear on the LEDs.
2. Rest a fingertip lightly on the MAX30102 sensor surface.
3. When the LEDs change to the blue measuring display, keep the finger still and in place.
4. When the serial log prints `OXIMETER_DATA,...,RESULT`, check the estimated heart rate and SpO2.

Removing the finger during measurement resets the result and returns the application to the waiting state. Place the fingertip steadily on the sensor again to restart the measurement.

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
| `main.rb` | Initializes the hardware and manages the application duration and shutdown. |
| `lib/oximeter/config.rb` | Defines wiring, sampling, detection, and display settings. |
| `lib/oximeter/rolling_statistics.rb` | Stores samples and calculates averages and standard deviations. |
| `lib/oximeter/monitor.rb` | Detects fingers and beats, then estimates heart rate and SpO2. |
| `lib/oximeter/status_leds.rb` | Controls the NeoPixel status display. |
