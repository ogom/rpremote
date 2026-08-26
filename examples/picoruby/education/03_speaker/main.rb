# frozen_string_literal: true

require "pwm"

SWITCH_PIN = 15
BUZZER_PIN = 18
TONE_FREQUENCY_HZ = 1_000
TONE_DURATION_MS = 200
VOLUME_PERCENT = 3

switch = GPIO.new(SWITCH_PIN, GPIO::IN | GPIO::PULL_UP)
buzzer = PWM.new(BUZZER_PIN, frequency: TONE_FREQUENCY_HZ, duty: 0)
buzzer.duty(0)

def beep(buzzer, frequency_hz = TONE_FREQUENCY_HZ, duration_ms = TONE_DURATION_MS)
  buzzer.frequency(frequency_hz)
  buzzer.duty(VOLUME_PERCENT)
  sleep_ms(duration_ms)
  buzzer.duty(0)
end

puts "スイッチを押してください。Ctrl-Cで停止します"

begin
  loop do
    if switch.low?
      beep(buzzer)
      puts "ピッ！"

      # Wait for release so one press produces one beep.
      sleep_ms(10) while switch.low?
      sleep_ms(50)
    else
      sleep_ms(10)
    end
  end
ensure
  buzzer.duty(0)
  puts "停止しました"
end
