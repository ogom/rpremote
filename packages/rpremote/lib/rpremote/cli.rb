# frozen_string_literal: true

require "optparse"
require_relative "build_command"
require_relative "bootsel_command"
require_relative "config_show"
require_relative "dfu_command"
require_relative "deploy_command"
require_relative "flash_command"
require_relative "help"
require_relative "mrbgems_command"
require_relative "recursive_copy"
require_relative "setup_command"

# rubocop:disable Metrics/ClassLength
module Rpremote
  class CLI
    def self.start(argv = ARGV, config: Config, **options)
      new(**options).run(argv, config: config)
    rescue OptionParser::ParseError, ArgumentError, SystemCallError, Rpremote::Error => e
      options.fetch(:stderr, $stderr).puts("rpremote: #{e.message}")
      1
    end

    def initialize(
      stdout: $stdout,
      stderr: $stderr,
      serial: Serial,
      device: Device,
      flasher: Flasher
    )
      @stdout = stdout
      @stderr = stderr
      @serial = serial
      @device = device
      @flasher = flasher
    end

    def run(argv, config: Config)
      args = argv.dup
      @config_class = config
      @config_filename, config_required = config.extract_option!(args)
      command = args.shift
      return show_help(command, args) if Help.requested?(command, args)

      @config_options = config.load_command(command, filename: config_filename, required: config_required)
      dispatch(command, args)
      0
    end

    private

    attr_reader :stdout, :stderr, :serial, :device, :flasher,
                :config_class, :config_filename, :config_options

    def show_help(command, args)
      stdout.puts(Help.command_text(command, args))
      0
    end

    def dispatch(command, args)
      case command
      when nil, "help", "--help", "-h"
        stdout.puts(Help::TEXT)
      when "--version", "-V"
        stdout.puts(Rpremote::VERSION)
      when "ports"
        ports(args)
      when "config"
        config_command(args)
      when "setup", "flash", "build", "bootsel", "deploy", "dfu", "mrbgems"
        project_command(command, args)
      when "run", "monitor", "repl", "exec", "reset", "fs"
        remote_command(command, args)
      else
        raise ArgumentError, "unknown command: #{command}"
      end
    end

    def project_command(command, args)
      case command
      when "setup"
        SetupCommand.run(args, defaults: config_options, config: config_class, config_filename: config_filename, output: stdout)
      when "flash"
        FlashCommand.run(args, defaults: config_options, output: stdout, flasher: flasher)
      when "build"
        BuildCommand.run(args, defaults: config_options, output: stdout, error: stderr)
      when "bootsel"
        BootselCommand.run(
          args,
          defaults: config_options,
          output: stdout,
          services: { flasher: flasher, serial: serial, device: device }
        )
      when "deploy"
        DeployCommand.run(
          args,
          defaults: config_options,
          output: stdout,
          error: stderr,
          services: { flasher: flasher, serial: serial, device: device }
        )
      when "dfu"
        DfuCommand.run(args, defaults: config_options, output: stdout, services: { serial: serial, device: device })
      when "mrbgems"
        MrbgemsCommand.run(args, output: stdout)
      end
    end

    def remote_command(command, args)
      case command
      when "run" then run_file(args)
      when "monitor" then interactive(args)
      when "repl" then interactive(args, repl: true)
      when "exec" then execute_code(args)
      when "reset" then reset(args)
      when "fs" then fs(args)
      end
    end

    def ports(args)
      raise ArgumentError, "ports does not accept arguments" unless args.empty?

      found = device.ports
      if found.empty?
        stdout.puts("No R2P2 serial ports found.")
      else
        found.each { |path| stdout.puts(path) }
      end
    end

    def config_command(args)
      subcommand = args.shift
      raise ArgumentError, "unknown config command: #{subcommand || "(none)"}" unless subcommand == "show"

      ConfigShow.run(args, defaults: config_options, output: stdout)
    end

    def fs(args)
      subcommand = args.shift
      recursive = subcommand == "cp" && (args.delete("--recursive") || args.delete("-r"))
      options = parse_connection_options(args)
      case subcommand
      when "cp"
        copy(args, options, recursive: recursive)
      when "push"
        copy(args, options, recursive: true, command: "push")
      when "cat"
        cat(args, options)
      when "ls", "rm", "mkdir"
        filesystem_shell_command(subcommand, args, options)
      else
        raise ArgumentError, "unknown fs command: #{subcommand || "(none)"}"
      end
    rescue Shell::TimeoutError => e
      raise Shell::TimeoutError, "filesystem connection failed: #{e.message}"
    end

    def run_file(args)
      reset_on_timeout = !args.delete("--reset-on-timeout").nil?
      options = parse_connection_options(args)
      raise ArgumentError, "usage: rpremote run FILE [options]" unless args.length == 1

      source = args.first
      source = File.join(source, "main.rb") if File.directory?(source)
      data = prepend_mrbgem_requires(File.binread(source))
      execute_temporary(data, options, output: stdout, reset_on_timeout: reset_on_timeout)
    rescue Errno::ENOENT => e
      raise ArgumentError, e.message
    end

    def execute_code(args)
      options = parse_connection_options(args)
      raise ArgumentError, "usage: rpremote exec CODE [options]" unless args.length == 1

      execute_temporary(prepend_mrbgem_requires(args.first), options, output: stdout)
    end

    def execute_temporary(data, options, output: nil, reset_on_timeout: false)
      Language.validate!(options[:language])
      port_path = device.main_port(options[:port])
      serial.open(port_path, baud: options[:baud]) do |port|
        runner = Runner.new(port, timeout: options[:timeout])
        output ? runner.run(data, output: output, diagnostics: stderr) : runner.run(data, diagnostics: stderr)
      end
    rescue Shell::TimeoutError => e
      reset_after_run_timeout(port_path, options, e) if reset_on_timeout
      raise
    end

    def reset_after_run_timeout(port_path, options, timeout_error)
      stderr.puts("rpremote: run timed out; resetting R2P2: #{port_path}")
      Resetter.new(serial: serial, timeout: options[:timeout]).reset(port_path, baud: options[:baud])
      stderr.puts("rpremote: reset R2P2 after run timeout: #{port_path}")
    rescue Rpremote::Error, IOError, SystemCallError => e
      raise Shell::TimeoutError,
            "#{timeout_error.message}; automatic reset failed: #{e.message}"
    end

    def prepend_mrbgem_requires(data)
      Mrbgems.new(cwd: Dir.pwd).prepend_requires(data)
    end

    def interactive(args, repl: false)
      options = parse_connection_options(args)
      command = repl ? "repl" : "monitor"
      raise ArgumentError, "#{command} does not accept arguments" unless args.empty?

      port_path = device.main_port(options[:port])
      stderr.puts("connected: #{port_path} at #{options[:baud]} baud (Ctrl-] to exit)")
      serial.open(port_path, baud: options[:baud]) do |port|
        if repl
          shell = Shell.new(port, timeout: options[:timeout])
          shell.synchronize!
          shell.send_command("irb")
        end
        Terminal.new(port, output: stdout).run(exit_sequence: repl ? "\x03\x04".b : nil)
      end
    end

    def reset(args)
      options = parse_connection_options(args, default_timeout: Resetter::DEFAULT_TIMEOUT)
      raise ArgumentError, "reset does not accept arguments" unless args.empty?

      port_path = device.main_port(options[:port])
      Resetter.new(serial: serial, timeout: options[:timeout]).reset(port_path, baud: options[:baud])
      stdout.puts("reset R2P2: #{port_path}")
    end

    def parse_connection_options(args, default_timeout: PicoModem::DEFAULT_TIMEOUT)
      options = {
        port: config_options[:port],
        baud: config_options.fetch(:baud, Serial::BAUD_RATE),
        timeout: config_options.fetch(:timeout, default_timeout),
        language: config_options.fetch(:language, Target::DEFAULT_LANGUAGE)
      }
      parser = OptionParser.new do |opts|
        opts.on("--port PORT") { |value| options[:port] = value }
        opts.on("--baud RATE", Integer) { |value| options[:baud] = value }
        opts.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
        opts.on("--language LANGUAGE") { |value| options[:language] = value }
      end
      parser.parse!(args)
      raise ArgumentError, "--baud must be positive" unless options[:baud].positive?
      raise ArgumentError, "--timeout must be positive" unless options[:timeout].positive?

      options
    end

    def copy(args, options, recursive: false, command: "cp")
      usage = command == "push" ? "rpremote fs push LOCAL_DIR :/REMOTE_DIR" : "rpremote fs cp SOURCE DESTINATION"
      raise ArgumentError, "usage: #{usage} [options]" unless args.length == 2

      source, destination = args
      source_remote = RemotePath.remote?(source)
      destination_remote = RemotePath.remote?(destination)
      raise ArgumentError, "exactly one cp path must be remote (prefix remote paths with :)" if source_remote == destination_remote
      return RecursiveCopy.new(output: stdout, serial: serial, device: device).call(source, destination, options) if recursive

      ensure_filesystem_connection!(options)
      if source_remote
        data = with_modem(options) { |modem| modem.download(RemotePath.unwrap(source)) }
        File.binwrite(local_destination(destination, source), data)
        stdout.puts("downloaded #{data.bytesize} bytes: #{source} -> #{destination}")
      else
        data = File.binread(source)
        with_modem(options) { |modem| modem.upload(RemotePath.unwrap(destination), data) }
        stdout.puts("uploaded #{data.bytesize} bytes: #{source} -> #{destination}")
      end
    rescue Errno::ENOENT => e
      raise ArgumentError, e.message
    end

    def cat(args, options)
      raise ArgumentError, "usage: rpremote fs cat :/REMOTE/PATH [options]" unless args.length == 1
      raise ArgumentError, "cat path must be remote (prefix it with :)" unless RemotePath.remote?(args.first)

      stdout.write(with_modem(options) { |modem| modem.download(RemotePath.unwrap(args.first)) })
    end

    def filesystem_shell_command(command, args, options)
      usage = "usage: rpremote fs #{command} :/REMOTE/PATH [options]"
      raise ArgumentError, usage unless args.length == 1

      path = RemotePath.validate(args.first)
      stdout.puts("deleting remote path permanently: #{path}") if command == "rm"
      output = with_shell(options) do |shell|
        shell.execute("#{command} #{Shell.quote_argument(path)}")
      end
      ensure_filesystem_success!(command, output)
      stdout.write(output)
    end

    def ensure_filesystem_success!(command, output)
      failed = command == "ls" ? output.start_with?("ls:") : !output.empty?
      raise Shell::CommandError, output.strip if failed
    end

    def ensure_filesystem_connection!(options)
      output = with_shell(options) { |shell| shell.execute("ls '/'") }
      ensure_filesystem_success!("ls", output)
    end

    def with_modem(options)
      port_path = device.main_port(options[:port])
      serial.open(port_path, baud: options[:baud]) do |port|
        yield PicoModem.new(port, timeout: options[:timeout])
      end
    end

    def with_shell(options)
      port_path = device.main_port(options[:port])
      serial.open(port_path, baud: options[:baud]) do |port|
        shell = Shell.new(port, timeout: options[:timeout])
        shell.synchronize!
        yield shell
      end
    end

    def local_destination(destination, source)
      return destination unless File.directory?(destination)

      File.join(destination, File.basename(RemotePath.unwrap(source)))
    end
  end
end
# rubocop:enable Metrics/ClassLength
