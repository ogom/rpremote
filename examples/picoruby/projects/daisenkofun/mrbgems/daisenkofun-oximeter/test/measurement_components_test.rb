# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterMeasurementComponentsTest < Picotest::Test
  def test_finger_detector_applies_hysteresis
    detector = Daisenkofun::Oximeter::Measurement::FingerDetector.new(
      threshold: 100,
      hysteresis: 10
    )

    assert_nil detector.update(110)
    assert_equal :detected, detector.update(111)
    assert detector.present?
    assert_nil detector.update(90)
    assert_equal :removed, detector.update(89)
    assert_false detector.present?
  end

  def test_beat_detector_reports_interval_and_validity
    detector = Daisenkofun::Oximeter::Measurement::BeatDetector.new(
      smooth_samples: 1,
      baseline_samples: 2,
      hysteresis: 5,
      min_interval_ms: 100,
      max_interval_ms: 1_000,
      stabilize_ms: 0
    )
    detector.start(0)

    assert_nil detector.process_sample(ir: 100, timestamp_ms: 0)
    assert_nil detector.process_sample(ir: 110, timestamp_ms: 200)
    beat = detector.process_sample(ir: 90, timestamp_ms: 600)
    assert_equal 600, beat[:interval_ms]
    assert beat[:accepted]
  end

  def test_spo2_estimator_buffers_and_clamps_an_estimate
    estimator = Daisenkofun::Oximeter::Measurement::SpO2Estimator.new(signal_samples: 3)

    estimator.push(100, 200)
    estimator.push(110, 205)
    assert_nil estimator.estimate
    estimator.push(90, 195)
    estimate = estimator.estimate
    assert estimate >= 0.0
    assert estimate <= 100.0
  end

  def test_session_reports_completion_once
    session = Daisenkofun::Oximeter::Measurement::Session.new(result_samples: 3)

    bpm = session.record_beat(600)
    assert_nil session.record_spo2(98.0, bpm: bpm)
    bpm = session.record_beat(600)
    assert_nil session.record_spo2(97.0, bpm: bpm)
    bpm = session.record_beat(600)
    result = session.record_spo2(99.0, bpm: bpm)
    assert result[:complete]
    assert result[:completed_now]

    bpm = session.record_beat(600)
    result = session.record_spo2(98.0, bpm: bpm)
    assert result[:complete]
    assert_false result[:completed_now]
  end
end
