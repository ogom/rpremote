# Hardware and safety

[日本語](hardware.ja.md)

## Safety

Power the 572 LEDs with an external supply designed for the LEDs and wiring. Do not power them from a Raspberry Pi Pico 2 GPIO, `3V3(OUT)`, or `VBUS`. Connect the Pico 2 and LED supply grounds, and disconnect both power sources before changing wiring.

`BRIGHTNESS_PERCENT` in [`config.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb) sets the brightness. Check supply capacity, voltage drop, wiring, connectors, and temperatures before increasing it.

## Wiring

### 572 illumination LEDs

| WS2812B | Connection |
| --- | --- |
| DIN | Pico 2 GP14 (physical pin 19) |
| GND | Ground shared by the Pico 2 and external LED supply |
| VDD | External supply appropriate for the LEDs |

Use a suitable level shifter if a 5 V LED does not reliably recognize the 3.3 V DIN signal.

### MAX30102

Connect the MAX30102 over I2C.

| MAX30102 | Raspberry Pi Pico 2 |
| --- | --- |
| VIN | Voltage accepted by the breakout board |
| GND | GND |
| SDA | GP16 |
| SCL | GP17 |

Confirm the breakout board's accepted input voltage and whether it includes I2C level shifting.

### Eight status LEDs

Connect the Oximeter status WS2812/NeoPixel LEDs over SPI.

| WS2812/NeoPixel | Raspberry Pi Pico 2 |
| --- | --- |
| DIN | GP3 (`RP2040_SPI0` COPI) |
| GND | Ground shared by the Pico 2 and LED power supply |
| LED power | An external supply sized for eight LEDs |

GP2 is configured as SPI SCK but is not connected to the LEDs. Do not power LEDs from a GPIO.
