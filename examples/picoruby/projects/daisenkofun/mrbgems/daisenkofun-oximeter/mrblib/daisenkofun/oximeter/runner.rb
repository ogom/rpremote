# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    class Runner
      attr_reader :dispatcher, :last_tick_samples, :max_sample_backlog, :processor

      def initialize(
        status_renderer: nil,
        dispatcher: Dispatcher.new,
        sensor: nil,
        sensor_factory: SensorFactory.new,
        clock: BoardClock.new,
        logger: ConsoleLogger.new,
        processor: nil,
        duration_ms: Config::RUN_DURATION_MS,
        poll_interval_ms: Config::POLL_INTERVAL_MS,
        max_samples_per_tick: Config::MAX_SAMPLES_PER_TICK
      )
        @status_renderer = status_renderer || StatusLed::NullRenderer.new
        @dispatcher = dispatcher
        @presenter = StatusLed::Presenter.new(status_renderer) if status_renderer
        @dispatcher.subscribe(@presenter) if @presenter
        @sensor = sensor
        @sensor_factory = sensor_factory
        @clock = clock
        @logger = logger
        @processor = processor
        @duration_ms = duration_ms
        @poll_interval_ms = poll_interval_ms
        @max_samples_per_tick = max_samples_per_tick
        unless @max_samples_per_tick.is_a?(Integer) && @max_samples_per_tick > 0
          raise ArgumentError, "max_samples_per_tick must be a positive Integer"
        end
        @last_tick_samples = 0
        @max_sample_backlog = 0
        @started = false
        @running = false
        @stopped = false
        @sensor_shutdown = false
        @completion_logged = false
      end

      def start
        raise RuntimeError, "oximeter runner has already started" if @started

        @stopped = false
        begin
          @status_renderer.clear
          @sensor ||= @sensor_factory.call
          raise RuntimeError, "sensor factory returned no sensor" unless @sensor

          @sensor_shutdown = false
          @processor ||= Measurement::Processor.new(
            dispatcher: @dispatcher,
            logger: @logger
          )
          @started_at = @clock.millis
          @started = true
          @running = true
          @logger.puts(
            "DAISENKOFUN component=oximeter event=measurement_start " \
            "address=0x57 duration_ms=#{@duration_ms}"
          )
          @logger.puts("DAISENKOFUN component=oximeter event=prompt message=place_fingertip")
          self
        rescue => error
          begin
            @status_renderer.error
            @logger.puts(
              "DAISENKOFUN component=oximeter event=error " \
              "error=#{error.class} message=#{error.message}"
            )
            @clock.wait_ms(Config::ERROR_DISPLAY_MS)
          ensure
            begin
              shutdown_sensor
            ensure
              @status_renderer.clear
              @stopped = true
            end
          end
          raise
        end
      end

      def tick(timestamp_ms = nil)
        raise RuntimeError, "oximeter runner is not running" unless running?

        timestamp_ms ||= @clock.millis
        if timestamp_ms - @started_at >= @duration_ms
          stop
          return self
        end

        available = @sensor.available_samples
        record_sample_backlog(available)
        remaining = available < @max_samples_per_tick ? available : @max_samples_per_tick
        @last_tick_samples = 0
        while remaining > 0
          sample = @sensor.read
          @processor.process_sample(
            red: sample[:red],
            ir: sample[:ir],
            timestamp_ms: timestamp_ms
          )
          @last_tick_samples += 1
          remaining -= 1
        end
        @presenter.tick(timestamp_ms) if @presenter
        self
      end

      def stop
        return self if @stopped

        @running = false
        begin
          shutdown_sensor
        ensure
          @status_renderer.clear
          @stopped = true
        end
        log_completion if @started && !@completion_logged
        self
      end

      def run
        begin
          start
          while running?
            tick(@clock.millis)
            @clock.wait_ms(@poll_interval_ms) if running?
          end
        ensure
          stop
        end
        result
      end

      def running?
        @running
      end

      def result
        return { bpm: 0.0, spo2: 0.0 } unless @processor

        { bpm: @processor.latest_bpm, spo2: @processor.latest_spo2 }
      end

      private

      def record_sample_backlog(available)
        return unless available > @max_sample_backlog

        @max_sample_backlog = available
        return unless available > @max_samples_per_tick

        @logger.puts(
          "DAISENKOFUN component=oximeter event=fifo_backlog " \
          "samples=#{available} per_tick=#{@max_samples_per_tick}"
        )
      end

      def shutdown_sensor
        return unless @sensor && !@sensor_shutdown

        begin
          @sensor.shutdown
        rescue => error
          @logger.puts(
            "DAISENKOFUN component=oximeter event=shutdown_warning " \
            "error=#{error.class} message=#{error.message}"
          )
        ensure
          @sensor_shutdown = true
        end
      end

      def log_completion
        values = result
        @logger.puts(sprintf(
          "DAISENKOFUN component=oximeter event=measurement_done bpm=%.1f spo2=%.1f",
          values[:bpm], values[:spo2]
        ))
        @completion_logged = true
      end
    end
  end
end
