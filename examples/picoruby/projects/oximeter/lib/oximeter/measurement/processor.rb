# frozen_string_literal: true

require "/lib/oximeter/config"
require "/lib/oximeter/dispatcher"
require "/lib/oximeter/measurement/beat_detector"
require "/lib/oximeter/measurement/events"
require "/lib/oximeter/measurement/finger_detector"
require "/lib/oximeter/measurement/session"
require "/lib/oximeter/measurement/spo2_estimator"

module Oximeter
  module Measurement
    class Processor
      attr_reader :latest_bpm, :latest_spo2

      def initialize(
        dispatcher: Oximeter::Dispatcher.new,
        logger: nil,
        finger_detector: FingerDetector.new,
        beat_detector: BeatDetector.new,
        spo2_estimator: SpO2Estimator.new,
        session: Session.new
      )
        @dispatcher = dispatcher
        @logger = logger
        @finger_detector = finger_detector
        @beat_detector = beat_detector
        @spo2_estimator = spo2_estimator
        @session = session
        @latest_bpm = 0.0
        @latest_spo2 = 0.0
        @last_wait_log = 0
      end

      def process_sample(red:, ir:, timestamp_ms:)
        update_finger(ir, timestamp_ms)
        unless @finger_detector.present?
          log_wait(red, ir, timestamp_ms)
          return self
        end

        @spo2_estimator.push(red, ir)
        beat = @beat_detector.process_sample(ir: ir, timestamp_ms: timestamp_ms)
        return self unless beat

        unless beat[:accepted]
          log("OXIMETER_BEAT,#{timestamp_ms},SKIPPED,interval_ms=#{beat[:interval_ms]}")
          return self
        end

        bpm = @session.record_beat(beat[:interval_ms])
        @dispatcher.publish(Events::BEAT, {
          timestamp_ms: timestamp_ms,
          red: red,
          ir: ir,
          interval_ms: beat[:interval_ms],
          bpm: bpm
        })
        spo2 = @spo2_estimator.estimate
        unless spo2
          log(
            "OXIMETER_BEAT,#{timestamp_ms},BUFFERING," \
              "signal_samples=#{@spo2_estimator.count}/#{Config::SIGNAL_SAMPLES}"
          )
          return self
        end

        result = @session.record_spo2(spo2, bpm: bpm)
        return self unless result

        @latest_bpm = result[:bpm]
        @latest_spo2 = result[:spo2]
        state = result[:complete] ? "RESULT" : "MEASURING"
        log(sprintf(
          "OXIMETER_DATA,%d,%d,%d,%.1f,%.1f,%s",
          timestamp_ms, red, ir, @latest_bpm, @latest_spo2, state
        ))
        payload = {
          timestamp_ms: timestamp_ms,
          red: red,
          ir: ir,
          bpm: @latest_bpm,
          spo2: @latest_spo2
        }
        @dispatcher.publish(Events::MEASUREMENT_UPDATED, payload)
        @dispatcher.publish(Events::MEASUREMENT_COMPLETED, payload) if result[:completed_now]
        self
      end

      private

      def update_finger(ir, timestamp_ms)
        transition = @finger_detector.update(ir)
        if transition == :removed
          reset_measurement
          log("OXIMETER_FINGER,#{timestamp_ms},REMOVED,ir=#{ir}")
          @dispatcher.publish(Events::FINGER_REMOVED, {
            timestamp_ms: timestamp_ms,
            ir: ir
          })
        elsif transition == :detected
          reset_measurement
          @beat_detector.start(timestamp_ms)
          log("OXIMETER_FINGER,#{timestamp_ms},DETECTED,ir=#{ir}")
          @dispatcher.publish(Events::FINGER_DETECTED, {
            timestamp_ms: timestamp_ms,
            ir: ir
          })
        end
      end

      def log_wait(red, ir, timestamp_ms)
        return unless timestamp_ms - @last_wait_log >= 1_000

        log("OXIMETER_WAIT,#{timestamp_ms},red=#{red},ir=#{ir}")
        @last_wait_log = timestamp_ms
      end

      def reset_measurement
        @beat_detector.clear
        @spo2_estimator.clear
        @session.clear
        @latest_bpm = 0.0
        @latest_spo2 = 0.0
      end

      def log(message)
        @logger.puts(message) if @logger
      end
    end
  end
end
