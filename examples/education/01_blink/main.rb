# frozen_string_literal: true

LED_PIN = 25
CYCLES = 5
INTERVAL_MS = 500

led = GPIO.new(LED_PIN, GPIO::OUT)

CYCLES.times do |index|
  led.write(1)
  puts "Hello World! LED ON (#{index + 1}/#{CYCLES})"
  sleep_ms(INTERVAL_MS)
  led.write(0)
  puts "Hello World! LED OFF (#{index + 1}/#{CYCLES})"
  sleep_ms(INTERVAL_MS)
end

puts 'blink: OK'
