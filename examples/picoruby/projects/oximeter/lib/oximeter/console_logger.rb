# frozen_string_literal: true

module Oximeter
  class ConsoleLogger
    def puts(message)
      print "#{message}\n"
    end
  end
end
