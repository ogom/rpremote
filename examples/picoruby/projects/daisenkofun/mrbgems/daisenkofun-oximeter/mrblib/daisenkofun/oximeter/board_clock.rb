# frozen_string_literal: true

require "machine"

module Daisenkofun
  module Oximeter
    class BoardClock
      def millis
        Machine.board_millis
      end

      def wait_ms(milliseconds)
        sleep_ms milliseconds
      end
    end
  end
end
