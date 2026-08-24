# frozen_string_literal: true

require "optparse"

module Rpremote
  class BuildCommand
    def self.run(args, defaults:, output: $stdout, error: $stderr, builder: Builder.new)
      if args.first == "clean"
        args.shift
        raise ArgumentError, "build clean does not accept arguments" unless args.empty?

        builder.clean(output: output)
        return
      end

      options = {
        language: Target::DEFAULT_LANGUAGE,
        language_version: Target::DEFAULT_LANGUAGE_VERSION,
        board: Target::DEFAULT_BOARD,
        cache_dir: defaults.fetch(:cache, Target::DEFAULT_CACHE_DIR),
        firmware: defaults[:firmware],
        mrbgems: nil
      }.merge(defaults.except(:cache))
      OptionParser.new do |parser|
        parser.on("--language LANGUAGE") { |value| options[:language] = value }
        parser.on("--language-version VERSION") { |value| options[:language_version] = value }
        parser.on("--board BOARD") { |value| options[:board] = value }
        parser.on("--firmware FILE") { |value| options[:firmware] = value }
        parser.on("--cache DIR") { |value| options[:cache_dir] = value }
        parser.on("--mrbgems FILE") { |value| options[:mrbgems] = value }
        parser.on("--no-mrbgems") { options[:mrbgems] = false }
      end.parse!(args)
      raise ArgumentError, "build does not accept arguments" unless args.empty?

      builder.build(**options, output: output, error: error)
    end
  end
end
