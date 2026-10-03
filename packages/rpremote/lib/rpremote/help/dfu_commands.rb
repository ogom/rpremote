# frozen_string_literal: true

module Rpremote
  module Help
    def self.dfu_text(subcommand)
      return dfu_app_text if subcommand == "app"
      return dfu_compile_text if subcommand == "compile"
      return dfu_status_text if subcommand == "status"
      return dfu_remove_text if subcommand == "remove"

      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:dfu_app)}
               #{COMMAND_USAGE.fetch(:dfu_compile)}
               #{COMMAND_USAGE.fetch(:dfu_status)}
               #{COMMAND_USAGE.fetch(:dfu_remove)}

        Stages and inspects PicoModem DFU applications. Run `rpremote dfu SUBCOMMAND --help` for details.
      HELP
    end

    def self.dfu_app_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:dfu_app)}

        Transfers a Ruby source or matching RITE bytecode application to the inactive DFU slot. The next R2P2 restart tries it.
        Options default to the configured or automatically selected CDC 0 port, 115200 baud, and 20 seconds.
        The transfer changes the staged boot application; use `rpremote reset` to restart and require DFU.confirm after a successful boot.
      HELP
    end

    def self.dfu_compile_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:dfu_compile)}

        Compiles Ruby source to bytecode that matches the selected PicoRuby version. The output defaults beside FILE.
        It requires prepared PicoRuby source and does not connect to a board.
      HELP
    end

    def self.dfu_status_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:dfu_status)}

        Prints the active and candidate DFU A/B slots. Defaults are the configured or automatically selected CDC 0 port,
        115200 baud, and 20 seconds. This command reads board state without changing it.
      HELP
    end

    def self.dfu_remove_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:dfu_remove)}

        Permanently removes the Ruby source and bytecode applications from both DFU A/B slots and resets their metadata.
        Run `rpremote reset` afterward to stop the application already running in RAM. It does not remove /home/app.rb,
        /home/app.mrb, other files, embedded mrbgems, or R2P2 firmware.
      HELP
    end
  end
end
