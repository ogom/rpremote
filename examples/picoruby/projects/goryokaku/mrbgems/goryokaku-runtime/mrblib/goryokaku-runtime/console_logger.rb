# frozen_string_literal: true

module Goryokaku
  module Runtime
    class ConsoleLogger
      def puts(message); print "#{message}\n"; end
    end
  end
end
