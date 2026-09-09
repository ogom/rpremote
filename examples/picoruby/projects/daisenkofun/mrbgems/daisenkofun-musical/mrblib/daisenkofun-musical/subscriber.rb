# frozen_string_literal: true

module Daisenkofun
  module Musical
    # Queues sensor state updates; PWM users may opt into immediate beat output.
    class Subscriber
      def initialize(output: Outputs::Null.new, logger: nil, immediate_beat: false)
        @output = output
        @logger = logger
        @immediate_beat = immediate_beat
        @pending_events = []
        @finger_present = nil
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
        return self unless @started && !@stopped

        if event == :finger_removed
          @finger_present = false
          @pending_events.clear
          @output.reset(event)
        elsif event == :finger_detected
          @finger_present = true
          @pending_events.clear
          @output.reset(event)
        elsif event == :beat
          return self if @finger_present == false

          if @immediate_beat
            @output.beat(payload)
            @output.tick(payload[:timestamp_ms])
          else
            @pending_events << [event, payload]
          end
        elsif event == :measurement_updated
          @pending_events << [event, payload]
        end
        self
      rescue => error
        stop
        raise error
      end

      def tick(now)
        return self unless @started && !@stopped

        @pending_events.each do |event, payload|
          if event == :beat
            @output.beat(payload)
          elsif event == :measurement_updated
            @output.measurement(payload)
          end
        end
        @pending_events.clear
        @output.tick(now)
        self
      rescue => error
        stop
        raise error
      end

      def stop
        return self if @stopped

        begin
          @output.stop
        ensure
          @pending_events.clear
          @finger_present = nil
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
