# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Outputs
      # Plays one non-overlapping PWM voice for each of the three moat cues.
      class KofunCanon
      attr_reader :cue_count, :max_delay_ms, :planner

      def initialize(pin: 18, clock:, logger: nil, pwm: nil, planner: nil)
        @pin = pin
        @clock = clock
        @logger = logger
        @pwm = pwm
        @planner = planner || Planners::KofunCanon.new
        @started = false
        @cues = []
        @cue_index = 0
        @off_at = nil
        @last_beat_at = nil
        @cue_count = 0
        @max_delay_ms = 0
      end

      def start
        return self if @started

        unless @pwm
          require "pwm"
          @pwm = ::PWM.new(@pin, frequency: 330, duty: 0)
        end
        @pwm.duty(0)
        @started = true
        self
      end

      def measurement(payload)
        @planner.measurement(payload)
        self
      end

      def beat(payload)
        at = payload[:timestamp_ms]
        return self unless at.is_a?(Integer)
        return self if @last_beat_at && at <= @last_beat_at

        received_at = @clock.millis
        cues = @planner.plan(payload, received_at)
        return self unless cues

        @last_beat_at = at
        @cues = cues
        @cue_index = 0
        @off_at = nil
        @pwm.duty(0) if @pwm
        self
      end

      def reset(reason = nil)
        @cues = []
        @cue_index = 0
        @off_at = nil
        @last_beat_at = nil
        @planner.reset
        @pwm.duty(0) if @pwm
        log("DAISENKOFUN component=kofun_canon event=reset reason=#{reason}") if reason
        self
      end

      def tick(_now)
        return self unless @started

        now = @clock.millis
        if @cue_index < @cues.length && now >= @cues[@cue_index][:due_ms]
          cue = @cues[@cue_index]
          @cue_index += 1
          sound(cue) if now - cue[:due_ms] <= 100
        end
        if @off_at && @clock.millis >= @off_at
          @pwm.duty(0)
          @off_at = nil
        end
        self
      rescue => error
        stop
        raise error
      end

      def stop
        @started = false
        reset(:stop)
      end

      def verification(min_cues: 15, max_delay_ms: 25)
        Musical::PerformanceVerification.canon(self, min_cues: min_cues, max_delay_ms: max_delay_ms)
      end

      private

      def sound(cue)
        @pwm.duty(0)
        @pwm.frequency(cue[:frequency_hz])
        @pwm.duty(cue[:duty_percent])
        started_at = @clock.millis
        delay = started_at - cue[:due_ms]
        @off_at = started_at + cue[:duration_ms]
        @cue_count += 1
        @max_delay_ms = delay if delay > @max_delay_ms
        log(
          "DAISENKOFUN component=kofun_canon event=note source=#{cue[:source] || :canon} " \
          "phrase=#{cue[:phrase]} slot=#{cue[:slot]} moat=#{cue[:moat]} beat_ms=#{cue[:beat_ms]} scheduled_ms=#{cue[:due_ms]} " \
          "started_ms=#{started_at} delay_ms=#{delay} frequency_hz=#{cue[:frequency_hz]} duration_ms=#{cue[:duration_ms]} " \
          "duty_percent=#{cue[:duty_percent]} pulse_width_ratio=#{cue[:pulse_width_ratio]} " \
          "spo2_direction=#{cue[:direction]} travel_direction=#{cue[:travel_direction]} order=#{cue[:phrase_order].join(',')}"
        )
      end

      def log(message)
        @logger.puts(message) if @logger
      end
      end
    end
  end
end
