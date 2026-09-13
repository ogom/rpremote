# frozen_string_literal: true
require_relative "test_helper"

class GoryokakuInteractionDetectorTest < Picotest::Test
  def test_detects_edges_and_orientation_changes
    detector = Goryokaku::Interaction::Detector.new(vertical_threshold: 0.7, horizontal_threshold: 0.7)
    assert_equal [:orientation_changed, :z_up], detector.prime([0.0, 0.0, 1.0])
    events = detector.detect(0, [1.0, 0.0, 0.0])
    assert_equal [[:orientation_changed, :x_up], [:touch_pressed]], events
    assert_equal [], detector.detect(0, [1.0, 0.0, 0.0])
  end


  def test_distinguishes_y_up_from_z_up
    detector = Goryokaku::Interaction::Detector.new(vertical_threshold: 0.7, horizontal_threshold: 0.7)
    assert_equal [:orientation_changed, :y_up], detector.prime([0.0, 1.0, 0.0])
    assert_equal [[:orientation_changed, :z_up]], detector.detect(1, [0.0, 0.0, 1.0])
  end

  def test_does_not_treat_downward_axes_as_up
    detector = Goryokaku::Interaction::Detector.new(vertical_threshold: 0.7, horizontal_threshold: 0.7)
    assert_equal [:orientation_changed, :unknown], detector.prime([0.0, -1.0, 0.0])
    assert_equal [], detector.detect(1, [0.0, 0.0, -1.0])
  end
end
