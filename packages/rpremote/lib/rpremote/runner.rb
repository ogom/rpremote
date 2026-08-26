# frozen_string_literal: true

module Rpremote
  class Runner
    REMOTE_DIRECTORY = "/home"
    RUN_REMOTE_PATH = "#{REMOTE_DIRECTORY}/.rpremote-run.rb".freeze
    DEPLOY_REMOTE_PATH = "#{REMOTE_DIRECTORY}/.rpremote-deploy.rb".freeze

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

    def run(data, output: nil, cleanup: true, remote_path: nil, diagnostics: nil)
      remote_path ||= @path_factory.call
      shell = @shell_class.new(io, timeout: timeout)
      trace(diagnostics, "SYNC_BEFORE_UPLOAD_START")
      shell.synchronize!
      trace(diagnostics, "SYNC_BEFORE_UPLOAD_DONE")
      trace(diagnostics, "UPLOAD_START", "bytes=#{data.bytesize},path=#{remote_path}")
      @modem_class.new(io, timeout: timeout).upload(remote_path, data)
      trace(diagnostics, "UPLOAD_DONE")
      trace(diagnostics, "SYNC_BEFORE_RUN_START")
      shell.synchronize!
      trace(diagnostics, "SYNC_BEFORE_RUN_DONE")
      shell_ready = true
      command = "./#{File.basename(remote_path)}"
      trace(diagnostics, "EXECUTE_START", "command=#{command}")
      result = output ? shell.execute(command, output: output, idle_timeout: true) : shell.execute(command, idle_timeout: true)
      trace(diagnostics, "EXECUTE_DONE", "bytes=#{result.to_s.bytesize}")
      result
    rescue StandardError => e
      trace(diagnostics, "ERROR", "class=#{e.class},message=#{e.message.to_s.gsub("\n", " ")}")
      raise
    ensure
      if cleanup && shell_ready && remote_path
        trace(diagnostics, "CLEANUP_START", "path=#{remote_path}")
        cleanup(shell, remote_path)
        trace(diagnostics, "CLEANUP_DONE")
      end
    end

    private

    def cleanup(shell, remote_path)
      shell.execute("rm #{remote_path}")
    rescue IOError, SystemCallError, Shell::Error
      nil
    end

    def trace(diagnostics, event, details = nil)
      return unless diagnostics

      line = "rpremote: run event=#{event}"
      line += ",#{details}" if details
      diagnostics.puts(line)
      diagnostics.flush if diagnostics.respond_to?(:flush)
    end

    def temporary_path
      RUN_REMOTE_PATH
    end
  end
end
