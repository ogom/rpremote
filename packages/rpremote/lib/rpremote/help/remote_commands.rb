# frozen_string_literal: true

module Rpremote
  module Help
    def self.ports_text
      "Usage: #{COMMAND_USAGE.fetch(:ports)}\n\nPrints each detected R2P2 CDC 0 serial path, one per line. It does not connect to a board.\n"
    end

    def self.run_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:run)}

        Uploads FILE to R2P2, or main.rb when FILE is a directory, relays output, then removes the temporary remote file. Defaults are the automatic CDC 0 port,
        115200 baud, a 20-second idle timeout, and picoruby. Output from the running program resets the idle timeout.
        It exits nonzero when compatible R2P2 firmware reports a Ruby exception.
        --reset-on-timeout resets R2P2 after the run times out and the serial connection has closed.
      HELP
    end

    def self.exec_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:exec)}

        Runs short Ruby CODE through a temporary remote file, then removes it. Defaults are the automatic CDC 0 port,
        115200 baud, a 20-second idle timeout, and picoruby. Output from the running program resets the idle timeout.
        It exits nonzero when compatible R2P2 firmware reports a Ruby exception.
      HELP
    end

    def self.monitor_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:monitor)}

        Opens a serial monitor for the selected CDC 0 port. Defaults are 115200 baud and 20 seconds; exit with Ctrl-].
      HELP
    end

    def self.repl_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:repl)}

        Opens PicoIRB on the selected CDC 0 port. Defaults are 115200 baud and 20 seconds; exit with Ctrl-].
      HELP
    end

    def self.reset_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:reset)}

        Reboots R2P2 and waits for reconnection. Defaults are the automatic CDC 0 port, 115200 baud, and 20 seconds.
      HELP
    end
  end
end
