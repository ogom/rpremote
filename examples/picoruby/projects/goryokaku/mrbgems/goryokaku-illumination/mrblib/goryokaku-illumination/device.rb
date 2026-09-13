# frozen_string_literal: true

require "ws2812-plus"

module Goryokaku
  module Illumination
    class Device
      attr_reader :display, :strip

      def initialize(strip: nil, pin: Config::LED_PIN, num: LedLayout::LED_COUNT)
        @strip = strip
        @pin = pin
        @num = num
        @display = nil
      end

      def open
        return self if @display
        @strip ||= WS2812.new(pin: @pin, num: @num, order: Config::LED_ORDER)
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
        @strip.clear if @strip
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

      def open?; !@display.nil?; end
    end
  end
end
