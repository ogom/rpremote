# frozen_string_literal: true

require "io/console"

module Rpremote
  class Terminal
    EXIT_BYTE = 0x1D
    BUFFER_SIZE = 4096

    attr_reader :serial_io, :input, :output

    def initialize(serial_io, input: $stdin, output: $stdout, selector: nil)
      @serial_io = serial_io
      @input = input
      @output = output
      @selector = selector || ->(readers) { IO.select(readers) }
    end

    def run(exit_sequence: nil)
      with_raw_input { relay }
    ensure
      leave_interactive_mode(exit_sequence)
    end

    private

    def with_raw_input(&)
      if input.respond_to?(:tty?) && input.tty? && input.respond_to?(:raw)
        input.raw(&)
      else
        yield
      end
    end

    def relay
      readers = [selectable_serial, input]
      loop do
        ready = @selector.call(readers)
        break unless ready

        return if ready.first.any? { |stream| !relay_stream(stream) }
      end
    rescue EOFError, Errno::EIO
      nil
    end

    def relay_stream(stream)
      if stream.equal?(selectable_serial)
        data = serial_io.read_nonblock(BUFFER_SIZE)
        return false if data.nil? || data.empty?

        output.write(normalize_line_endings(data))
        output.flush if output.respond_to?(:flush)
        true
      else
        relay_input?
      end
    rescue IO::WaitReadable
      true
    end

    def relay_input?
      data = input.read_nonblock(BUFFER_SIZE)
      return false if data.nil? || data.empty?

      exit_at = data.index(EXIT_BYTE.chr)
      if exit_at&.positive?
        serial_io.write(data.byteslice(0...exit_at))
        serial_io.flush if serial_io.respond_to?(:flush)
      end
      return false if exit_at

      serial_io.write(data)
      serial_io.flush if serial_io.respond_to?(:flush)
      true
    end

    # input.raw disables the terminal's usual LF-to-CRLF output conversion.
    # Preserve device CRLF while making a bare LF start at the left margin.
    def normalize_line_endings(data)
      normalized = +"".b
      data.each_byte do |byte|
        normalized << "\r" if byte == 0x0A && !@previous_output_was_cr
        normalized << byte
        @previous_output_was_cr = byte == 0x0D
      end
      normalized
    end

    def selectable_serial
      @selectable_serial ||= serial_io.respond_to?(:to_io) ? serial_io.to_io : serial_io
    end

    def leave_interactive_mode(sequence)
      return unless sequence

      serial_io.write(sequence)
      serial_io.flush if serial_io.respond_to?(:flush)
    rescue IOError, SystemCallError
      nil
    end
  end
end
