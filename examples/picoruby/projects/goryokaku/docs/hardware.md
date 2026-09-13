# Hardware and safety

[日本語](hardware.ja.md)

## Wiring

| Component | Signal | Raspberry Pi Pico 2 |
| --- | --- | --- |
| WS2812B | DIN | GP14 |
| Touch switch | Output | GP21 (internal pull-up, connects to GND when pressed) |
| PWM buzzer/amplifier | Signal | GP18 |
| MPU6050 | SDA | GP16 |
| MPU6050 | SCL | GP17 |
| MPU6050 | VCC | 3V3(OUT) |
| All components | GND | Common ground |

The defaults in `main.rb` and `Goryokaku::Application::Config` match this pin assignment. Change the values passed to the configuration when the wiring differs.

Mount the MPU6050 so the model face is horizontal in display Z-up and star group 5 is at the top in performance Y-up. Performance uses Z for both the shake travel and strikes perpendicular to the model face, distinguishing smooth reversals from sharp jerk.

## LED power

Do not power 380 WS2812B LEDs from a Pico 2 GPIO or 3V3(OUT). Use an external 5 V supply suitable for the LEDs and simultaneous-lighting conditions, and connect its ground to the Pico 2 ground. Check wire current capacity, voltage drop, power-injection points, connectors, fusing, and temperature as well as the supply rating.

A conservative design case of 60 mA per LED at maximum white is 22.8 A for 380 LEDs. Actual consumption depends on the specific LEDs and effect brightness; use the LED data sheet and measured current as the authority.

A 3.3 V-to-5 V logic-level shifter is recommended for LEDs powered at 5 V. Follow the LED product's recommended circuit for a series data resistor and bulk supply capacitor.

## Operating precautions

- Disconnect USB and LED power before changing wiring.
- Do not apply 5 V to the MPU6050 I2C signals.
- Do not draw high speaker or buzzer current directly from a GPIO. Use an amplifier or driver when required.
- For the first run, use a short effect while monitoring LED current.
