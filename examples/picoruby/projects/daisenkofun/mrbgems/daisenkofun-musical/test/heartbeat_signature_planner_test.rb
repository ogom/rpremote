# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunMusicalHeartbeatSignaturePlannerTest < Picotest::Test
  def setup
    @planner = Daisenkofun::Musical::Planners::HeartbeatSignature.new
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

  def test_reset_discards_a_partial_signature
    7.times do |index|
      @planner.plan({ timestamp_ms: index * 800, interval_ms: 800 }, index * 800)
    end
    @planner.reset
    cues = @planner.plan({ timestamp_ms: 8_000, interval_ms: 800 }, 8_000)

    assert_equal 3, cues.length
    assert_equal 0, @planner.signature_count
  end

end
