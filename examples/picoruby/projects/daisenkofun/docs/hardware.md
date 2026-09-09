# Hardware and safety

[日本語](hardware.ja.md)

## Safety

Power the 572 LEDs with an external supply designed for the LEDs and wiring. Do not power them from a Raspberry Pi Pico 2 GPIO, `3V3(OUT)`, or `VBUS`. Connect the Pico 2 and LED supply grounds, and disconnect both power sources before changing wiring.

`BRIGHTNESS_PERCENT` in the illumination [`config.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/config.rb) sets the 572-LED strip brightness to 10%. The eight status LEDs use `Oximeter::Config::LED_BRIGHTNESS` (12). Check supply capacity, voltage drop, wiring, connectors, and temperatures before increasing either value.

## Wiring

### 572 illumination LEDs

| WS2812B | Connection |
| --- | --- |
| DIN | Pico 2 GP14 (physical pin 19, `ws2812_pin`) |
| GND | Ground shared by the Pico 2 and external LED supply |
| VDD | External supply appropriate for the LEDs |

Use a suitable level shifter if a 5 V LED does not reliably recognize the 3.3 V DIN signal.

### MAX30102

Connect the MAX30102 over I2C.

| MAX30102 | Raspberry Pi Pico 2 / `Application::Config` |
| --- | --- |
| VIN | Voltage accepted by the breakout board |
| GND | GND |
| SDA | GP16 / `i2c_sda_pin` |
| SCL | GP17 / `i2c_scl_pin` |

Confirm the breakout board's accepted input voltage and whether it includes I2C level shifting.

### PWM buzzer

Configure the WS2812, I2C, SPI, and buzzer pins with `Daisenkofun::Application::Config` in [`main.rb`](../main.rb). For audio in `:combined`, connect the PWM buzzer used in education example 03_speaker to GP18 (`buzzer_pin`) and common GND. Default duty is 3%. Change `buzzer_pin` to select another signal pin, or use `nil` for silence.

### Eight status LEDs

Connect the Oximeter status WS2812/NeoPixel LEDs over SPI.

| WS2812/NeoPixel | Raspberry Pi Pico 2 / `Application::Config` |
| --- | --- |
| DIN | GP3 (`RP2040_SPI0` COPI, `spi_copi_pin`) |
| GND | Ground shared by the Pico 2 and LED power supply |
| LED power | An external supply sized for eight LEDs |

GP2 (`spi_sck_pin`) is configured as SPI SCK but is not connected to the LEDs. Do not power LEDs from a GPIO. The SPI unit remains `RP2040_SPI0`; `Application::Config` changes its SCK and COPI pins, not the unit.
