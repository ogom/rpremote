# frozen_string_literal: true

require "optparse"

module Rpremote
  class DfuCommand
    DEFAULT_TIMEOUT = 20.0
    TYPES = { ".rb" => "RUBY", ".mrb" => "RITE" }.freeze

    def self.run(args, defaults:, output: $stdout, services: {})
      default_services = {
        serial: Serial, device: Device, modem: PicoModem, runner: Runner,
        compiler: DfuCompiler
      }
      services = default_services.merge(services)
      subcommand = args.shift
      case subcommand
      when "app" then stage(args, defaults, output, services)
      when "compile" then compile(args, defaults, output, services[:compiler])
      when "status" then status(args, defaults, output, services)
      when "remove" then remove(args, defaults, output, services)
      else
        raise ArgumentError,
              "usage: rpremote dfu app FILE [options], dfu compile FILE [options], " \
              "dfu status [options], or dfu remove [options]"
      end
    end

    def self.stage(args, defaults, output, services)
      options = parse_app_options(args, defaults)
      raise ArgumentError, "usage: rpremote dfu app FILE [options]" unless args.length == 1

      source = args.first
      data = read_source(source)
      type = options[:type] || type_for(source)
      port_path = services[:device].main_port(options[:port])
      verify_rite_version!(data, port_path, options, services) if type == "RITE"
      output.puts("staging DFU #{type.downcase} app (#{data.bytesize} bytes): #{source} -> inactive slot on #{port_path}; " \
                  "this changes the staged boot application")
      services[:serial].open(port_path, baud: options[:baud]) do |port|
        services[:modem].new(port, timeout: options[:timeout]).dfu(data, type: type)
      end
      output.puts("staged DFU #{type.downcase} app (#{data.bytesize} bytes): #{source}")
      output.puts("restart R2P2 to activate it; the app must call DFU.confirm after a successful boot")
    end
    private_class_method :stage

    def self.compile(args, defaults, output, compiler)
      options = parse_compile_options(args, defaults)
      raise ArgumentError, "usage: rpremote dfu compile FILE [options]" unless args.length == 1

      target = Target.new(
        language: options[:language], language_version: options[:language_version], cache_dir: options[:cache]
      )
      compiler.compile(args.first, target: target, destination: options[:output], output: output)
    end
    private_class_method :compile

    def self.status(args, defaults, output, services)
      options = parse_connection_options(args, defaults)
      raise ArgumentError, "usage: rpremote dfu status [options]" unless args.empty?

      port_path = services[:device].main_port(options[:port])
      code = <<~'RUBY'
        require "dfu"
        status = DFU.status
        puts "active_slot=#{status["active_slot"]}"
        puts "try_slot=#{status["try_slot"]}"
        puts "boot_count=#{status["boot_count"]}/#{status["max_boot_attempts"]}"
        %w[a b].each { |slot| item = status["slot_#{slot}"]; puts "slot_#{slot}=#{item["state"]} #{item["ext"] || "-"}" }
      RUBY
      result = services[:serial].open(port_path, baud: options[:baud]) do |port|
        services[:runner].new(port, timeout: options[:timeout]).run(code)
      end
      output.write(result)
    end
    private_class_method :status

    def self.remove(args, defaults, output, services)
      options = parse_connection_options(args, defaults)
      raise ArgumentError, "usage: rpremote dfu remove [options]" unless args.empty?

      port_path = services[:device].main_port(options[:port])
      code = <<~'RUBY'
        require "dfu"
        # A confirmed DFU launcher may have returned after leaving a Sandbox
        # worker alive. Stop known Processing workers before waiting for the
        # Shell prompt; deleting their source files does not stop RAM tasks.
        begin
          $imu_processing_stream.close if $imu_processing_stream
          $imu_processing_stream = nil
        rescue Exception
          $imu_processing_stream = nil
        end
        begin
          $mpu6050_processing_stream.close if $mpu6050_processing_stream
          $mpu6050_processing_stream = nil
        rescue Exception
          $mpu6050_processing_stream = nil
        end
        DFU::Meta.recover
        DFU::Meta.save(DFU::Meta.deep_copy(DFU::Meta::DEFAULT))
        %w[a b].each do |slot|
          %w[rb mrb].each do |ext|
            path = "#{ENV['HOME']}/app_#{slot}.#{ext}"
            File.unlink(path) if File.exist?(path)
          end
        end
      RUBY
      output.puts("removing all DFU boot applications from #{port_path}; this permanently clears both A/B slots")
      services[:serial].open(port_path, baud: options[:baud]) do |port|
        services[:runner].new(port, timeout: options[:timeout]).run(code)
      end
      output.puts("removed all DFU boot applications; run `rpremote reset` to stop the running application")
    end
    private_class_method :remove

    def self.parse_app_options(args, defaults)
      options = {
        port: defaults[:port],
        baud: defaults.fetch(:baud, Serial::BAUD_RATE),
        timeout: defaults.fetch(:timeout, DEFAULT_TIMEOUT),
        type: nil
      }
      OptionParser.new do |parser|
        parser.on("--type TYPE", %w[ruby rite]) { |value| options[:type] = value.upcase }
        parser.on("--port PORT") { |value| options[:port] = value }
        parser.on("--baud RATE", Integer) { |value| options[:baud] = value }
        parser.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
      end.parse!(args)
      raise ArgumentError, "--baud must be positive" unless options[:baud].positive?
      raise ArgumentError, "--timeout must be positive" unless options[:timeout].positive?

      options
    end
    private_class_method :parse_app_options

    def self.parse_connection_options(args, defaults)
      options = {
        port: defaults[:port],
        baud: defaults.fetch(:baud, Serial::BAUD_RATE),
        timeout: defaults.fetch(:timeout, DEFAULT_TIMEOUT)
      }
      OptionParser.new do |parser|
        parser.on("--port PORT") { |value| options[:port] = value }
        parser.on("--baud RATE", Integer) { |value| options[:baud] = value }
        parser.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
      end.parse!(args)
      raise ArgumentError, "--baud must be positive" unless options[:baud].positive?
      raise ArgumentError, "--timeout must be positive" unless options[:timeout].positive?

      options
    end
    private_class_method :parse_connection_options

    def self.parse_compile_options(args, defaults)
      options = {
        language: defaults.fetch(:language, Target::DEFAULT_LANGUAGE),
        language_version: defaults.fetch(:language_version, Target::DEFAULT_LANGUAGE_VERSION),
        cache: defaults.fetch(:cache, Target::DEFAULT_CACHE_DIR),
        output: nil
      }
      OptionParser.new do |parser|
        parser.on("--output FILE") { |value| options[:output] = value }
        parser.on("--language LANGUAGE") { |value| options[:language] = value }
        parser.on("--language-version VERSION") { |value| options[:language_version] = value }
        parser.on("--cache DIR") { |value| options[:cache] = value }
      end.parse!(args)
      options
    end
    private_class_method :parse_compile_options

    def self.type_for(path)
      TYPES.fetch(File.extname(path).downcase) do
        raise ArgumentError, "cannot infer DFU type from #{path}; use --type ruby or --type rite"
      end
    end
    private_class_method :type_for

    def self.read_source(source)
      File.binread(source)
    rescue Errno::ENOENT
      raise ArgumentError, "DFU app file not found: #{source} (current directory: #{Dir.pwd})"
    end
    private_class_method :read_source

    def self.verify_rite_version!(data, port_path, options, services)
      bytecode_version = data.byteslice(0, 8)
      raise ArgumentError, "DFU RITE app must start with a RITE bytecode header" unless bytecode_version&.match?(/\ARITE\d{4}\z/)

      picoruby_version = services[:serial].open(port_path, baud: options[:baud]) do |port|
        services[:runner].new(port, timeout: options[:timeout]).run("p PICORUBY_VERSION")[/\d+\.\d+\.\d+/]
      end
      unless picoruby_version
        raise Rpremote::Error,
              "connected R2P2 did not report PICORUBY_VERSION; use a .rb app or update R2P2"
      end
      device_version = rite_version_for(picoruby_version)
      return if bytecode_version == device_version

      raise Rpremote::Error,
            "RITE bytecode version #{bytecode_version} does not match connected R2P2 #{device_version}; " \
            "compile with rpremote dfu compile using the installed PicoRuby version"
    end
    private_class_method :verify_rite_version!

    def self.rite_version_for(picoruby_version)
      case picoruby_version.split(".").first
      when "3" then "RITE0300"
      when "4" then "RITE0400"
      else
        raise Rpremote::Error, "unsupported connected PicoRuby version: #{picoruby_version}"
      end
    end
    private_class_method :rite_version_for
  end
end
