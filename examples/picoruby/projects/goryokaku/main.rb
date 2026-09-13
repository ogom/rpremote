# frozen_string_literal: true

require "goryokaku-application"
require "dfu"

config = Goryokaku::Application::Config.new(
  mode: :illumination, # :illumination, :musical, or :combined
  setlist_name: :highlights, # :tests, :highlights, :story, or :showcase (illumination/combined only)
  pattern_key: nil,
  repeat: false,
  led_pin: 14,
  led_count: 380,
  touch_pin: 21,
  buzzer_pin: 18,
  buzzer_volume: 0.02,
  i2c_unit: :RP2040_I2C0,
  i2c_frequency: 400_000,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  shake_threshold: 0.2,
  strike_threshold: 0.45,
  strike_release_threshold: 0.15,
  poll_interval_ms: 20
)

Goryokaku::Application::Runner.new(config: config).call
