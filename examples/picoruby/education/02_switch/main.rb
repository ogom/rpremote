# frozen_string_literal: true

LED_PIN = 25
SWITCH_PIN = 15
SAMPLES = 200
POLL_INTERVAL_MS = 50

led = GPIO.new(LED_PIN, GPIO::OUT)
switch = GPIO.new(SWITCH_PIN, GPIO::IN | GPIO::PULL_UP)
last_state = nil

SAMPLES.times do
  state = switch.low?
  if state != last_state
    led.write(state ? 1 : 0)
    puts(state ? 'LED ON' : 'LED OFF')
    last_state = state
  end
  sleep_ms(POLL_INTERVAL_MS)
end

led.write(0)
puts 'switch: OK'
