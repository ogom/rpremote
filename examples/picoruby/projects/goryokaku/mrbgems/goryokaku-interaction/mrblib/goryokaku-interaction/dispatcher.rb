# frozen_string_literal: true
module Goryokaku
  module Interaction
    class Dispatcher
      def initialize; @subscribers = []; end
      def subscribe(subscriber); @subscribers << subscriber; self; end
      def publish(event)
        index = 0
        while index < @subscribers.length
          @subscribers[index].on_event(event)
          index += 1
        end
      end
    end
  end
end
