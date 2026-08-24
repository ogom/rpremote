# frozen_string_literal: true

require "open3"

module Rpremote
  class Serial
    BAUD_RATE = 115_200

    class ConfigurationError < Rpremote::Error; end

    def self.open(path, baud: BAUD_RATE)
      port = new(path, baud: baud)
      return port unless block_given?

      begin
        yield port
      ensure
        port.close
      end
    end

    attr_reader :path, :baud, :io

    def initialize(path, baud: BAUD_RATE)
      @path = path
      @baud = Integer(baud)
      configure!
      @io = File.open(path, File::RDWR)
      @io.binmode
      @io.sync = true
    rescue SystemCallError => e
      raise ConfigurationError, "cannot open serial port #{path}: #{e.message}"
    end

    def read_nonblock(length)
      io.read_nonblock(length)
    end

    def write(data)
      io.write(data)
    end

    def flush
      io.flush
    end

    def close
      io.close unless io.closed?
    end

    def closed?
      io.closed?
    end

    def to_io
      io
    end

    private

    def configure!
      output, status = Open3.capture2e(
        "stty", "-f", path, baud.to_s, "cs8", "-cstopb", "-parenb", "raw", "-echo"
      )
      return if status.success?

      raise ConfigurationError, "cannot configure serial port #{path}: #{output.strip}"
    rescue Errno::ENOENT
      raise ConfigurationError, "stty was not found; rpremote currently requires macOS"
    end
  end
end
