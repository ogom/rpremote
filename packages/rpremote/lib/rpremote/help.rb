# frozen_string_literal: true

module Rpremote
  module Help
    TEXT = <<~HELP
      rpremote - R2P2 remote control for Raspberry Pi Pico 2

      Usage:
        rpremote setup [--language LANGUAGE] [--language-version VERSION] [--force] [--cache DIR]
        rpremote build [--language LANGUAGE] [--language-version VERSION] [--board BOARD]
                       [--firmware FILE] [--cache DIR]
                       [--mrbgems FILE|--no-mrbgems]
        rpremote build clean
        rpremote dfu app FILE [--type ruby|rite] [--port PORT] [--baud RATE] [--timeout SEC]
        rpremote dfu compile FILE [--output FILE] [--language picoruby]
                             [--language-version VERSION] [--cache DIR]
        rpremote dfu status [--port PORT] [--baud RATE] [--timeout SEC]
        rpremote mrbgems check|list|lock|update [--file FILE] [--lockfile FILE]
        rpremote flash [--firmware FILE] [--language LANGUAGE] [--language-version VERSION]
                       [--board BOARD] [--cache DIR] [--mount DIR] [--port PORT] [--timeout SEC]
        rpremote ports
        rpremote run FILE [--port PORT] [--timeout SEC] [--language LANGUAGE]
        rpremote monitor [--port PORT]
        rpremote repl [--port PORT]
        rpremote exec CODE [--port PORT] [--timeout SEC] [--language LANGUAGE]
        rpremote reset [--port PORT]
        rpremote fs cp FILE :/REMOTE/PATH [--port PORT]
        rpremote fs cp :/REMOTE/PATH FILE [--port PORT]
        rpremote fs cat :/REMOTE/PATH [--port PORT]
        rpremote fs ls :/REMOTE/PATH [--port PORT]
        rpremote fs rm :/REMOTE/PATH [--port PORT]
        rpremote fs mkdir :/REMOTE/PATH [--port PORT]

      `rpremote build clean` removes only the project's generated `build/` directory.

      Configuration:
        config/setting.json  default project options

      Options:
        --force           download the PicoRuby source again during setup
        --language-version VERSION
                          use R2P2/PicoRuby 4.0.3 or 3.4.2 (default: 4.0.3)
        --cache DIR       use another project cache directory
        --mrbgems FILE    use an explicit Mrbgems definition during build
        --no-mrbgems      build without the automatically detected Mrbgems
        --board BOARD
                          select pico2 or pico2_w (default: pico2)
        --firmware FILE   build to, or flash from, this UF2 path
        --language LANGUAGE
                          select the remote language (default: picoruby)
        --config FILE     use another configuration file
        --mount DIR       use an explicit RP2350 BOOTSEL drive
        --port PORT       use an explicit R2P2 CDC 0 device
        --baud RATE       serial baud rate (default: 115200)
        --timeout SEC     timeout in seconds (default: 10)
        -h, --help        show this help
        -V, --version     show the version
    HELP
  end
end
