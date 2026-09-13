# frozen_string_literal: true

module Goryokaku
  module Musical
    class GesturePublisher
      def initialize(detector:, dispatcher:)
        @detector = detector
        @dispatcher = dispatcher
      end

      def start; self; end

      def on_event(event)
        gesture = @detector.on_event(event)
        @dispatcher.publish(gesture) if gesture
      end

      def tick(_now); end
      def stop; @detector.reset; end
    end
  end
end
