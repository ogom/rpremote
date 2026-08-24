# frozen_string_literal: true

require "my_gems"

LED_PIN = 25
CYCLES = 5
INTERVAL_MS = 500

led = MyGems.new(pin: LED_PIN)

CYCLES.times do |index|
  led.led_on
  puts "my_gems: LED ON (#{index + 1}/#{CYCLES})"
  sleep_ms(INTERVAL_MS)

  led.led_off
  puts "my_gems: LED OFF (#{index + 1}/#{CYCLES})"
  sleep_ms(INTERVAL_MS)
end

led.led_off
puts "my_gems: OK"
