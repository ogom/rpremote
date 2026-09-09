# frozen_string_literal: true

require "ws2812-plus"

module Daisenkofun
  module Illumination
    class Device
      attr_reader :display, :strip

      def initialize(strip: nil, pin: Config::LED_PIN)
        @strip = strip
        @pin = pin
        @display = nil
      end

      def open
        return self if @display

        @strip ||= WS2812.new(pin: @pin, num: LedLayout::LED_COUNT, order: Config::LED_ORDER)
        begin
          @strip.brightness = Config::BRIGHTNESS_PERCENT
          @display = Display.new(@strip)
        rescue
          close
          raise
        end
        self
      end

      def clear
        return self unless @strip

        @strip.clear
        self
      end

      def close
        return self unless @strip

        strip = @strip
        @strip = nil
        @display = nil
        begin
          strip.clear
        ensure
          strip.close
        end
        self
      end

      def open?
        !@display.nil?
      end
    end
  end
end
