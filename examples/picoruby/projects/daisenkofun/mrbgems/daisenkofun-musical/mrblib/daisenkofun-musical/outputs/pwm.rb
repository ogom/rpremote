# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Outputs
      # Single-voice, nonblocking call and response. Hardware is acquired at start.
      class PWM
      attr_reader :baseline_count, :main_note_count, :max_main_delay_ms, :pulse_timbre_count, :min_duty_percent, :max_duty_percent

      def initialize(pin: 18, duty: 3, clock:, logger: nil, pwm: nil, timbre_translator: nil)
        @pin = pin
        @clock = clock
        @logger = logger
        @pwm = pwm
        @translator = Translators::Pulse.new
        @timbre_translator = timbre_translator || Translators::Timbre.new(default_duty: duty)
        @started = false
        @pending = nil
        @response = nil
        @off_at = nil
        @last_beat_at = nil
        @baseline_count = 0
        @main_note_count = 0
        @max_main_delay_ms = 0
        @pulse_timbre_count = 0
        @min_duty_percent = nil
        @max_duty_percent = nil
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
        previous_baseline = @translator.baseline
        @translator.measurement(payload)
        if !previous_baseline && @translator.baseline
          @baseline_count += 1
          log("DAISENKOFUN component=musical event=baseline timestamp_ms=#{payload[:timestamp_ms]} spo2=#{@translator.baseline}")
        end
        self
      end

      def beat(payload)
        at = payload[:timestamp_ms]
        return self unless at.is_a?(Integer)
        return self if @last_beat_at && at <= @last_beat_at

        interval = payload[:interval_ms]
        notes = @translator.notes(interval, at)
        return self unless notes

        received_at = @clock.millis
        timbre = @timbre_translator.translate(payload)
        @last_beat_at = at
        @pending = [at, received_at, interval, notes, @translator.direction, timbre]
        @response = nil
        self
      end

      def reset(reason = nil)
        @pending = nil
        @response = nil
        @off_at = nil
        @last_beat_at = nil
        @translator.reset
        @pwm.duty(0) if @pwm
        log("DAISENKOFUN component=musical event=reset reason=#{reason}") if reason
        self
      end

      def tick(_now)
        return self unless @started

        # Read after sensor/LED work, not the event loop's earlier timestamp.
        now = @clock.millis
        if @pending
          at, received_at, interval, notes, direction, timbre = @pending
          @pending = nil
          @pwm.duty(0)
          @off_at = nil
          # Do not turn an old, buffered beat into a fresh audible heartbeat.
          if now >= at && now - at <= 100
            duration = interval / 5
            duration = 120 if duration > 120
            sound(notes[0], duration, :main, at, received_at, direction, timbre)
            @response = [received_at + interval / 2, at, notes[1], duration, direction, timbre]
          end
        elsif @response && now >= @response[0]
          due, at, frequency, duration, direction, timbre = @response
          @response = nil
          sound(frequency, duration, :response, at, due, direction, timbre) if now - due <= 100
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

      def verification(min_main_notes: 10, max_main_delay_ms: 25, min_baselines: 2, min_pulse_notes: 10)
        Musical::PerformanceVerification.pulse(
          self,
          min_main_notes: min_main_notes,
          max_main_delay_ms: max_main_delay_ms,
          min_baselines: min_baselines,
          min_pulse_notes: min_pulse_notes
        )
      end

      private

      def log(message)
        @logger.puts(message) if @logger
      end

      def sound(frequency, duration, role, beat_at, scheduled_at, direction, timbre)
        @pwm.duty(0)
        @pwm.frequency(frequency)
        @pwm.duty(timbre[:duty_percent])
        started_at = @clock.millis
        delay = started_at - scheduled_at
        @off_at = started_at + duration
        if role == :main
          @main_note_count += 1
          @max_main_delay_ms = delay if delay > @max_main_delay_ms
          if timbre[:pulse_width_ratio]
            @pulse_timbre_count += 1
            duty = timbre[:duty_percent]
            @min_duty_percent = duty if !@min_duty_percent || duty < @min_duty_percent
            @max_duty_percent = duty if !@max_duty_percent || duty > @max_duty_percent
          end
        end
        log(
          "DAISENKOFUN component=musical event=note role=#{role} beat_ms=#{beat_at} scheduled_ms=#{scheduled_at} started_ms=#{started_at} " \
          "delay_ms=#{delay} sensor_age_ms=#{started_at - beat_at} frequency_hz=#{frequency} duration_ms=#{duration} direction=#{direction} " \
          "duty_percent=#{timbre[:duty_percent]} pulse_width_ratio=#{timbre[:pulse_width_ratio]} " \
          "pulse_width_ms=#{timbre[:pulse_width_ms]} pulse_amplitude=#{timbre[:pulse_amplitude]} pulse_samples=#{timbre[:pulse_samples]}"
        )
      end
      end
    end
  end
end
