# frozen_string_literal: true

module Rpremote
  class Runner
    REMOTE_DIRECTORY = "/home"

    attr_reader :io, :timeout

    def initialize(
      io,
      timeout: Shell::DEFAULT_TIMEOUT,
      modem_class: PicoModem,
      shell_class: Shell,
      path_factory: nil
    )
      @io = io
      @timeout = timeout
      @modem_class = modem_class
      @shell_class = shell_class
      @path_factory = path_factory || method(:temporary_path)
    end

    def run(data)
      remote_path = @path_factory.call
      shell = @shell_class.new(io, timeout: timeout)
      shell.synchronize!
      @modem_class.new(io, timeout: timeout).upload(remote_path, data)
      shell.synchronize!
      shell_ready = true
      shell.execute("./#{File.basename(remote_path)}")
    ensure
      cleanup(shell, remote_path) if shell_ready && remote_path
    end

    private

    def cleanup(shell, remote_path)
      shell.execute("rm #{remote_path}")
    rescue IOError, SystemCallError, Shell::Error
      nil
    end

    def temporary_path
      stamp = (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1_000_000).to_i
      "#{REMOTE_DIRECTORY}/.rpremote-run-#{Process.pid}-#{stamp}.rb"
    end
  end
end
