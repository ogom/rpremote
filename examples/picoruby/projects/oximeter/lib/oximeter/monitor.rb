# frozen_string_literal: true

require '/lib/oximeter/config'
require '/lib/oximeter/rolling_statistics'

module Oximeter
  class Monitor
    attr_reader :latest_bpm, :latest_spo2

    def initialize(status_leds:)
      @status_leds = status_leds
      @smooth = RollingStatistics.new(Config::SMOOTH_SAMPLES)
      @baseline = RollingStatistics.new(Config::BASELINE_SAMPLES)
      @beats = RollingStatistics.new(Config::RESULT_SAMPLES)
      @spo2_values = RollingStatistics.new(Config::RESULT_SAMPLES)
      @red_signal = RollingStatistics.new(Config::SIGNAL_SAMPLES)
      @ir_signal = RollingStatistics.new(Config::SIGNAL_SAMPLES)
      @finger_present = false
      @finger_detected_at = 0
      @last_beat_at = 0
      @crossed = false
      @latest_bpm = 0.0
      @latest_spo2 = 0.0
      @measurement_complete = false
      @last_wait_log = 0
    end

    def process(red, ir, now)
      update_finger(ir, now)
      unless @finger_present
        log_wait(red, ir, now)
        update_led(:no_finger, now)
        return
      end

      @smooth.push(ir)
      smooth = @smooth.average
      @baseline.push(ir)
      baseline = @baseline.average
      @red_signal.push(red)
      @ir_signal.push(ir)

      if @baseline.count < Config::BASELINE_SAMPLES ||
         now - @finger_detected_at < Config::STABILIZE_MS
        @last_beat_at = now
        update_led(:measuring, now)
        return
      end

      @crossed = false if smooth > baseline + Config::BEAT_HYSTERESIS
      if !@crossed && smooth < baseline - Config::BEAT_HYSTERESIS
        @crossed = true
        detect_beat(red, ir, now)
      end

      update_led(@measurement_complete ? :result : :measuring, now)
    end

    private

    def log_wait(red, ir, now)
      return unless now - @last_wait_log >= 1_000

      puts "OXIMETER_WAIT,#{now},red=#{red},ir=#{ir}"
      @last_wait_log = now
    end

    def update_finger(ir, now)
      if @finger_present
        return unless ir < Config::FINGER_THRESHOLD - Config::FINGER_HYSTERESIS

        @finger_present = false
        reset_measurement
        puts "OXIMETER_FINGER,#{now},REMOVED,ir=#{ir}"
      else
        return unless ir > Config::FINGER_THRESHOLD + Config::FINGER_HYSTERESIS

        @finger_present = true
        @finger_detected_at = now
        @last_beat_at = now
        puts "OXIMETER_FINGER,#{now},DETECTED,ir=#{ir}"
      end
    end

    def detect_beat(red, ir, now)
      interval = now - @last_beat_at
      @last_beat_at = now
      unless interval > Config::MIN_BEAT_INTERVAL_MS &&
             interval < Config::MAX_BEAT_INTERVAL_MS
        puts "OXIMETER_BEAT,#{now},SKIPPED,interval_ms=#{interval}"
        return
      end

      @beats.push(interval)
      bpm = 60_000.0 / @beats.average
      spo2 = estimate_spo2
      unless spo2
        puts "OXIMETER_BEAT,#{now},BUFFERING,signal_samples=#{@red_signal.count}/#{Config::SIGNAL_SAMPLES}"
        return
      end
      @spo2_values.push(spo2)
      return if @beats.count < 3

      @latest_bpm = bpm
      @latest_spo2 = @spo2_values.average
      @measurement_complete = @beats.count >= Config::RESULT_SAMPLES
      state = @measurement_complete ? 'RESULT' : 'MEASURING'
      puts sprintf(
        'OXIMETER_DATA,%d,%d,%d,%.1f,%.1f,%s',
        now, red, ir, @latest_bpm, @latest_spo2, state
      )
    end

    def estimate_spo2
      return nil if @red_signal.count < Config::SIGNAL_SAMPLES ||
                    @ir_signal.count < Config::SIGNAL_SAMPLES

      red_dc = @red_signal.average
      ir_dc = @ir_signal.average
      red_ac = @red_signal.standard_deviation
      ir_ac = @ir_signal.standard_deviation
      return nil if red_dc == 0.0 || ir_dc == 0.0 || ir_ac == 0.0

      ratio = (red_ac / red_dc) / (ir_ac / ir_dc)
      spo2 = Config::SPO2_INTERCEPT - Config::SPO2_RATIO_SCALE * ratio
      spo2 = 0.0 if spo2 < 0.0
      spo2 = 100.0 if spo2 > 100.0
      spo2
    end

    def update_led(mode, now)
      @status_leds.update(
        mode,
        now,
        spo2: @latest_spo2,
        bpm: @latest_bpm,
        last_beat_at: @last_beat_at
      )
    end

    def reset_measurement
      @smooth.clear
      @baseline.clear
      @beats.clear
      @spo2_values.clear
      @red_signal.clear
      @ir_signal.clear
      @crossed = false
      @latest_bpm = 0.0
      @latest_spo2 = 0.0
      @measurement_complete = false
    end
  end
end
