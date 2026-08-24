# frozen_string_literal: true

require "optparse"

module Rpremote
  class SetupCommand
    def self.run(args, defaults:, config:, config_filename:, output: $stdout)
      options = {
        force: false,
        cache_dir: defaults.fetch(:cache, Target::DEFAULT_CACHE_DIR),
        language: defaults.fetch(:language, Target::DEFAULT_LANGUAGE),
        language_version: defaults.fetch(:language_version, Target::DEFAULT_LANGUAGE_VERSION)
      }
      OptionParser.new do |parser|
        parser.on("--force") { options[:force] = true }
        parser.on("--cache DIR") { |value| options[:cache_dir] = value }
        parser.on("--language LANGUAGE") { |value| options[:language] = value }
        parser.on("--language-version VERSION") { |value| options[:language_version] = value }
      end.parse!(args)
      raise ArgumentError, "setup does not accept arguments" unless args.empty?

      target = Target.new(**options.slice(:cache_dir, :language, :language_version))
      Language.validate!(target.language)
      result = config.setup(filename: config_filename)
      output.puts("#{result.created ? "created" : "exists"} config: #{result.path}")
      path = LanguageSource.new(
        language: target.language,
        version: target.language_version,
        cache_dir: target.cache_dir
      ).setup(force: options[:force])
      output.puts("installed #{target.language} #{target.language_version}: #{path}")
    end
  end
end
