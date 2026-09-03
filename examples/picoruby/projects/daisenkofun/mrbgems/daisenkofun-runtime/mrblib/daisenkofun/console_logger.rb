# frozen_string_literal: true

module Daisenkofun
  class ConsoleLogger
    def puts(message)
      print "#{message}\n"
    end
  end
end
