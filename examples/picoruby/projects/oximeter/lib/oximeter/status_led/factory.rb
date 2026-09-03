# frozen_string_literal: true

require "spi"
require "ws2812_spi"
require "/lib/oximeter/config"
require "/lib/oximeter/status_led/renderer"

module Oximeter
  module StatusLed
    class Factory
      def call
        spi = SPI.new(
          unit: Config::SPI_UNIT,
          frequency: WS2812SPI::FREQUENCY,
          sck_pin: Config::SPI_SCK_PIN,
          copi_pin: Config::SPI_COPI_PIN,
          mode: WS2812SPI::MODE
        )
        pixels = WS2812SPI.new(spi: spi, count: Config::LED_COUNT)
        Renderer.new(pixels)
      end
    end
  end
end
