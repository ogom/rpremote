# frozen_string_literal: true

require "machine"

module Goryokaku
  module Runtime
    class Clock
      def millis; Machine.board_millis; end
      def wait_ms(milliseconds); sleep_ms milliseconds; end
    end
  end
end
