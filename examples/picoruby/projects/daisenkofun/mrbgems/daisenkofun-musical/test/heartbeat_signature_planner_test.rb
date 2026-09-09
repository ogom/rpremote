# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunMusicalHeartbeatSignaturePlannerTest < Picotest::Test
  def setup
    @planner = Daisenkofun::Musical::Planners::HeartbeatSignature.new
  end

  def signature(intervals, ratios, spo2_values)
    cues = nil
    intervals.each_with_index do |interval, index|
      at = 1_000 + index * 900
      @planner.measurement(timestamp_ms: at, spo2: spo2_values[index])
      cues = @planner.plan({ timestamp_ms: at, interval_ms: interval, pulse_width_ratio: ratios[index] }, at)
    end
    cues
  end

  def test_uses_canon_for_seven_beats_then_builds_an_eight_note_signature
    7.times do |index|
      cues = @planner.plan({ timestamp_ms: index * 800, interval_ms: 800 }, index * 800)
      assert_equal 3, cues.length
      assert_nil cues[0][:source]
    end
    cues = @planner.plan({ timestamp_ms: 5_600, interval_ms: 800 }, 5_600)
    assert_equal 8, cues.length
    assert_equal 8, cues.count { |cue| cue[:source] == :heartbeat_signature }
    assert_equal 1, @planner.signature_count

    cues = @planner.plan({ timestamp_ms: 6_400, interval_ms: 800 }, 6_400)
    assert_equal 3, cues.length
    assert_nil cues[0][:source]
  end

  def test_same_eight_beats_always_generate_the_same_signature
    intervals = [820, 780, 760, 840, 800, 740, 860, 790]
    ratios = [0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55]
    spo2 = [97.0, 97.2, 97.7, 97.8, 97.4, 96.3, 96.2, 97.0]
    first = signature(intervals, ratios, spo2)
    @planner.reset
    second = signature(intervals, ratios, spo2)

    fields = [:frequency_hz, :duration_ms, :duty_percent, :moat]
    assert_equal first.map { |cue| fields.map { |field| cue[field] } }, second.map { |cue| fields.map { |field| cue[field] } }
  end

  def test_interval_spo2_and_pulse_width_change_pitch_rhythm_and_duty
    cues = signature(
      [800, 740, 900, 780, 820, 700, 880, 760],
      [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 0.3, 0.7],
      [97.0, 97.8, 96.0, 98.0, 97.0, 98.0, 96.0, 97.7]
    )

    assert cues.map { |cue| cue[:frequency_hz] }.uniq.length > 1
    assert cues.map { |cue| cue[:duration_ms] }.uniq.length > 1
    assert cues.map { |cue| cue[:duty_percent] }.uniq.length > 1
    assert_equal 8, cues.length
    assert_equal [:inner, :middle, :outer, :inner], cues[0, 4].map { |cue| cue[:moat] }
  end

  def test_reset_discards_a_partial_signature
    7.times do |index|
      @planner.plan({ timestamp_ms: index * 800, interval_ms: 800 }, index * 800)
    end
    @planner.reset
    cues = @planner.plan({ timestamp_ms: 8_000, interval_ms: 800 }, 8_000)

    assert_equal 3, cues.length
    assert_equal 0, @planner.signature_count
  end

  def test_reset_keeps_the_completed_signature_count_for_the_run_summary
    8.times do |index|
      @planner.plan({ timestamp_ms: index * 800, interval_ms: 800 }, index * 800)
    end
    @planner.reset

    assert_equal 1, @planner.signature_count
    cues = @planner.plan({ timestamp_ms: 8_000, interval_ms: 800 }, 8_000)
    assert_equal 3, cues.length
  end
end
