# frozen_string_literal: true

module Daisenkofun
  # Cooperative loop: publisher work first, then one short component tick each.
  class EventLoop
    DEFAULT_INTERVAL_MS = 2
    DEFAULT_WARNING_MS = 25

    attr_reader :max_tick_ms

    def initialize(
      publisher:,
      components: [],
      clock:,
      logger:,
      mode:,
      interval_ms: DEFAULT_INTERVAL_MS,
      warning_ms: DEFAULT_WARNING_MS
    )
      @publisher = publisher
      @components = components
      @clock = clock
      @logger = logger
      @mode = mode
      @interval_ms = interval_ms
      @warning_ms = warning_ms
      @started_components = 0
      @max_tick_ms = 0
    end

    def run
      begin
        start_all
        while @publisher.running?
          started_at = @clock.millis
          @publisher.tick(started_at)
          tick_components(started_at) if @publisher.running?
          record_tick_duration(started_at)
          @clock.wait_ms(@interval_ms) if @publisher.running?
        end
        @publisher.result
      ensure
        stop_all
      end
    end

    private

    def start_all
      while @started_components < @components.length
        component = @components[@started_components]
        @started_components += 1
        component.start
      end
      @publisher.start
    end

    def stop_all
      cleanup_error = nil
      begin
        @publisher.stop
      rescue => error
        cleanup_error = error
      end

      index = @started_components - 1
      while index >= 0
        begin
          @components[index].stop
        rescue => error
          cleanup_error ||= error
        end
        index -= 1
      end
      @started_components = 0
      raise cleanup_error if cleanup_error
    end

    def tick_components(timestamp_ms)
      index = 0
      while index < @components.length
        @components[index].tick(timestamp_ms)
        index += 1
      end
    end

    def record_tick_duration(started_at)
      elapsed = @clock.millis - started_at
      return unless elapsed > @max_tick_ms

      @max_tick_ms = elapsed
      return unless elapsed > @warning_ms

      @logger.puts(
        "DAISENKOFUN mode=#{@mode} event=loop_warning " \
        "tick_ms=#{elapsed} warning_ms=#{@warning_ms}"
      )
    end
  end
end
