# frozen_string_literal: true

require_relative "test_helper"
require_relative "pattern_baselines"

class GoryokakuIlluminationPatternsTest < Picotest::Test
  def test_all_patterns_match_saved_frames
    keys = Goryokaku::Illumination::Setlist::PATTERNS.map { |entry| entry[Goryokaku::Illumination::Setlist::KEY] }
    assert_equal keys.sort, PATTERN_BASELINES.keys.sort

    keys.each do |key|
      strip = PatternCapture.call(key)
      assert_equal [key, PATTERN_BASELINES[key]], [key, [strip.frame_count, strip.checksum]]
      assert_equal [key, []], [key, strip.invalid_indices]
    end
  end
end
