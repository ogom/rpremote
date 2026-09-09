# frozen_string_literal: true

module Daisenkofun
  module Application
    class Config
      attr_reader :mode, :setlist_name, :pattern_key, :repeat, :duration_ms, :buzzer_pin, :musical_style,
                  :ws2812_pin, :i2c_sda_pin, :i2c_scl_pin, :spi_sck_pin, :spi_copi_pin

      def initialize(
        mode: :combined, setlist_name: nil, pattern_key: nil, repeat: false,
        duration_ms: nil, buzzer_pin: 18, musical_style: :heartbeat_signature,
        ws2812_pin: Daisenkofun::Illumination::Config::LED_PIN,
        i2c_sda_pin: Daisenkofun::Oximeter::Config::I2C_SDA_PIN,
        i2c_scl_pin: Daisenkofun::Oximeter::Config::I2C_SCL_PIN,
        spi_sck_pin: Daisenkofun::Oximeter::Config::SPI_SCK_PIN,
        spi_copi_pin: Daisenkofun::Oximeter::Config::SPI_COPI_PIN
      )
        @mode = mode
        @setlist_name = setlist_name
        @pattern_key = pattern_key
        @repeat = repeat
        @duration_ms = duration_ms
        @buzzer_pin = buzzer_pin
        @musical_style = musical_style
        @ws2812_pin = ws2812_pin
        @i2c_sda_pin = i2c_sda_pin
        @i2c_scl_pin = i2c_scl_pin
        @spi_sck_pin = spi_sck_pin
        @spi_copi_pin = spi_copi_pin

        @setlist_name = :highlights if illumination? && !@setlist_name && !@pattern_key
        if !illumination? && @duration_ms.nil?
          @duration_ms = Daisenkofun::Oximeter::Config::RUN_DURATION_MS
        end
      end

      def illumination?
        @mode == :illumination
      end

      def combined?
        @mode == :combined
      end
    end
  end
end
