# frozen_string_literal: true

require "fileutils"
require "json"

module Rpremote
  class Config
    DEFAULT_PATH = "config/setting.json"
    OPTION_TYPES = {
      port: String,
      mount: String,
      cache: String,
      language_version: String,
      board: String,
      firmware: String,
      baud: Integer,
      timeout: Numeric,
      language: String,
      mrbgems: [String, FalseClass].freeze
    }.freeze
    COMMAND_OPTIONS = {
      "setup" => %i[cache language language_version],
      "build" => %i[cache language language_version board firmware mrbgems],
      "bootsel" => %i[mount port baud timeout],
      "deploy" => %i[cache language language_version board firmware mrbgems mount port baud timeout],
      "dfu" => %i[cache language language_version port baud timeout],
      "flash" => %i[cache language language_version board firmware mount port timeout],
      "run" => %i[port baud timeout language],
      "exec" => %i[port baud timeout language],
      "reset" => %i[port baud timeout],
      "monitor" => %i[port baud timeout],
      "repl" => %i[port baud timeout],
      "fs" => %i[port baud timeout],
      "config" => OPTION_TYPES.keys,
      "ports" => [],
      "mrbgems" => []
    }.freeze

    Result = Data.define(:path, :created)

    class Error < Rpremote::Error; end

    def self.extract_option!(args)
      filename = nil
      index = 0
      while index < args.length
        argument = args[index]
        break if argument == "--"

        value, consumed = config_argument(args, index)
        unless consumed
          index += 1
          next
        end
        raise Error, "--config specified more than once" if filename
        raise Error, "--config requires a value" if value.nil? || value.empty?

        filename = value
        args.slice!(index, consumed)
      end
      [filename || DEFAULT_PATH, !filename.nil?]
    end

    def self.load_command(command, filename:, required:)
      return {} if command.nil? || %w[help --help -h --version -V].include?(command)
      return {} unless COMMAND_OPTIONS.key?(command)

      load(command, filename: filename, required: required && command != "setup")
    end

    def self.load(command, filename: DEFAULT_PATH, required: false, cwd: Dir.pwd)
      path = File.expand_path(filename, cwd)
      text = File.read(path)
      values = parse(text, path)
      validate!(values)
      values.slice(*COMMAND_OPTIONS.fetch(command, []))
    rescue Errno::ENOENT
      raise Error, "config file does not exist: #{path}" if required

      {}
    end

    def self.setup(filename: DEFAULT_PATH, cwd: Dir.pwd)
      path = File.expand_path(filename, cwd)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "wx") { |file| file.write("{}\n") }
      Result.new(path: path, created: true)
    rescue Errno::EEXIST
      Result.new(path: path, created: false)
    rescue SystemCallError => e
      raise Error, "cannot create config file #{path}: #{e.message}"
    end

    def self.parse(text, path)
      parsed = JSON.parse(text, symbolize_names: true)
      raise Error, "config file must contain a JSON object: #{path}" unless parsed.is_a?(Hash)

      parsed
    rescue JSON::ParserError => e
      raise Error, "invalid config file #{path}: #{e.message}"
    end
    private_class_method :parse

    def self.validate!(values)
      values.each do |key, value|
        expected = OPTION_TYPES[key]
        raise Error, "unknown config option: #{key}" unless expected
        raise Error, "config option #{key} must be a #{type_name(expected)}" unless valid_value?(value, expected)
        next unless %i[baud timeout].include?(key)
        next if value.positive?

        raise Error, "config option #{key} must be positive"
      end
    end
    private_class_method :validate!

    def self.valid_value?(value, expected)
      types = Array(expected)
      types.any? { |type| value.is_a?(type) } && (!value.is_a?(String) || !value.empty?)
    end
    private_class_method :valid_value?

    def self.type_name(type)
      return type.map { |item| type_name(item) }.join(" or ") if type.is_a?(Array)
      return "false" if type == FalseClass

      type == Numeric ? "number" : type.name.downcase
    end
    private_class_method :type_name

    def self.config_argument(args, index)
      argument = args[index]
      return [args[index + 1], 2] if argument == "--config"
      return [argument.delete_prefix("--config="), 1] if argument.start_with?("--config=")

      [nil, nil]
    end
    private_class_method :config_argument
  end
end
