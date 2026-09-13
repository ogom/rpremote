# frozen_string_literal: true
require_relative "test_helper"

class GoryokakuRuntimeEventLoopTest < Picotest::Test
  class Part
    attr_reader :events
    def initialize(events); @events = events; @running = true; end
    def start; @events << :start; end
    def tick(_now); @events << :tick; end
    def stop; @events << :stop; @running = false; end
    def running?; @running; end
  end
  class Clock
    def millis; 0; end
    def wait_ms(_ms); end
  end

  def test_starts_ticks_and_stops_components
    events = []
    publisher = Part.new(events)
    component = Part.new(events)
    Goryokaku::Runtime::EventLoop.new(publisher: publisher, components: [component], clock: Clock.new).call(iterations: 1)
    assert_equal [:start, :start, :tick, :tick, :stop, :stop], events
  end
end
