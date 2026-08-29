# picoruby-hcsr04_temp

`picoruby-hcsr04_temp` provides the `HCSR04Temp` C-extension driver for an HC-SR04 ultrasonic distance sensor. Timing-sensitive trigger generation, ECHO polling, and distance calculation run in C.

## Safety

Raspberry Pi Pico 2 GPIO pins use 3.3 V logic. Do not connect the HC-SR04 ECHO pin directly to a Pico GPIO pin because the sensor outputs a 5 V signal. Lower the ECHO signal to 3.3 V with a voltage divider or a level shifter.

Connect the grounds of the Pico and the sensor. Supply the sensor with the voltage specified for your HC-SR04 module.

## Wiring

The following example uses GP16 for TRIG and GP17 for ECHO.

| HC-SR04 | Connection |
| --- | --- |
| VCC | Power supply specified for the module |
| GND | Pico GND and power-supply GND |
| TRIG | Pico GP16 |
| ECHO | Voltage divider or level shifter -> Pico GP17 |

## Usage

Add the mrbgem to `Mrbgems`.

```ruby
gem path: "examples/picoruby/mrbgems/hcsr04_temp"
```

Create the GPIO objects and pass them to `HCSR04Temp`.

```ruby
require "gpio"
require "hcsr04_temp"

trigger = GPIO.new(16, GPIO::OUT)
echo = GPIO.new(17, GPIO::IN)
sensor = HCSR04Temp.new(trigger: trigger, echo: echo, temperature_c: 20.0)

loop do
  result = sensor.read
  puts "Distance: #{result[:distance_cm].round(1)} cm"
  sleep 1
end
```

`read` performs one measurement and returns the pulse width and distance.

```ruby
{
  pulse_width_us: 1_000,
  distance_cm: 17.175,
  distance_mm: 171.75
}
```

Set `temperature_c` to the air temperature in degrees Celsius. The distance calculation compensates for the speed of sound using `331.5 + 0.6 × temperature_c` m/s. The default is 20 °C.

Before the first measurement, the driver keeps TRIG Low for 20 ms. The minimum interval between subsequent trigger pulses is 60 ms. The default ECHO timeout is 30 ms. `HCSR04Temp::TimeoutError` is raised when the sensor does not return an ECHO pulse.

Air temperature, the target material and angle, wiring, and the sensor module affect the result. Calibrate the value in the application when measurement accuracy matters.

## License

[MIT License](LICENSE)
