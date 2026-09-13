# frozen_string_literal: true
module Goryokaku
  module Interaction
    class Detector
      def initialize(vertical_threshold:, horizontal_threshold:)
        @vertical_threshold = vertical_threshold
        @horizontal_threshold = horizontal_threshold
        @touch_state = 1
        @orientation = nil
      end

      def prime(acceleration)
        orientation_event(acceleration)
      end

      def detect(touch_state, acceleration)
        events = []
        event = orientation_event(acceleration)
        events << event if event
        events << [:touch_pressed] if touch_state == 0 && @touch_state == 1
        @touch_state = touch_state
        events
      end

      private

      def orientation_event(acceleration)
        ax = acceleration[0]
        ay = acceleration[1]
        az = acceleration[2]
        orientation = nil
        orientation = :z_up if az > @horizontal_threshold
        orientation = :y_up if !orientation && ay > @vertical_threshold
        orientation = :x_up if !orientation && ax > @vertical_threshold
        orientation ||= :unknown
        return nil if orientation == @orientation
        @orientation = orientation
        [:orientation_changed, orientation]
      end

    end
  end
end
