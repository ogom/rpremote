# frozen_string_literal: true

module Goryokaku
  module Musical
    class TambourineDetector
      SHAKE_DURATION_MS = 100
      STRIKE_DURATION_MS = 120

      def initialize(
        application_mode:, axis_signs: [1, 1, 1], orientation_stable_ms: 100,
        shake_threshold: 0.2, shake_window_ms: 250, shake_reversals: 2, shake_retrigger_ms: 100,
        strike_threshold: 0.45, strike_release_threshold: 0.15, strike_retrigger_ms: 120
      )
        @enabled = application_mode == :musical
        @axis_signs = axis_signs
        @orientation_stable_ms = orientation_stable_ms
        @shake_threshold = shake_threshold
        @shake_window_ms = shake_window_ms
        @shake_reversals_required = shake_reversals
        @shake_retrigger_ms = shake_retrigger_ms
        @strike_threshold = strike_threshold
        @strike_release_threshold = strike_release_threshold
        @strike_retrigger_ms = strike_retrigger_ms
        reset
      end

      def on_event(event)
        type = event[0]
        return orientation_changed(event[1]) if type == :orientation_changed
        return mode_changed(event[1]) if type == :mode_changed
        return motion(event[1], event[2]) if type == :motion_sample

        nil
      end

      def reset
        @orientation = nil
        @y_up_since = nil
        @ready = false
        @previous_z = nil
        reset_shake
        @strike_armed = true
        @last_strike_ms = nil
      end

      private

      def orientation_changed(orientation)
        if orientation == :y_up
          @orientation = :y_up
          @y_up_since = nil
          @ready = false
        elsif orientation != :unknown
          was_active = @ready
          @orientation = orientation
          reset_motion
          return [:tambourine_inactive] if was_active
        end
        nil
      end

      def mode_changed(mode)
        enabled = mode == :tambourine
        return nil if enabled == @enabled

        @enabled = enabled
        reset_motion
        enabled ? nil : [:tambourine_inactive]
      end

      def motion(now, acceleration)
        transformed = transform(acceleration)
        unless active_at?(now)
          @previous_z = transformed[2]
          return nil
        end

        if !@ready
          @ready = true
          @previous_z = transformed[2]
          reset_shake
          return nil
        end

        strike = detect_strike(now, transformed[2])
        return strike if strike

        detect_shake(now, transformed[2])
      end

      def active_at?(now)
        return false unless @enabled && @orientation == :y_up

        @y_up_since ||= now
        now - @y_up_since >= @orientation_stable_ms
      end

      def detect_strike(now, z)
        jerk = @previous_z ? (z - @previous_z).abs : 0.0
        @previous_z = z
        @strike_armed = true if jerk < @strike_release_threshold
        return nil unless @strike_armed && jerk >= @strike_threshold
        return nil if @last_strike_ms && now - @last_strike_ms < @strike_retrigger_ms

        @strike_armed = false
        @last_strike_ms = now
        reset_shake
        [:tambourine_struck, now, intensity(jerk, @strike_threshold), STRIKE_DURATION_MS]
      end

      def detect_shake(now, z)
        return nil unless z.abs >= @shake_threshold

        sign = z < 0 ? -1 : 1
        if @shake_sign && sign != @shake_sign
          if @last_reversal_ms && now - @last_reversal_ms > @shake_window_ms
            @shake_reversals = 0
          end
          @shake_reversals += 1
          @last_reversal_ms = now
        end
        @shake_sign = sign
        return nil unless @shake_reversals >= @shake_reversals_required
        return nil if @last_shake_ms && now - @last_shake_ms < @shake_retrigger_ms

        @shake_reversals = 0
        @last_shake_ms = now
        direction = sign > 0 ? :right : :left
        [:tambourine_shaken, now, intensity(z.abs, @shake_threshold), direction, SHAKE_DURATION_MS]
      end

      def intensity(value, threshold)
        level = (value - threshold) / threshold
        level = 0.0 if level < 0.0
        level = 1.0 if level > 1.0
        level
      end

      def transform(acceleration)
        [
          acceleration[0] * @axis_signs[0],
          acceleration[1] * @axis_signs[1],
          acceleration[2] * @axis_signs[2]
        ]
      end

      def reset_motion
        @y_up_since = nil
        @ready = false
        @previous_z = nil
        reset_shake
        @strike_armed = true
      end

      def reset_shake
        @shake_sign = nil
        @shake_reversals = 0
        @last_reversal_ms = nil
        @last_shake_ms = nil
      end
    end
  end
end
