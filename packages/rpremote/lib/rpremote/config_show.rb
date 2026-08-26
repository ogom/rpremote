# frozen_string_literal: true

require "optparse"
require_relative "picomodem"
require_relative "serial"
require_relative "target"

module Rpremote
  class ConfigShow
    def self.run(args, defaults:, output:)
      new(defaults: defaults, output: output).run(args)
    end

    def initialize(defaults:, output:)
      @defaults = defaults
      @output = output
    end

    def run(args)
      options = effective_options
      parser = option_parser(options)
      parser.parse!(args)
      raise ArgumentError, "usage: rpremote config show [options]" unless args.empty?
      raise ArgumentError, "--baud must be positive" unless options[:baud].positive?
      raise ArgumentError, "--timeout must be positive" unless options[:timeout].positive?

      print_options(options)
    end

    private

    attr_reader :defaults, :output

    def effective_options
      {
        language: defaults.fetch(:language, Target::DEFAULT_LANGUAGE),
        language_version: defaults.fetch(:language_version, Target::DEFAULT_LANGUAGE_VERSION),
        board: defaults.fetch(:board, Target::DEFAULT_BOARD),
        cache: defaults.fetch(:cache, Target::DEFAULT_CACHE_DIR),
        firmware: defaults[:firmware],
        mrbgems: defaults[:mrbgems],
        mount: defaults[:mount],
        port: defaults[:port],
        baud: defaults.fetch(:baud, Serial::BAUD_RATE),
        timeout: defaults.fetch(:timeout, PicoModem::DEFAULT_TIMEOUT)
      }
    end

    def option_parser(options)
      OptionParser.new do |opts|
        opts.on("--language LANGUAGE") { |value| options[:language] = value }
        opts.on("--language-version VERSION") { |value| options[:language_version] = value }
        opts.on("--board BOARD") { |value| options[:board] = value }
        opts.on("--cache DIR") { |value| options[:cache] = value }
        opts.on("--firmware FILE") { |value| options[:firmware] = value }
        opts.on("--mrbgems FILE") { |value| options[:mrbgems] = value }
        opts.on("--no-mrbgems") { options[:mrbgems] = false }
        opts.on("--mount DIR") { |value| options[:mount] = value }
        opts.on("--port PORT") { |value| options[:port] = value }
        opts.on("--baud RATE", Integer) { |value| options[:baud] = value }
        opts.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
      end
    end

    def print_options(options)
      target = Target.new(
        language: options[:language],
        language_version: options[:language_version],
        board: options[:board],
        cache_dir: options[:cache],
        firmware: options[:firmware]
      )
      output.puts("language=#{target.language}")
      output.puts("language_version=#{target.language_version}")
      output.puts("board=#{target.board}")
      output.puts("cache=#{target.cache_dir}")
      output.puts("firmware=#{target.firmware_path}")
      output.puts("mrbgems=#{mrbgems_value(options[:mrbgems])}")
      output.puts("mount=#{options[:mount] || "auto"}")
      output.puts("port=#{options[:port] || "auto"}")
      output.puts("baud=#{options[:baud]}")
      output.puts("timeout=#{options[:timeout]}")
    end

    def mrbgems_value(value)
      return "false" if value == false

      value || "auto"
    end
  end
end
