# frozen_string_literal: true

require "daisenkofun-application"
require "dfu"

config = Daisenkofun::Application::Config.new(
  mode: :illumination, # :illumination, :oximeter, or :combined
  setlist_name: :story, # :tests, :highlights, :story, or :showcase
  pattern_key: nil,
  repeat: false,
  duration_ms: nil, #60_000
  ws2812_pin: 14,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  spi_sck_pin: 2,
  spi_copi_pin: 3,
  buzzer_pin: 18, # nil selects silent output
  buzzer_volume: 3, # master duty percentage; 0 selects silent output
  musical_style: :heartbeat_signature # :pulse_translation, :kofun_canon, or :heartbeat_signature
)

Daisenkofun::Application::Runner.new(config: config).call
