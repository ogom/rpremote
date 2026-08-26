# frozen_string_literal: true

led_pin = 25
cycles = 5
interval_ms = 500

led = GPIO.new(led_pin, GPIO::OUT)

cycles.times do |index|
  led.write(1)
  puts "Hello World! LED ON (#{index + 1}/#{cycles})"
  sleep_ms(interval_ms)
  led.write(0)
  puts "Hello World! LED OFF (#{index + 1}/#{cycles})"
  sleep_ms(interval_ms)
end

puts 'blink: OK'
