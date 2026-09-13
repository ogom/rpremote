# frozen_string_literal: true

module Goryokaku
  module Runtime
    class EventLoop
      def initialize(publisher:, components:, clock:, interval_ms: 20)
        @publisher = publisher
        @components = components
        @clock = clock
        @interval_ms = interval_ms
        @started = 0
      end

      def call(iterations: nil)
        count = 0
        begin
          start_all
          while @publisher.running? && (!iterations || count < iterations)
            now = @clock.millis
            @publisher.tick(now)
            tick_components(now)
            count += 1
            @clock.wait_ms(@interval_ms) if @publisher.running? && (!iterations || count < iterations)
          end
        ensure
          stop_all
        end
      end

      private

      def start_all
        while @started < @components.length
          @components[@started].start
          @started += 1
        end
        @publisher.start
      end

      def tick_components(now)
        index = 0
        while index < @components.length
          @components[index].tick(now)
          index += 1
        end
      end

      def stop_all
        error = nil
        begin
          @publisher.stop
        rescue => failure
          error = failure
        end
        index = @started - 1
        while index >= 0
          begin
            @components[index].stop
          rescue => failure
            error ||= failure
          end
          index -= 1
        end
        @started = 0
        raise error if error
      end
    end
  end
end
