# frozen_string_literal: true

require_relative "test_helper"

class FakeTambourineGestureDetector
  attr_reader :reset_called
  def on_event(event); [:tambourine_struck, event[1], 1.0, 120] if event[0] == :motion_sample; end
  def reset; @reset_called = true; end
end

class FakeTambourineDispatcher
  attr_reader :events
  def initialize; @events = []; end
  def publish(event); @events << event; end
end

class GoryokakuMusicalGesturePublisherTest < Picotest::Test
  def test_publishes_detected_gestures_and_resets
    detector = FakeTambourineGestureDetector.new
    dispatcher = FakeTambourineDispatcher.new
    publisher = Goryokaku::Musical::GesturePublisher.new(detector: detector, dispatcher: dispatcher)

    publisher.on_event([:orientation_changed, :y_up])
    publisher.on_event([:motion_sample, 20, [0.0, 1.0, 1.5], [0.0, 0.0, 0.0]])
    publisher.stop

    assert_equal [[:tambourine_struck, 20, 1.0, 120]], dispatcher.events
    assert detector.reset_called
  end
end
