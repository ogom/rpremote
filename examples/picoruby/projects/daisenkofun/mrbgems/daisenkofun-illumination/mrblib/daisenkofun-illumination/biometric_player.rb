# frozen_string_literal: true

module Daisenkofun
  module Illumination
    class BiometricPlayer
      def initialize(device: nil, strip: nil, pattern: nil, logger: nil)
        raise ArgumentError, "device and strip are mutually exclusive" if device && strip

        @device = device || Device.new(strip: strip)
        @pattern = pattern || Biometrics::BeatPulse.new
        @logger = logger
        @started = false
      end

      def start
        return self if @started

        @device.open
        @device.display.clear
        @started = true
        log("DAISENKOFUN mode=combined component=illumination event=start")
        self
      end

      def call(event, payload)
        if event == :beat
          @pattern.beat(payload)
        elsif event == :finger_removed
          @pattern.reset
        end
        self
      end

      def tick(now_ms)
        return self unless @started

        @pattern.tick(@device.display, now_ms)
        self
      end

      def stop
        return self unless @device.open?

        begin
          @device.close
        ensure
          @started = false
          log("DAISENKOFUN mode=combined component=illumination event=stop")
        end
        self
      end

      private

      def log(message)
        if @logger
          @logger.puts(message)
        else
          puts message
        end
      end
    end
  end
end
