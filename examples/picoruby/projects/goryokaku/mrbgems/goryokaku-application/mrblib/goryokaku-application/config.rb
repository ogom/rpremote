# frozen_string_literal: true

module Goryokaku
  module Application
    class Config
      attr_reader :mode, :setlist_name, :pattern_key, :repeat,
                  :led_pin, :led_count, :touch_pin, :buzzer_pin, :buzzer_volume,
                  :i2c_unit, :i2c_frequency, :i2c_sda_pin, :i2c_scl_pin,
                  :vertical_threshold, :horizontal_threshold,
                  :poll_interval_ms, :heartbeat_interval_ms,
                  :musical_axis_signs, :orientation_stable_ms,
                  :shake_threshold, :shake_window_ms, :shake_reversals, :shake_retrigger_ms,
                  :strike_threshold, :strike_release_threshold, :strike_retrigger_ms

      def initialize(
        mode: :illumination, setlist_name: nil, pattern_key: nil, repeat: false,
        led_pin: 14, led_count: Goryokaku::Illumination::LedLayout::LED_COUNT,
        touch_pin: 21, buzzer_pin: 18, buzzer_volume: 1,
        i2c_unit: :RP2040_I2C0, i2c_frequency: 400_000,
        i2c_sda_pin: 16, i2c_scl_pin: 17,
        vertical_threshold: 0.7, horizontal_threshold: 0.7, poll_interval_ms: 20,
        musical_axis_signs: [1, 1, 1], orientation_stable_ms: 100,
        shake_threshold: 0.2, shake_window_ms: 250, shake_reversals: 2, shake_retrigger_ms: 100,
        strike_threshold: 0.45, strike_release_threshold: 0.15, strike_retrigger_ms: 120,
        heartbeat_interval_ms: 5_000, heartbeat_interval: nil
      )
        @mode = mode
        @setlist_name = setlist_name
        @pattern_key = pattern_key
        @repeat = repeat
        @led_pin = led_pin
        @led_count = led_count
        @touch_pin = touch_pin
        @buzzer_pin = buzzer_pin
        @buzzer_volume = buzzer_volume
        @i2c_unit = i2c_unit
        @i2c_frequency = i2c_frequency
        @i2c_sda_pin = i2c_sda_pin
        @i2c_scl_pin = i2c_scl_pin
        @vertical_threshold = vertical_threshold
        @horizontal_threshold = horizontal_threshold
        @poll_interval_ms = poll_interval_ms
        @musical_axis_signs = musical_axis_signs
        @orientation_stable_ms = orientation_stable_ms
        @shake_threshold = shake_threshold
        @shake_window_ms = shake_window_ms
        @shake_reversals = shake_reversals
        @shake_retrigger_ms = shake_retrigger_ms
        @strike_threshold = strike_threshold
        @strike_release_threshold = strike_release_threshold
        @strike_retrigger_ms = strike_retrigger_ms
        @heartbeat_interval_ms = heartbeat_interval ? heartbeat_interval * poll_interval_ms : heartbeat_interval_ms
        if (illumination? || combined?) && !@setlist_name && !@pattern_key
          @setlist_name = :highlights
        end
      end

      def illumination?; @mode == :illumination; end
      def musical?; @mode == :musical; end
      def combined?; @mode == :combined; end
    end
  end
end
