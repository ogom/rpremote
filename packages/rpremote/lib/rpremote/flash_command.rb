# frozen_string_literal: true

require "optparse"

module Rpremote
  class FlashCommand
    def self.run(args, defaults:, output: $stdout, flasher: Flasher)
      options = parse_options(args, defaults)
      raise ArgumentError, "flash does not accept arguments; use --firmware FILE" unless args.empty?

      target = Target.new(**options.slice(:language, :language_version, :board, :cache_dir, :firmware))
      result = flasher.new(timeout: options[:timeout]).flash(
        target.firmware_path(root: Dir.pwd),
        mount: options[:mount],
        port: options[:port]
      )
      output.puts("flashed firmware #{File.basename(target.firmware_path)}: #{result.port}")
    end

    def self.parse_options(args, defaults)
      options = {
        timeout: defaults.fetch(:timeout, Flasher::DEFAULT_TIMEOUT),
        mount: defaults[:mount],
        port: defaults[:port],
        cache_dir: defaults.fetch(:cache, Target::DEFAULT_CACHE_DIR),
        firmware: defaults[:firmware],
        language: defaults.fetch(:language, Target::DEFAULT_LANGUAGE),
        language_version: defaults.fetch(:language_version, Target::DEFAULT_LANGUAGE_VERSION),
        board: defaults.fetch(:board, Target::DEFAULT_BOARD)
      }
      OptionParser.new do |parser|
        parser.on("--cache DIR") { |value| options[:cache_dir] = value }
        parser.on("--firmware FILE") { |value| options[:firmware] = value }
        parser.on("--language LANGUAGE") { |value| options[:language] = value }
        parser.on("--language-version VERSION") { |value| options[:language_version] = value }
        parser.on("--board BOARD") { |value| options[:board] = value }
        parser.on("--mount DIR") { |value| options[:mount] = value }
        parser.on("--port PORT") { |value| options[:port] = value }
        parser.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
      end.parse!(args)
      options
    end
    private_class_method :parse_options
  end
end
