# frozen_string_literal: true

require 'dfu'

APP_VERSION = '3.0.0-broken'
LED_PIN = 25

puts "classroom beacon: starting v#{APP_VERSION}"

led = GPIO.new(LED_PIN, GPIO::OUT)
led.write(0)

# Simulate a failed device self-check: leave outputs safe and omit DFU.confirm so R2P2 can roll back while its Shell remains available.
puts 'classroom beacon: startup self-check failed; update not confirmed'
