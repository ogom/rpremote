# frozen_string_literal: true

require_relative "test_helper"
require_relative "pattern_baselines"

class DaisenkofunPatternsTest < Picotest::Test
  def test_all_patterns_match_saved_frames
    keys = Daisenkofun::Setlist::PATTERNS.map { |entry| entry[Daisenkofun::Setlist::KEY] }
    assert_equal keys.sort, PATTERN_BASELINES.keys.sort

    keys.each do |key|
      strip = PatternCapture.call(key)
      expected = PATTERN_BASELINES[key]
      actual = [strip.frame_count, strip.checksum]
      assert_equal [key, expected], [key, actual]
      assert_equal [key, []], [key, strip.invalid_indices]
    end
  end
end
