# frozen_string_literal: true

module Rpremote
  module Help
    def self.setup_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:setup)}

        Creates config/setting.json when it does not exist, then downloads and prepares PicoRuby source and the official Raspberry Pi nuke_universal.uf2 firmware.
        Options: --language LANGUAGE (picoruby), --language-version VERSION (latest), --cache DIR (firmware), --force.
        This changes the project configuration and source cache but does not connect to a board.
      HELP
    end

    def self.build_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:build)}

        Builds a custom UF2 for the selected target. It writes generated files under build/ and the selected firmware path.
        Options: --language LANGUAGE, --language-version VERSION, --board BOARD (pico2), --cache DIR (firmware),
        --firmware FILE, --lockfile FILE, --no-mrbgems. A project Mrbgems.lock file is used automatically by default.
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

        Enters BOOTSEL when needed, flashes the existing selected UF2, and waits for the R2P2 Shell to become ready.
        With --build, builds the selected custom UF2 before entering BOOTSEL and flashing it.
        If PATH/lib/NAME exists, it copies it to :/lib/NAME, where NAME is the final component of PATH. It then runs PATH/main.rb and preserves its Shell job, so hardware output remains active until the next command.
        The stages run in order and stop at the first failure. Flashing replaces persistent board firmware.
        deploy requires current PicoRuby 4.x firmware.
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

    def self.mrbgems_text(subcommand)
      action = subcommand || "check|list|lock|update"
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:mrbgems).sub("SUBCOMMAND", action)}

        Checks or lists build dependencies, writes a reproducible lock file, or updates locked GitHub commits.
        `lock --with production --without test` includes common and production gems. Exclusions take precedence.
        `update` resolves new commits using the same group options.
      HELP
    end

    def self.flash_text
      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:flash)}

        Copies the selected UF2 to an RP2350 BOOTSEL volume and waits for R2P2 to reconnect. It replaces persistent board firmware.
        Defaults select pico2, firmware/picoruby-latest-pico2.uf2, an automatic BOOTSEL mount and CDC 0 port, and 20 seconds.
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
  end
end
