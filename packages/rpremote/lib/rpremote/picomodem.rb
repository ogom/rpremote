# frozen_string_literal: true

require "io/wait"

module Rpremote
  class PicoModem
    STX = 0x02
    ACK = 0x06

    FILE_READ = 0x01
    FILE_WRITE = 0x02
    DFU_START = 0x03
    CHUNK = 0x04
    ABORT = 0xFF

    FILE_DATA = 0x81
    FILE_ACK = 0x82
    DFU_ACK = 0x83
    CHUNK_ACK = 0x84
    DONE_ACK = 0x8F
    ERROR = 0xFE

    OK = 0x00
    READY = 0x01

    CHUNK_SIZE = 480
    DEFAULT_TIMEOUT = 10.0
    MAX_FRAME_BODY = 65_535
    DFU_MAGIC = "DFU\0".b
    DFU_VERSION = 1
    DFU_TYPES = %w[RUBY RITE].freeze

    class Error < Rpremote::Error; end
    class TimeoutError < Error; end
    class ProtocolError < Error; end
    class ChecksumError < ProtocolError; end
    class DeviceError < Error; end

    attr_reader :io, :timeout

    def initialize(io, timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "timeout must be positive" unless timeout.positive?

      @io = io
      @timeout = timeout
    end

    def upload(path, data)
      path = validate_path(path)
      data = data.b
      in_session do
        send_frame(FILE_WRITE, [data.bytesize].pack("N") + path)
        expect_status(FILE_ACK, READY, "device readiness")
        send_chunks(data)

        status, remote_crc = completion
        raise DeviceError, format("upload failed with status 0x%02x", status) unless status == OK

        local_crc = Checksum.crc32(data)
        raise ChecksumError, checksum_mismatch("CRC32", local_crc, remote_crc, 8) unless remote_crc == local_crc
      end
      data.bytesize
    end

    def download(path)
      path = validate_path(path)
      data = +"".b
      total = nil

      in_session do
        send_frame(FILE_READ, path)
        loop do
          command, payload = receive_frame
          case command
          when FILE_DATA
            if total.nil?
              raise ProtocolError, "first FILE_DATA frame has no size" if payload.bytesize < 4

              total = payload.unpack1("N")
              data << payload.byteslice(4..)
            else
              data << payload
            end
            raise ProtocolError, "received more bytes than declared" if total && data.bytesize > total

            send_frame(CHUNK_ACK, [OK].pack("C"))
          when DONE_ACK
            status, remote_crc = parse_completion(payload)
            raise DeviceError, format("download failed with status 0x%02x", status) unless status == OK
            if total && data.bytesize != total
              raise ProtocolError, "file size mismatch: expected #{total}, received #{data.bytesize}"
            end

            local_crc = Checksum.crc32(data)
            raise ChecksumError, checksum_mismatch("CRC32", local_crc, remote_crc, 8) unless remote_crc == local_crc

            break
          when ERROR
            raise DeviceError, payload.force_encoding(Encoding::UTF_8)
          else
            raise ProtocolError, format("unexpected response 0x%02x during download", command)
          end
        end
      end
      data
    end

    def dfu(data, type:)
      data = data.b
      type = validate_dfu_type(type)
      header = [DFU_MAGIC, DFU_VERSION, type, data.bytesize, Checksum.crc32(data), 0].pack("a4Ca4NNn")
      in_session do
        send_frame(DFU_START, header)
        expect_status(DFU_ACK, READY, "DFU readiness")
        send_chunks(data)
        expect_dfu_completion
      end
      data.bytesize
    end

    def send_frame(command, payload = +"".b)
      body = [command].pack("C") + payload.b
      raise ProtocolError, "frame body is too large" if body.bytesize > MAX_FRAME_BODY

      frame = [STX, body.bytesize].pack("Cn") + body + [Checksum.crc16(body)].pack("n")
      write_all(frame)
      frame.bytesize
    end

    def receive_frame
      deadline = monotonic_time + timeout
      scan_for(STX, deadline, "PicoModem frame")
      length = read_exact(2, deadline).unpack1("n")
      raise ProtocolError, "invalid empty frame" if length.zero?
      raise ProtocolError, "frame body is too large: #{length}" if length > MAX_FRAME_BODY

      body = read_exact(length, deadline)
      expected_crc = read_exact(2, deadline).unpack1("n")
      actual_crc = Checksum.crc16(body)
      raise ChecksumError, checksum_mismatch("CRC16", actual_crc, expected_crc, 4) unless actual_crc == expected_crc

      [body.getbyte(0), body.byteslice(1..) || +"".b]
    end

    private

    def in_session
      entered = false
      completed = false
      enter_mode
      entered = true
      result = yield
      completed = true
      result
    ensure
      abort_transfer if entered && !completed
    end

    def enter_mode
      write_all([STX].pack("C"))
      scan_for(ACK, monotonic_time + timeout, "PicoModem ACK")
    end

    def abort_transfer
      send_frame(ABORT)
    rescue IOError, SystemCallError, Error
      nil
    end

    def completion
      command, payload = receive_frame
      raise DeviceError, payload.force_encoding(Encoding::UTF_8) if command == ERROR
      raise ProtocolError, format("expected DONE_ACK, got 0x%02x", command) unless command == DONE_ACK

      parse_completion(payload)
    end

    def expect_dfu_completion
      command, payload = receive_frame
      raise DeviceError, payload.force_encoding(Encoding::UTF_8) if command == ERROR
      raise ProtocolError, format("expected DFU DONE_ACK, got 0x%02x", command) unless command == DONE_ACK
      raise ProtocolError, "DFU DONE_ACK has no status" if payload.empty?
      return if payload.getbyte(0) == OK

      raise DeviceError, format("DFU failed with status 0x%02x", payload.getbyte(0))
    end

    def parse_completion(payload)
      raise ProtocolError, "DONE_ACK has no CRC32" if payload.bytesize < 5

      payload.unpack("CN")
    end

    def expect_status(expected_command, expected_status, context)
      command, payload = receive_frame
      raise DeviceError, payload.force_encoding(Encoding::UTF_8) if command == ERROR
      unless command == expected_command
        raise ProtocolError, "unexpected response #{hex(command, 2)} while waiting for #{context}"
      end
      raise ProtocolError, "#{context} has no status" if payload.empty?
      return if payload.getbyte(0) == expected_status

      raise DeviceError, "#{context} failed with status #{hex(payload.getbyte(0), 2)}"
    end

    def send_chunks(data)
      offset = 0
      while offset < data.bytesize
        chunk = data.byteslice(offset, CHUNK_SIZE)
        send_frame(CHUNK, chunk)
        expect_status(CHUNK_ACK, OK, "chunk acknowledgement")
        offset += chunk.bytesize
      end
    end

    def validate_dfu_type(type)
      type = String(type).upcase
      return type if DFU_TYPES.include?(type)

      raise ArgumentError, "DFU type must be one of: #{DFU_TYPES.join(", ")}"
    end

    def validate_path(path)
      path = String(path)
      raise ArgumentError, "remote path must be absolute" unless path.start_with?("/")
      raise ArgumentError, "remote path contains a null byte" if path.include?("\0")
      raise ArgumentError, "remote path must not contain .." if path.split("/").include?("..")

      path.b
    end

    def scan_for(byte, deadline, description)
      loop do
        return if read_exact(1, deadline).getbyte(0) == byte
      rescue TimeoutError
        raise TimeoutError, "timed out waiting for #{description}"
      end
    end

    def read_exact(length, deadline)
      buffer = +"".b
      while buffer.bytesize < length
        begin
          remaining = deadline - monotonic_time
          raise TimeoutError, "timed out after #{timeout} seconds" unless remaining.positive?

          wait_readable(remaining)
          chunk = io.read_nonblock(length - buffer.bytesize)
          raise IOError, "serial connection closed" if chunk.nil? || chunk.empty?

          buffer << chunk
        rescue IO::WaitReadable
          next
        rescue EOFError
          raise IOError, "serial connection closed"
        end
      end
      buffer
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

    def wait_readable(timeout_seconds)
      selectable = io.respond_to?(:to_io) ? io.to_io : io
      return unless selectable.respond_to?(:fileno)

      return if selectable.wait_readable(timeout_seconds)

      raise TimeoutError, "timed out after #{timeout} seconds"
    end

    def checksum_mismatch(name, local, remote, width)
      "#{name} mismatch: local=#{hex(local, width)} remote=#{hex(remote, width)}"
    end

    def hex(value, width)
      "0x#{value.to_s(16).rjust(width, "0")}"
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
