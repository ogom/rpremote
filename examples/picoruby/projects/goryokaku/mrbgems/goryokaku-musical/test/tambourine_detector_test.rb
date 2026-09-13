# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuMusicalTambourineDetectorTest < Picotest::Test
  def detector(mode = :musical)
    Goryokaku::Musical::TambourineDetector.new(
      application_mode: mode, orientation_stable_ms: 100,
      shake_threshold: 0.2, shake_window_ms: 250, shake_reversals: 2, shake_retrigger_ms: 100,
      strike_threshold: 0.45, strike_release_threshold: 0.15, strike_retrigger_ms: 120
    )
  end

  def sample(target, now, x, y, z)
    target.on_event([:motion_sample, now, [x, y, z], [0.0, 0.0, 0.0]])
  end

  def test_requires_stable_y_up
    target = detector
    assert_equal nil, target.on_event([:orientation_changed, :z_up])
    assert_equal nil, sample(target, 0, 1.0, 0.0, 0.0)
    target.on_event([:orientation_changed, :y_up])
    assert_equal nil, sample(target, 0, 1.0, 1.0, 0.0)
    assert_equal nil, sample(target, 99, -1.0, 1.0, 0.0)
  end

  def test_detects_two_smooth_z_reversals_as_a_shake
    target = detector
    target.on_event([:orientation_changed, :y_up])
    sample(target, 0, 0.0, 1.0, 0.0)
    sample(target, 100, 0.0, 1.0, 0.0)
    assert_equal nil, sample(target, 120, 0.0, 1.0, 0.32)
    assert_equal nil, sample(target, 140, 0.0, 1.0, 0.10)
    assert_equal nil, sample(target, 160, 0.0, 1.0, -0.10)
    assert_equal nil, sample(target, 180, 0.0, 1.0, -0.32)
    assert_equal nil, sample(target, 200, 0.0, 1.0, -0.10)
    assert_equal nil, sample(target, 220, 0.0, 1.0, 0.10)
    event = sample(target, 240, 0.0, 1.0, 0.32)
    assert_equal :tambourine_shaken, event[0]
    assert_equal 240, event[1]
    assert_in_delta 0.6, event[2]
    assert_equal :right, event[3]
    assert_equal 100, event[4]
  end

  def test_detects_one_z_impact_and_waits_for_release
    target = detector
    target.on_event([:orientation_changed, :y_up])
    sample(target, 0, 0.0, 1.0, 0.0)
    sample(target, 100, 0.0, 1.0, 0.0)
    event = sample(target, 120, 0.0, 1.0, 0.5625)
    assert_equal :tambourine_struck, event[0]
    assert_equal 120, event[1]
    assert_in_delta 0.25, event[2]
    assert_equal 120, event[3]
    assert_equal nil, sample(target, 140, 0.0, 1.0, 1.125)
    assert_equal nil, sample(target, 160, 0.0, 1.0, 1.125)
  end

  def test_combined_requires_tambourine_confirmation
    target = detector(:combined)
    target.on_event([:orientation_changed, :y_up])
    sample(target, 0, 0.0, 1.0, 0.0)
    sample(target, 100, 0.0, 1.0, 0.0)
    assert_equal nil, sample(target, 120, 0.0, 1.0, 0.5625)
    target.on_event([:mode_changed, :tambourine])
    sample(target, 140, 0.0, 1.0, 0.0)
    sample(target, 240, 0.0, 1.0, 0.0)
    event = sample(target, 260, 0.0, 1.0, 0.5625)
    assert_equal :tambourine_struck, event[0]
    assert_equal 260, event[1]
    assert_in_delta 0.25, event[2]
    assert_equal 120, event[3]
  end

  def test_ignores_motion_below_the_weak_play_thresholds
    target = detector
    target.on_event([:orientation_changed, :y_up])
    sample(target, 0, 0.0, 1.0, 0.0)
    sample(target, 100, 0.0, 1.0, 0.0)

    assert_equal nil, sample(target, 120, 0.0, 1.0, 0.15)
    assert_equal nil, sample(target, 140, 0.0, 1.0, -0.15)
    assert_equal nil, sample(target, 160, 0.0, 1.0, 0.15)
  end
end
