# frozen_string_literal: true

module Rpremote
  module Help
    COMMAND_USAGE = {
      setup: "rpremote setup [--language LANGUAGE] [--language-version VERSION] [--force] [--cache DIR]",
      build: "rpremote build [--language LANGUAGE] [--language-version VERSION] [--board BOARD] " \
             "[--firmware FILE] [--cache DIR] [--lockfile FILE|--no-mrbgems]",
      build_clean: "rpremote build clean",
      bootsel: "rpremote bootsel [--reset-flash-memory] [--mount DIR] [--port PORT] [--baud RATE] [--timeout SEC]",
      deploy: "rpremote deploy PATH [--build] [--language LANGUAGE] [--language-version VERSION] [--board BOARD] " \
              "[--firmware FILE] [--cache DIR] [--lockfile FILE|--no-mrbgems] [--mount DIR] " \
              "[--port PORT] [--baud RATE] [--timeout SEC]",
      dfu_app: "rpremote dfu app FILE [--type ruby|rite] [--port PORT] [--baud RATE] [--timeout SEC]",
      dfu_compile: "rpremote dfu compile FILE [--output FILE] [--language LANGUAGE] [--language-version VERSION] [--cache DIR]",
      dfu_status: "rpremote dfu status [--port PORT] [--baud RATE] [--timeout SEC]",
      dfu_remove: "rpremote dfu remove [--port PORT] [--baud RATE] [--timeout SEC]",
      mrbgems: "rpremote mrbgems SUBCOMMAND [--file FILE] [--lockfile FILE] [--with GROUPS] [--without GROUPS]",
      flash: "rpremote flash [--firmware FILE] [--language LANGUAGE] [--language-version VERSION] " \
             "[--board BOARD] [--cache DIR] [--mount DIR] [--port PORT] [--timeout SEC]",
      config_show: "rpremote config show [--language LANGUAGE] [--language-version VERSION] [--board BOARD] " \
                   "[--cache DIR] [--firmware FILE] [--lockfile FILE|--no-mrbgems] [--mount DIR] " \
                   "[--port PORT] [--baud RATE] [--timeout SEC]",
      ports: "rpremote ports",
      run: "rpremote run FILE [--port PORT] [--baud RATE] [--timeout SEC] [--reset-on-timeout] [--language LANGUAGE] " \
           "[--lockfile FILE|--no-mrbgems]",
      monitor: "rpremote monitor [--port PORT] [--baud RATE] [--timeout SEC]",
      repl: "rpremote repl [--port PORT] [--baud RATE] [--timeout SEC]",
      exec: "rpremote exec CODE [--port PORT] [--baud RATE] [--timeout SEC] [--language LANGUAGE] " \
            "[--lockfile FILE|--no-mrbgems]",
      reset: "rpremote reset [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_cp: "rpremote fs cp SOURCE DESTINATION [--recursive] [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_push: "rpremote fs push LOCAL_DIR :/REMOTE_DIR [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_cat: "rpremote fs cat :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_ls: "rpremote fs ls :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_rm: "rpremote fs rm :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]",
      fs_mkdir: "rpremote fs mkdir :/REMOTE/PATH [--port PORT] [--baud RATE] [--timeout SEC]"
    }.freeze
    COMMAND_TEXT_METHODS = {
      "setup" => :setup_text, "bootsel" => :bootsel_text, "deploy" => :deploy_text,
      "flash" => :flash_text, "ports" => :ports_text, "run" => :run_text,
      "exec" => :exec_text, "monitor" => :monitor_text, "repl" => :repl_text,
      "reset" => :reset_text
    }.freeze

    def self.requested?(command, args)
      %w[help --help -h].include?(command) || args.include?("--help") || args.include?("-h")
    end

    def self.command_text(command, args)
      command = args.shift if command == "help"
      return TEXT if command.nil? || %w[help --help -h].include?(command)
      return args.first == "clean" ? build_clean_text : build_text if command == "build"
      return dfu_text(args.first) if command == "dfu"
      return mrbgems_text(args.first) if command == "mrbgems"
      return config_text(args.first) if command == "config"
      return fs_text(args.first) if command == "fs"

      method_name = COMMAND_TEXT_METHODS[command]
      method_name ? public_send(method_name) : TEXT
    end
  end
end

require_relative "help/root_text"
require_relative "help/project_commands"
require_relative "help/dfu_commands"
require_relative "help/remote_commands"
require_relative "help/filesystem_commands"
