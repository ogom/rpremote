# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    class Dispatcher
      def initialize
        @subscribers = []
      end

      def subscribe(subscriber)
        @subscribers << subscriber
        self
      end

      def publish(event, payload)
        index = 0
        while index < @subscribers.length
          @subscribers[index].call(event, payload)
          index += 1
        end
        self
      end
    end
  end
end
