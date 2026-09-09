# frozen_string_literal: true

module Daisenkofun
  module Application
    class Validator
      MODES = [:illumination, :oximeter, :combined]
      MUSICAL_STYLES = [:pulse_translation, :kofun_canon, :heartbeat_signature]

      def validate(config)
        unless MODES.include?(config.mode)
          raise ArgumentError, "mode must be :illumination, :oximeter, or :combined"
        end
        unless MUSICAL_STYLES.include?(config.musical_style)
          raise ArgumentError, "musical_style must be :pulse_translation, :kofun_canon, or :heartbeat_signature"
        end
        validate_pin(:ws2812_pin, config.ws2812_pin)
        validate_pin(:i2c_sda_pin, config.i2c_sda_pin)
        validate_pin(:i2c_scl_pin, config.i2c_scl_pin)
        validate_pin(:spi_sck_pin, config.spi_sck_pin)
        validate_pin(:spi_copi_pin, config.spi_copi_pin)

        config.illumination? ? validate_illumination(config) : validate_measurement(config)
        config
      end

      private

      def validate_pin(name, pin)
        raise ArgumentError, "#{name} must be a non-negative Integer" unless pin.is_a?(Integer) && pin >= 0
      end

      def validate_illumination(config)
        unless config.repeat == true || config.repeat == false
          raise ArgumentError, "repeat must be true or false"
        end
        if config.setlist_name && config.pattern_key
          raise ArgumentError, "setlist_name and pattern_key are mutually exclusive"
        end
        if config.duration_ms
          raise ArgumentError, "duration_ms is only valid for mode :oximeter or :combined"
        end

        Daisenkofun::Illumination::Setlist.resolve(config.setlist_name) if config.setlist_name
        if config.pattern_key && !Daisenkofun::Illumination::Setlist.valid_key?(config.pattern_key)
          raise ArgumentError, "pattern_key must name a registered pattern"
        end
      end

      def validate_measurement(config)
        if config.setlist_name || config.pattern_key
          raise ArgumentError, "setlist_name and pattern_key are only valid for mode :illumination"
        end
        unless config.duration_ms.is_a?(Integer) && config.duration_ms > 0
          raise ArgumentError, "duration_ms must be a positive Integer"
        end
      end
    end
  end
end
