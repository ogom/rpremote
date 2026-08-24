# frozen_string_literal: true

module Rpremote
  class Resetter
    DEFAULT_TIMEOUT = 20.0
    RETRY_INTERVAL = 0.1
    PROBE_TIMEOUT = 1.0

    class TimeoutError < Rpremote::Error; end

    def initialize(
      serial: Serial,
      timeout: DEFAULT_TIMEOUT,
      shell_class: Shell,
      sleeper: nil,
      clock: nil,
      port_probe: nil
    )
      @serial = serial
      @timeout = Float(timeout)
      @shell_class = shell_class
      @sleeper = sleeper || ->(seconds) { sleep(seconds) }
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @port_probe = port_probe || ->(path) { File.exist?(path) }
      raise ArgumentError, "timeout must be positive" unless @timeout.positive?
    end

    def reset(port_path, baud: Serial::BAUD_RATE)
      deadline = clock.call + timeout
      send_reboot(port_path, baud)
      wait_until("USB serial port to disconnect", deadline) { !port_probe.call(port_path) }
      wait_until_ready(port_path, baud, deadline)
      port_path
    end

    private

    attr_reader :serial, :timeout, :shell_class, :sleeper, :clock, :port_probe

    def send_reboot(port_path, baud)
      serial.open(port_path, baud: baud) do |port|
        shell = shell_class.new(port, timeout: [timeout, PROBE_TIMEOUT].min)
        shell.synchronize!
        shell.send_command("reboot")
      end
    end

    def wait_until_ready(port_path, baud, deadline)
      wait_until("R2P2 Shell after reset", deadline) do
        remaining = deadline - clock.call
        shell_ready?(port_path, baud, [remaining, PROBE_TIMEOUT].min) if remaining.positive?
      end
    end

    def wait_until(description, deadline)
      loop do
        return if yield
        raise TimeoutError, "timed out waiting for #{description}" if clock.call >= deadline

        sleeper.call(RETRY_INTERVAL)
      end
    end

    def shell_ready?(port_path, baud, probe_timeout)
      serial.open(port_path, baud: baud) do |port|
        shell_class.new(port, timeout: probe_timeout).synchronize!
      end
      true
    rescue IOError, SystemCallError, Rpremote::Error
      false
    end
  end
end
