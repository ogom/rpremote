# frozen_string_literal: true
module Goryokaku
  module Interaction
    class Runner
      def initialize(
        device:, detector:, dispatcher:, logger:,
        heartbeat_interval_ms: 5_000, mode_selection: true,
        application_mode: :combined
      )
        @device = device
        @detector = detector
        @dispatcher = dispatcher
        @logger = logger
        @heartbeat_interval_ms = heartbeat_interval_ms
        @last_heartbeat_ms = 0
        @running = false
        @mode = :illumination
        @selected_mode = nil
        @orientation = nil
        @mode_selection = mode_selection
        @application_mode = application_mode
      end

      def start
        @device.open
        @running = true
        sample = @device.sample
        publish(@detector.prime(sample[:acceleration]))
      end

      def tick(now)
        sample = @device.sample
        events = @detector.detect(@device.touch_state, sample[:acceleration])
        index = 0
        while index < events.length
          publish(events[index])
          index += 1
        end
        publish([:motion_sample, now, sample[:acceleration], sample[:gyroscope]])
        if now - @last_heartbeat_ms >= @heartbeat_interval_ms
          @logger.puts("GORYOKAKU mode=#{@application_mode} event=alive")
          @last_heartbeat_ms = now
        end
      end

      def stop; @running = false; @device.close; end
      def running?; @running; end

      private

      def publish(event)
        return unless event
        if event[0] == :orientation_changed
          @orientation = event[1]
          @logger.puts("GORYOKAKU event=orientation mode=#{event[1]}")
        elsif event[0] == :touch_pressed
          return unless @mode_selection
          event = touch_event
          return unless event
        end
        @dispatcher.publish(event)
      end

      def touch_event
        if @orientation == :y_up
          @selected_mode = @selected_mode == :illumination ? :tambourine : :illumination
          @logger.puts("GORYOKAKU event=touch action=select mode=#{@selected_mode}")
          [:mode_selected, @selected_mode]
        elsif @orientation == :z_up
          unless @selected_mode
            @logger.puts("GORYOKAKU event=touch action=ignored reason=no_selection")
            return nil
          end
          @mode = @selected_mode
          @logger.puts("GORYOKAKU event=touch action=confirm mode=#{@mode}")
          [:mode_changed, @mode]
        else
          @logger.puts("GORYOKAKU event=touch action=ignored orientation=#{@orientation}")
          nil
        end
      end
    end
  end
end
