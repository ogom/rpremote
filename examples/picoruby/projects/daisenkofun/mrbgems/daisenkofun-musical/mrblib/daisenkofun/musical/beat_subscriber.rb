# frozen_string_literal: true

module Daisenkofun
  module Musical
    # Defers beat output to tick so publishing a sensor event stays short.
    class BeatSubscriber
      def initialize(output: NullOutput.new, logger: nil)
        @output = output
        @logger = logger
        @pending_beat = nil
        @started = false
        @stopped = false
      end

      def start
        return self if @started

        @output.start
        @started = true
        @stopped = false
        log("DAISENKOFUN mode=combined component=musical event=start")
        self
      end

      def call(event, payload)
        @pending_beat = payload if event == :beat
        self
      end

      def tick(now)
        return self unless @started && !@stopped

        if @pending_beat
          payload = @pending_beat
          @pending_beat = nil
          @output.beat(payload)
        end
        @output.tick(now)
        self
      end

      def stop
        return self if @stopped

        begin
          @output.stop
        ensure
          @pending_beat = nil
          @started = false
          @stopped = true
          log("DAISENKOFUN mode=combined component=musical event=stop")
        end
        self
      end

      private

      def log(message)
        @logger.puts(message) if @logger
      end
    end
  end
end
