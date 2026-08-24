# frozen_string_literal: true

require "io/wait"

module Rpremote
  class Shell
    DEFAULT_TIMEOUT = 10.0
    PROMPT_START = "\e[?25l\e[1G$> \e[0K".b
    PROMPT_END = "\e[?25h".b
    ECHO_START = "\e[?25l\e[1G$> ".b
    ERASE_LINE = "\e[0K".b
    CURSOR_POSITION_QUERY = "\e[6n".b
    CURSOR_POSITION_RESPONSE = "\e[1;1R".b

    class Error < Rpremote::Error; end
    class TimeoutError < Error; end
    class ProtocolError < Error; end
    class CommandError < Error; end

    def self.quote_argument(argument)
      argument = String(argument)
      raise ArgumentError, "shell argument contains a control character" if argument.match?(/[\x00-\x1f\x7f]/)
      return "'#{argument}'" unless argument.include?("'")
      return %("#{argument}") unless argument.include?('"')

      raise ArgumentError, "shell argument cannot contain both quote characters"
    end

    attr_reader :io, :timeout

    def initialize(io, timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "timeout must be positive" unless timeout.positive?

      @io = io
      @timeout = timeout
    end

    def synchronize!
      drain_input
      write_all("\r".b)
      read_until_prompt
      nil
    end

    def execute(command)
      command = validate_command(command)
      send_command(command)
      response = read_until_prompt(after: ECHO_START + command.b + ERASE_LINE)
      extract_output(response, command)
    rescue TimeoutError
      interrupt
      raise
    end

    def send_command(command)
      command = validate_command(command)
      write_all("#{command}\r".b)
      nil
    end

    private

    def validate_command(command)
      command = String(command)
      raise ArgumentError, "shell command must not be empty" if command.empty?
      raise ArgumentError, "shell command contains a control character" if command.match?(/[\x00-\x1f\x7f]/)

      command
    end

    def read_until_prompt(wait: timeout, after: nil)
      deadline = monotonic_time + wait
      buffer = +"".b
      loop do
        boundary = after ? buffer.index(after) : 0
        prompt_at = buffer.index(PROMPT_START, boundary + (after&.bytesize || 0)) if boundary
        return buffer if prompt_at && buffer.index(PROMPT_END, prompt_at + PROMPT_START.bytesize)

        buffer << read_available(deadline)
        answer_terminal_queries(buffer)
      end
    end

    def extract_output(response, command)
      echo = ECHO_START + command.b + ERASE_LINE
      echo_at = response.rindex(echo)
      raise ProtocolError, "R2P2 Shell did not echo the command" unless echo_at

      prompt_at = response.index(PROMPT_START, echo_at + echo.bytesize)
      raise ProtocolError, "R2P2 Shell prompt was not found after the command" unless prompt_at

      output_at = response.index("\n", echo_at + echo.bytesize)
      raise ProtocolError, "R2P2 Shell response has no command boundary" unless output_at

      response.byteslice((output_at + 1)...prompt_at) || +"".b
    end

    def drain_input
      deadline = monotonic_time + 0.1
      buffer = +"".b
      loop do
        remaining = deadline - monotonic_time
        break unless remaining.positive? && selectable_io.wait_readable(remaining)

        buffer << io.read_nonblock(4096)
      rescue IO::WaitReadable
        next
      rescue EOFError
        raise IOError, "serial connection closed"
      end
      answer_terminal_queries(buffer)
    end

    def read_available(deadline)
      remaining = deadline - monotonic_time
      raise TimeoutError, "timed out waiting for the R2P2 Shell after #{timeout} seconds" unless remaining.positive?
      unless selectable_io.wait_readable(remaining)
        raise TimeoutError, "timed out waiting for the R2P2 Shell after #{timeout} seconds"
      end

      data = io.read_nonblock(4096)
      raise IOError, "serial connection closed" if data.nil? || data.empty?

      data
    rescue IO::WaitReadable
      retry
    rescue EOFError
      raise IOError, "serial connection closed"
    end

    def interrupt
      write_all("\x03".b)
      read_until_prompt(wait: [timeout, 1.0].min)
    rescue IOError, SystemCallError, Error
      nil
    end

    def answer_terminal_queries(buffer)
      write_all(CURSOR_POSITION_RESPONSE) while buffer.sub!(CURSOR_POSITION_QUERY, "")
    end

    def write_all(data)
      offset = 0
      while offset < data.bytesize
        written = io.write(data.byteslice(offset..))
        raise IOError, "serial connection closed while writing" unless written&.positive?

        offset += written
      end
      io.flush if io.respond_to?(:flush)
    end

    def selectable_io
      io.respond_to?(:to_io) ? io.to_io : io
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
