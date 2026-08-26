# frozen_string_literal: true

require "optparse"

module Rpremote
  class BootselCommand
    SHELL_READY_TIMEOUT = 2.0
    RETRY_INTERVAL = 0.25
    RESET_FLASH_FIRMWARE = File.join("firmware", "nuke_universal.uf2").freeze

    class Error < Rpremote::Error; end

    def self.run(args, defaults:, output: $stdout, services: {})
      options = parse_options(args, defaults)
      raise ArgumentError, "bootsel does not accept arguments" unless args.empty?

      reset_flasher = nil
      if options[:reset_flash_memory]
        flasher = services.fetch(:flasher, Flasher)
        reset_flasher = flasher.new(timeout: options[:timeout])
        target = reset_flasher.find_mounted(options[:mount])
        output.puts("BOOTSEL ready: #{target}") if target
      end
      target ||= enter(**options.slice(:mount, :port, :baud, :timeout), output: output, services: services)
      reset_flash_memory(target, output: output, flasher: reset_flasher) if options[:reset_flash_memory]
      target
    end

    def self.reset_flash_memory(target, output:, flasher:)
      firmware_path = File.expand_path(RESET_FLASH_FIRMWARE, Dir.pwd)
      raise Error, "reset firmware not found: #{firmware_path}; run `rpremote setup` first" unless File.file?(firmware_path)

      output.puts("resetting Raspberry Pi Pico 2 external flash memory through #{target}; this erases all stored data and firmware")
      flasher.flash(firmware_path, mount: target, wait_for_port: false)
      output.puts("Pico 2 external flash memory reset; wait for the RP2350 BOOTSEL drive, then run `rpremote flash` to install R2P2")
    end
    private_class_method :reset_flash_memory

    def self.enter(mount:, port:, baud:, timeout:, output:, services: {})
      serial = services.fetch(:serial, Serial)
      device = services.fetch(:device, Device)
      shell = services.fetch(:shell, Shell)
      flasher = services.fetch(:flasher, Flasher)
      sleeper = services.fetch(:sleeper) { ->(seconds) { sleep(seconds) } }
      clock = services.fetch(:clock) { -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) } }
      deadline = clock.call + timeout

      request_bootsel(
        port: port, baud: baud, deadline: deadline, output: output,
        serial: serial, device: device, shell: shell, sleeper: sleeper, clock: clock
      )

      remaining = deadline - clock.call
      raise Error, "timed out waiting for R2P2 Shell to accept a BOOTSEL request" unless remaining.positive?

      target = flasher.new(timeout: remaining).wait_for_mount(mount: mount)
      output.puts("BOOTSEL ready: #{target}")
      target
    end

    def self.request_bootsel(context)
      port = context.fetch(:port)
      baud = context.fetch(:baud)
      deadline = context.fetch(:deadline)
      output = context.fetch(:output)
      serial = context.fetch(:serial)
      device = context.fetch(:device)
      shell = context.fetch(:shell)
      sleeper = context.fetch(:sleeper)
      clock = context.fetch(:clock)
      announced = false

      loop do
        port_path = device.main_port(port)
        unless announced
          output.puts("entering BOOTSEL mode: #{port_path}")
          announced = true
        end

        requested = false
        serial.open(port_path, baud: baud) do |connection|
          remaining = deadline - clock.call
          raise Shell::TimeoutError, "R2P2 Shell is not ready" unless remaining.positive?

          remote_shell = shell.new(connection, timeout: [remaining, SHELL_READY_TIMEOUT].min)
          remote_shell.synchronize!
          unless remote_shell.execute("type bootsel").include?("bootsel is")
            raise Error, "connected R2P2 firmware does not support BOOTSEL reset; flash a current rpremote UF2 once while holding BOOTSEL"
          end

          remote_shell.send_command("bootsel")
          requested = true
        end
        break if requested
      rescue Device::NotFoundError, Serial::ConfigurationError, Shell::TimeoutError, IOError, SystemCallError
        raise Error, "timed out waiting for R2P2 Shell to accept a BOOTSEL request" if clock.call >= deadline

        sleeper.call(RETRY_INTERVAL)
      end
    end
    private_class_method :request_bootsel

    def self.parse_options(args, defaults)
      options = {
        mount: defaults[:mount],
        port: defaults[:port],
        baud: defaults.fetch(:baud, Serial::BAUD_RATE),
        timeout: defaults.fetch(:timeout, Flasher::DEFAULT_TIMEOUT)
      }
      OptionParser.new do |parser|
        parser.on("--mount DIR") { |value| options[:mount] = value }
        parser.on("--port PORT") { |value| options[:port] = value }
        parser.on("--baud RATE", Integer) { |value| options[:baud] = value }
        parser.on("--timeout SECONDS", Float) { |value| options[:timeout] = value }
        parser.on("--reset-flash-memory") { options[:reset_flash_memory] = true }
      end.parse!(args)
      raise ArgumentError, "--baud must be positive" unless options[:baud].positive?
      raise ArgumentError, "--timeout must be positive" unless options[:timeout].positive?

      options
    end
    private_class_method :parse_options
  end
end
