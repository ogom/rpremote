# frozen_string_literal: true

require "daisenkofun-application"
require "dfu"

config = Daisenkofun::Application::Config.new(
  mode: :combined, # :illumination, :oximeter, or :combined
  setlist_name: nil, # :tests, :highlights, :story, or :showcase
  pattern_key: nil,
  repeat: false,
  duration_ms: 60_000,
  ws2812_pin: 14,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  spi_sck_pin: 2,
  spi_copi_pin: 3,
  buzzer_pin: 18, # nil selects silent output
  musical_style: :heartbeat_signature # :pulse_translation, :kofun_canon, or :heartbeat_signature
)

Daisenkofun::Application::Runner.new(config: config).call
