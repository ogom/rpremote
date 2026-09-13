# frozen_string_literal: true

module Goryokaku
  module Application
    class Validator
      def initialize(config); @config = config; end

      def validate
        unless @config.illumination? || @config.musical? || @config.combined?
          raise ArgumentError, "mode must be :illumination, :musical, or :combined"
        end
        unless @config.repeat == true || @config.repeat == false
          raise ArgumentError, "repeat must be true or false"
        end
        if @config.setlist_name && @config.pattern_key
          raise ArgumentError, "setlist_name and pattern_key are mutually exclusive"
        end
        Goryokaku::Illumination::Setlist.resolve(@config.setlist_name) if @config.setlist_name
        if @config.illumination?
          if @config.pattern_key && !Goryokaku::Illumination::Setlist.valid_key?(@config.pattern_key)
            raise ArgumentError, "pattern_key must name a registered pattern"
          end
        elsif @config.combined? && (@config.pattern_key || @config.repeat)
          raise ArgumentError, "pattern_key and repeat are only valid for mode :illumination"
        elsif @config.musical? && (@config.setlist_name || @config.pattern_key || @config.repeat)
          raise ArgumentError, "setlist_name, pattern_key, and repeat are not valid for mode :musical"
        end
        positive_integer!(:led_count, @config.led_count)
        if @config.led_count < Goryokaku::Illumination::LedLayout::LED_COUNT
          raise ArgumentError, "led_count must cover the physical LED layout"
        end
        positive_integer!(:poll_interval_ms, @config.poll_interval_ms)
        positive_integer!(:heartbeat_interval_ms, @config.heartbeat_interval_ms)
        validate_musical
        true
      end

      private

      def positive_integer!(name, value)
        return if value.is_a?(Integer) && value > 0
        raise ArgumentError, "#{name} must be positive"
      end

      def validate_musical
        unless valid_axis_signs?
          raise ArgumentError, "musical_axis_signs must contain three values of 1 or -1"
        end
        positive_integer!(:orientation_stable_ms, @config.orientation_stable_ms)
        positive_integer!(:shake_window_ms, @config.shake_window_ms)
        positive_integer!(:shake_reversals, @config.shake_reversals)
        positive_integer!(:shake_retrigger_ms, @config.shake_retrigger_ms)
        positive_integer!(:strike_retrigger_ms, @config.strike_retrigger_ms)
        positive_number!(:shake_threshold, @config.shake_threshold)
        positive_number!(:strike_threshold, @config.strike_threshold)
        positive_number!(:strike_release_threshold, @config.strike_release_threshold)
        return if @config.strike_release_threshold < @config.strike_threshold

        raise ArgumentError, "strike_release_threshold must be lower than strike_threshold"
      end

      def positive_number!(name, value)
        return if (value.is_a?(Integer) || value.is_a?(Float)) && value > 0

        raise ArgumentError, "#{name} must be positive"
      end

      def valid_axis_signs?
        signs = @config.musical_axis_signs
        return false unless signs.is_a?(Array) && signs.length == 3

        index = 0
        while index < signs.length
          return false unless signs[index] == 1 || signs[index] == -1
          index += 1
        end
        true
      end
    end
  end
end
