# frozen_string_literal: true

class MyGems
  def initialize(pin:)
    @led = GPIO.new(pin, GPIO::OUT)
  end

  def led_on
    @led.write(1)
  end

  def led_off
    @led.write(0)
  end

  def led_loop
    loop do
      puts "led on"
      led_on
      sleep 1
      puts "led off"
      led_off
      sleep 1
    end
  end
end
