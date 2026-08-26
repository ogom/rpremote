# frozen_string_literal: true

require "optparse"
require_relative "bootsel_command"
require_relative "recursive_copy"

module Rpremote
  class DeployCommand
    SHELL_READY_TIMEOUT = 2.0
    RETRY_INTERVAL = 0.25

    class Error < Rpremote::Error; end

    # The command intentionally keeps the six deployment stages visible in execution order.
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.run(args, defaults:, output: $stdout, error: $stderr, services: {})
      options = parse_options(args, defaults)
      raise ArgumentError, "usage: rpremote deploy PATH [options]" unless args.length == 1

      project = File.expand_path(args.first)
      library, remote_library, source = project_files(project)
      Language.validate!(options[:language])

      builder = services.fetch(:builder) { Builder.new }
      flasher = services.fetch(:flasher, Flasher)
      serial = services.fetch(:serial, Serial)
      device = services.fetch(:device, Device)
      runner = services.fetch(:runner, Runner)
      target_options = options.slice(:language, :language_version, :board, :cache_dir, :firmware)
      firmware_path = Target.new(**target_options).firmware_path(root: Dir.pwd)

      output.puts("deploy build: #{firmware_path}")
      builder.build(
        **target_options,
        mrbgems: options[:mrbgems],
        output: output,
        error: error
      )

      flash_service = flasher.new(timeout: options[:timeout])
      bootsel_mount = resolve_bootsel_mount(options, flash_service, output, services)

      mount = options[:mount] || "an automatically detected RP2350 BOOTSEL volume"
      output.puts("deploy flash: #{firmware_path} to #{mount}; this replaces persistent board firmware")
      result = flash_service.flash(
        firmware_path,
        mount: bootsel_mount,
        port: options[:port]
      )

      connection_options = options.merge(port: result.port)
      output.puts("deploy connect: waiting for R2P2 Shell on #{result.port}")
      wait_for_shell(
        port: result.port, baud: options[:baud], timeout: options[:timeout], serial: serial,
        shell: services.fetch(:shell, Shell),
        sleeper: services.fetch(:sleeper) { ->(seconds) { sleep(seconds) } },
        clock: services.fetch(:clock) { -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) } }
      )
      output.puts("deploy connect: ready on #{result.port}")

      if File.directory?(library)
        output.puts("deploy push: #{library} -> :#{remote_library}")
        recursive_copy = services.fetch(:recursive_copy) do
          RecursiveCopy.new(output: output, serial: serial, device: device)
        end
        recursive_copy.call(library, ":#{remote_library}", connection_options)
      else
        output.puts("deploy push: skipped; directory not found: #{library}")
      end

      output.puts("deploy run: #{source} on #{result.port}")
      source_data = prepend_mrbgem_requires(File.binread(source), options[:mrbgems])
      run_output = serial.open(result.port, baud: options[:baud]) do |port|
        runner.new(port, timeout: options[:timeout]).run(
          source_data, output: output, cleanup: false, remote_path: Runner::DEPLOY_REMOTE_PATH
        )
      end
      output.puts("deploy run: completed; output bytes: #{run_output.to_s.bytesize}")
    rescue Errno::ENOENT => e
      raise ArgumentError, e.message
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def self.project_files(project)
      raise ArgumentError, "project directory not found: #{project}" unless File.directory?(project)

      name = File.basename(project)
      library = File.join(project, "lib", name)
      source = File.join(project, "main.rb")
      raise ArgumentError, "project entry file not found: #{source}" unless File.file?(source)

      [library, File.join("/lib", name), source]
    end
    private_class_method :project_files

    def self.prepend_mrbgem_requires(source, definition)
      return source if definition == false

      Mrbgems.new(path: definition || Mrbgems::DEFAULT_PATH, cwd: Dir.pwd).prepend_requires(source)
    end
    private_class_method :prepend_mrbgem_requires

    def self.wait_for_shell(context)
      port = context.fetch(:port)
      baud = context.fetch(:baud)
      timeout = context.fetch(:timeout)
      serial = context.fetch(:serial)
      shell = context.fetch(:shell)
      sleeper = context.fetch(:sleeper)
      clock = context.fetch(:clock)
      deadline = clock.call + timeout
      loop do
        serial.open(port, baud:) do |connection|
          remaining = deadline - clock.call
          raise Shell::TimeoutError, "R2P2 Shell is not ready" unless remaining.positive?

          shell.new(connection, timeout: [remaining, SHELL_READY_TIMEOUT].min).synchronize!
        end
        return
      rescue Serial::ConfigurationError, Shell::TimeoutError, IOError, SystemCallError
        raise Error, "timed out waiting for R2P2 Shell after flash" if clock.call >= deadline

        sleeper.call(RETRY_INTERVAL)
      end
    end
    private_class_method :wait_for_shell

    def self.resolve_bootsel_mount(options, flash_service, output, services)
      mounted = flash_service.find_mounted(options[:mount])
      if mounted
        output.puts("deploy bootsel: already mounted at #{mounted}; skipping serial reset")
        return mounted
      end

      port = options[:port] || "an automatically detected R2P2 port"
      output.puts("deploy bootsel: requesting USB BOOTSEL mode through #{port}")
      BootselCommand.enter(
        mount: options[:mount], port: options[:port], baud: options[:baud], timeout: options[:timeout],
        output: output, services: services.slice(:flasher, :serial, :device, :shell)
      )
    end
    private_class_method :resolve_bootsel_mount

    def self.parse_options(args, defaults)
      options = default_options(defaults)
      option_parser(options).parse!(args)
      validate_options!(options)
      options
    end
    private_class_method :parse_options

    def self.default_options(defaults)
      {
        language: defaults.fetch(:language, Target::DEFAULT_LANGUAGE),
        language_version: defaults.fetch(:language_version, Target::DEFAULT_LANGUAGE_VERSION),
        board: defaults.fetch(:board, Target::DEFAULT_BOARD),
        cache_dir: defaults.fetch(:cache, Target::DEFAULT_CACHE_DIR),
        firmware: defaults[:firmware],
        mrbgems: defaults[:mrbgems],
        mount: defaults[:mount],
        port: defaults[:port],
        baud: defaults.fetch(:baud, Serial::BAUD_RATE),
        timeout: defaults.fetch(:timeout, Flasher::DEFAULT_TIMEOUT)
      }
    end
    private_class_method :default_options

    def self.option_parser(options)
      OptionParser.new do |parser|
        parser.on("--language LANGUAGE") { |value| options[:language] = value }
        parser.on("--language-version VERSION") { |value| options[:language_version] = value }
        parser.on("--board BOARD") { |value| options[:board] = value }
        parser.on("--cache DIR") { |value| options[:cache_dir] = value }
        parser.on("--firmware FILE") { |value| options[:firmware] = value }
        parser.on("--mrbgems FILE") { |value| options[:mrbgems] = value }
        parser.on("--no-mrbgems") { options[:mrbgems] = false }
        parser.on("--mount DIR") { |value| options[:mount] = value }
        parser.on("--port PORT") { |value| options[:port] = value }
        parser.on("--baud RATE", Integer) { |value| options[:baud] = value }
        parser.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
      end
    end
    private_class_method :option_parser

    def self.validate_options!(options)
      raise ArgumentError, "--baud must be positive" unless options[:baud].positive?
      raise ArgumentError, "--timeout must be positive" unless options[:timeout].positive?
    end
    private_class_method :validate_options!
  end
end
