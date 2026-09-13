# frozen_string_literal: true

require_relative "test_helper"
require "goryokaku-interaction/runner"

class FakeInteractionDevice
  def open; end
  def close; end
  def sample; { acceleration: [0.0, 0.0, 1.0], gyroscope: [1.0, 2.0, 3.0] }; end
  def touch_state; 1; end
end

class FakeInteractionDetector
  attr_accessor :events
  def initialize; @events = []; end
  def prime(_acceleration); nil; end
  def detect(_touch, _acceleration); @events; end
end

class RecordingInteractionDispatcher
  attr_reader :events
  def initialize; @events = []; end
  def publish(event); @events << event; end
end

class RecordingInteractionLogger
  attr_reader :lines
  def initialize; @lines = []; end
  def puts(line); @lines << line; end
end

class GoryokakuInteractionRunnerTest < Picotest::Test
  def test_y_up_selects_and_z_up_confirms_a_mode
    detector = FakeInteractionDetector.new
    dispatcher = RecordingInteractionDispatcher.new
    logger = RecordingInteractionLogger.new
    runner = Goryokaku::Interaction::Runner.new(
      device: FakeInteractionDevice.new,
      detector: detector,
      dispatcher: dispatcher,
      logger: logger
    )
    runner.start

    detector.events = [[:orientation_changed, :y_up], [:touch_pressed]]
    runner.tick(0)
    detector.events = [[:touch_pressed]]
    runner.tick(1)
    detector.events = [[:orientation_changed, :z_up], [:touch_pressed]]
    runner.tick(2)

    assert_equal [
      [:orientation_changed, :y_up],
      [:mode_selected, :illumination],
      [:motion_sample, 0, [0.0, 0.0, 1.0], [1.0, 2.0, 3.0]],
      [:mode_selected, :tambourine],
      [:motion_sample, 1, [0.0, 0.0, 1.0], [1.0, 2.0, 3.0]],
      [:orientation_changed, :z_up],
      [:mode_changed, :tambourine],
      [:motion_sample, 2, [0.0, 0.0, 1.0], [1.0, 2.0, 3.0]]
    ], dispatcher.events
    assert_equal "GORYOKAKU event=touch action=select mode=illumination", logger.lines[1]
    assert_equal "GORYOKAKU event=touch action=select mode=tambourine", logger.lines[2]
    assert_equal "GORYOKAKU event=touch action=confirm mode=tambourine", logger.lines[4]
  end

  def test_touch_is_ignored_outside_y_up_and_z_up
    detector = FakeInteractionDetector.new
    detector.events = [[:orientation_changed, :x_up], [:touch_pressed]]
    dispatcher = RecordingInteractionDispatcher.new
    logger = RecordingInteractionLogger.new
    runner = Goryokaku::Interaction::Runner.new(
      device: FakeInteractionDevice.new,
      detector: detector,
      dispatcher: dispatcher,
      logger: logger
    )
    runner.start
    runner.tick(0)

    assert_equal [
      [:orientation_changed, :x_up],
      [:motion_sample, 0, [0.0, 0.0, 1.0], [1.0, 2.0, 3.0]]
    ], dispatcher.events
    assert_equal "GORYOKAKU event=touch action=ignored orientation=x_up", logger.lines[1]
  end
end
