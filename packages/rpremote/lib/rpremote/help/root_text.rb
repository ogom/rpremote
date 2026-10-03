# frozen_string_literal: true

module Rpremote
  module Help
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
        --build           build the selected firmware before deploy flashes it
        --language-version VERSION
                          use a PicoRuby tag or latest (default: latest)
        --cache DIR       use another project cache directory
        --lockfile FILE   use an explicit Mrbgems.lock for build, deploy, run, or exec
        --no-mrbgems      do not build or automatically require locked mrbgems
        --with GROUPS     lock common mrbgems and the comma-separated groups
        --without GROUPS  exclude the comma-separated groups from the lock
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
  end
end
