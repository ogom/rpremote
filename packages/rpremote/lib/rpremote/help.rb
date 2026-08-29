# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength, Metrics/CyclomaticComplexity

module Rpremote
  module Help
    COMMAND_USAGE = {
      setup: "rpremote setup [--language LANGUAGE] [--language-version VERSION] [--force] [--cache DIR]",
      build: "rpremote build [--language LANGUAGE] [--language-version VERSION] [--board BOARD] " \
             "[--firmware FILE] [--cache DIR] [--mrbgems FILE|--no-mrbgems]",
      build_clean: "rpremote build clean",
      bootsel: "rpremote bootsel [--reset-flash-memory] [--mount DIR] [--port PORT] [--baud RATE] [--timeout SEC]",
      deploy: "rpremote deploy PATH [--language LANGUAGE] [--language-version VERSION] [--board BOARD] " \
              "[--firmware FILE] [--cache DIR] [--mrbgems FILE|--no-mrbgems] [--mount DIR] " \
              "[--port PORT] [--baud RATE] [--timeout SEC]",
      dfu_app: "rpremote dfu app FILE [--type ruby|rite] [--port PORT] [--baud RATE] [--timeout SEC]",
      dfu_compile: "rpremote dfu compile FILE [--output FILE] [--language LANGUAGE] [--language-version VERSION] [--cache DIR]",
      dfu_status: "rpremote dfu status [--port PORT] [--baud RATE] [--timeout SEC]",
      dfu_remove: "rpremote dfu remove [--port PORT] [--baud RATE] [--timeout SEC]",
      mrbgems: "rpremote mrbgems SUBCOMMAND [--file FILE] [--lockfile FILE]",
      flash: "rpremote flash [--firmware FILE] [--language LANGUAGE] [--language-version VERSION] " \
             "[--board BOARD] [--cache DIR] [--mount DIR] [--port PORT] [--timeout SEC]",
      config_show: "rpremote config show [--language LANGUAGE] [--language-version VERSION] [--board BOARD] " \
                   "[--cache DIR] [--firmware FILE] [--mrbgems FILE|--no-mrbgems] [--mount DIR] " \
                   "[--port PORT] [--baud RATE] [--timeout SEC]",
      ports: "rpremote ports",
      run: "rpremote run FILE [--port PORT] [--baud RATE] [--timeout SEC] [--reset-on-timeout] [--language LANGUAGE]",
      monitor: "rpremote monitor [--port PORT] [--baud RATE] [--timeout SEC]",
      repl: "rpremote repl [--port PORT] [--baud RATE] [--timeout SEC]",
      exec: "rpremote exec CODE [--port PORT] [--baud RATE] [--timeout SEC] [--language LANGUAGE]",
      reset: "rpremote reset [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_cp: "rpremote fs cp SOURCE DESTINATION [--recursive] [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_push: "rpremote fs push LOCAL_DIR :/REMOTE_DIR [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_cat: "rpremote fs cat :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_ls: "rpremote fs ls :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_rm: "rpremote fs rm :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_mkdir: "rpremote fs mkdir :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]"
    }.freeze

    TEXT = <<~HELP.freeze
      rpremote - R2P2 remote control for Raspberry Pi Pico 2

      Usage:
        #{COMMAND_USAGE.fetch(:setup)}
        #{COMMAND_USAGE.fetch(:build)}
        #{COMMAND_USAGE.fetch(:build_clean)}
        #{COMMAND_USAGE.fetch(:bootsel)}
        #{COMMAND_USAGE.fetch(:deploy)}
        #{COMMAND_USAGE.fetch(:dfu_app)}
        #{COMMAND_USAGE.fetch(:dfu_compile)}
        #{COMMAND_USAGE.fetch(:dfu_status)}
        #{COMMAND_USAGE.fetch(:dfu_remove)}
        #{COMMAND_USAGE.fetch(:mrbgems).sub("SUBCOMMAND", "check|list|lock|update")}
        #{COMMAND_USAGE.fetch(:flash)}
        #{COMMAND_USAGE.fetch(:config_show)}
        #{COMMAND_USAGE.fetch(:ports)}
        #{COMMAND_USAGE.fetch(:run)}
        #{COMMAND_USAGE.fetch(:monitor)}
        #{COMMAND_USAGE.fetch(:repl)}
        #{COMMAND_USAGE.fetch(:exec)}
        #{COMMAND_USAGE.fetch(:reset)}
        #{COMMAND_USAGE.fetch(:fs_cp)}
        #{COMMAND_USAGE.fetch(:fs_push)}
        #{COMMAND_USAGE.fetch(:fs_cat)}
        #{COMMAND_USAGE.fetch(:fs_ls)}
        #{COMMAND_USAGE.fetch(:fs_rm)}
        #{COMMAND_USAGE.fetch(:fs_mkdir)}

      `rpremote build clean` removes only the project's generated `build/` directory.

      Configuration:
        config/setting.json  default project options

      Options:
        --force           download the PicoRuby source again during setup
        --language-version VERSION
                          use R2P2/PicoRuby 4.0.3 or 3.4.2 (default: 4.0.3)
        --cache DIR       use another project cache directory
        --mrbgems FILE    use an explicit Mrbgems definition during build or deploy
        --no-mrbgems      build or deploy without the automatically detected Mrbgems
        --board BOARD
                          select pico2 or pico2_w (default: pico2)
        --firmware FILE   build to, or deploy or flash from, this UF2 path
        --language LANGUAGE
                          select the remote language (default: picoruby)
        --config FILE     use another configuration file
        --mount DIR       use an explicit RP2350 BOOTSEL drive
        --port PORT       use an explicit R2P2 CDC 0 device
        --baud RATE       serial baud rate (default: 115200)
        --timeout SEC     timeout in seconds (default: 20)
        -h, --help        show this help
        -V, --version     show the version
    HELP

    def self.requested?(command, args)
      %w[help --help -h].include?(command) || args.include?("--help") || args.include?("-h")
    end

    def self.command_text(command, args)
      command = args.shift if command == "help"
      return TEXT if command.nil? || %w[help --help -h].include?(command)

      case command
      when "setup" then setup_text
      when "build" then args.first == "clean" ? build_clean_text : build_text
      when "bootsel" then bootsel_text
      when "deploy" then deploy_text
      when "dfu" then dfu_text(args.first)
      when "mrbgems" then mrbgems_text(args.first)
      when "flash" then flash_text
      when "config" then config_text(args.first)
      when "ports" then ports_text
      when "run" then run_text
      when "exec" then exec_text
      when "monitor" then monitor_text
      when "repl" then repl_text
      when "reset" then reset_text
      when "fs" then fs_text(args.first)
      else TEXT
      end
    end

    def self.setup_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:setup)}

        Creates config/setting.json when it does not exist, then downloads and prepares PicoRuby source and the official Raspberry Pi nuke_universal.uf2 firmware.
        Options: --language LANGUAGE (picoruby), --language-version VERSION (4.0.3), --cache DIR (firmware), --force.
        This changes the project configuration and source cache but does not connect to a board.
      HELP
    end

    def self.build_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:build)}

        Builds a custom UF2 for the selected target. It writes generated files under build/ and the selected firmware path.
        Options: --language LANGUAGE, --language-version VERSION, --board BOARD (pico2), --cache DIR (firmware),
        --firmware FILE, --mrbgems FILE, --no-mrbgems. A project Mrbgems file is used automatically by default.
      HELP
    end

    def self.build_clean_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:build_clean)}

        Removes only the project's generated build/ directory. It does not remove firmware/, Mrbgems, or Mrbgems.lock.
      HELP
    end

    def self.deploy_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:deploy)}

        Builds the selected custom UF2, enters BOOTSEL when needed, flashes the firmware, and waits for the R2P2 Shell to become ready.
        If PATH/lib/NAME exists, it copies it to :/lib/NAME, where NAME is the final component of PATH. It then runs PATH/main.rb and preserves its Shell job, so hardware output remains active until the next command.
        The stages run in order and stop at the first failure. Flashing replaces persistent board firmware.
        deploy requires PicoRuby 4.x firmware (currently 4.0.3).
        Options combine build, BOOTSEL, flash, library-copy, and run settings. The first install of firmware with automatic BOOTSEL still requires holding BOOTSEL.
      HELP
    end

    def self.bootsel_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:bootsel)}

        Asks the running R2P2 firmware to restart as an RP2350 BOOTSEL USB volume, then waits for that volume to appear.
        By default it does not write firmware. This requires firmware built by a current rpremote; use physical BOOTSEL once to install it first.
        --reset-flash-memory copies the official Raspberry Pi nuke_universal.uf2 in BOOTSEL mode and erases all external flash memory.
        After resetting flash memory, wait for BOOTSEL to reappear and run `rpremote flash` to install R2P2 again.
      HELP
    end

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

    def self.mrbgems_text(subcommand)
      action = subcommand || "check|list|lock|update"
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:mrbgems).sub("SUBCOMMAND", action)}

        Checks or lists build dependencies, writes a reproducible lock file, or updates locked GitHub commits.
        `check` and `list` are read-only. `lock` writes Mrbgems.lock; `update` resolves new commits and rewrites it.
      HELP
    end

    def self.flash_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:flash)}

        Copies the selected UF2 to an RP2350 BOOTSEL volume and waits for R2P2 to reconnect. It replaces persistent board firmware.
        Defaults select pico2, firmware/picoruby-4.0.3-pico2.uf2, an automatic BOOTSEL mount and CDC 0 port, and 20 seconds.
      HELP
    end

    def self.config_text(subcommand)
      unless subcommand == "show"
        return "Usage: #{COMMAND_USAGE.fetch(:config_show)}\n\nUse `rpremote config show --help` for the supported overrides.\n"
      end

      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:config_show)}

        Prints the configuration file, defaults, and command-line overrides after resolution. It does not connect to a board or change state.
      HELP
    end

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

    def self.fs_text(subcommand)
      return fs_subcommand_text(subcommand) if %w[cp push cat ls rm mkdir].include?(subcommand)

      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:fs_cp)}
               #{COMMAND_USAGE.fetch(:fs_push)}
               #{COMMAND_USAGE.fetch(:fs_cat)}
               #{COMMAND_USAGE.fetch(:fs_ls)}
               #{COMMAND_USAGE.fetch(:fs_rm)}
               #{COMMAND_USAGE.fetch(:fs_mkdir)}

        Uses :/REMOTE/PATH for R2P2 paths. Run `rpremote fs SUBCOMMAND --help` for details.
      HELP
    end

    def self.fs_subcommand_text(subcommand)
      usage = COMMAND_USAGE.fetch(:"fs_#{subcommand}")
      effect = case subcommand
               when "rm" then "Deletes the remote path permanently."
               when "mkdir" then "Creates a remote directory."
               when "cp" then "Transfers one file, or recursively uploads a local directory with --recursive."
               when "push" then "Creates missing remote directories and recursively uploads a local directory."
               else "Reads remote files."
               end
      <<~HELP
        Usage: #{usage}

        #{effect} Defaults are the automatic CDC 0 port, 115200 baud, and 20 seconds.
      HELP
    end
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/CyclomaticComplexity
