# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    class Device
      attr_reader :sensor

      def initialize(sensor: nil, sensor_factory: SensorFactory.new, logger: nil)
        @sensor = sensor
        @sensor_factory = sensor_factory
        @logger = logger
        @open = false
        @closed = false
      end

      def open
        return self if @open

        @sensor ||= @sensor_factory.call
        raise RuntimeError, "sensor factory returned no sensor" unless @sensor

        @open = true
        @closed = false
        self
      rescue
        close
        raise
      end

      def close
        return self if @closed

        begin
          @sensor.shutdown if @sensor
        rescue => error
          @logger.puts("DAISENKOFUN component=oximeter event=shutdown_warning error=#{error.class} message=#{error.message}") if @logger
        ensure
          @open = false
          @closed = true
        end
        self
      end

      def open?
        @open
      end
    end
  end
end
