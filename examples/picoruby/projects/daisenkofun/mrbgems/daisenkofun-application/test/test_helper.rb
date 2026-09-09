# frozen_string_literal: true

require "picotest"

module Daisenkofun
  module Illumination
    module Config
      LED_PIN = 14
    end

    module Setlist
      def self.resolve(name)
        return [[:structure_guide, 1, 1]] if name == :highlights

        raise ArgumentError, "unknown setlist"
      end

      def self.valid_key?(key)
        key == :structure_guide
      end
    end
  end

  module Oximeter
    module Config
      RUN_DURATION_MS = 60_000
      I2C_SDA_PIN = 16
      I2C_SCL_PIN = 17
      SPI_SCK_PIN = 2
      SPI_COPI_PIN = 3
    end
  end
end

application_dir = File.expand_path("../mrblib/daisenkofun-application", __dir__)
require File.join(application_dir, "config")
require File.join(application_dir, "validator")
