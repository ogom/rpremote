# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunEventLoopFakeLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunEventLoopFakeClock
  def initialize(trace)
    @trace = trace
    @now = 10
  end

  def millis
    @now
  end

  def wait_ms(milliseconds)
    @trace << [:wait, milliseconds]
    @now += milliseconds
  end
end

class DaisenkofunEventLoopFakePublisher
  def initialize(trace, error = nil)
    @trace = trace
    @error = error
    @running = false
    @stopped = false
  end

  def start
    @trace << :publisher_start
    @running = true
  end

  def tick(now)
    @trace << [:publisher_tick, now]
    raise @error if @error

    @running = false
  end

  def running?
    @running
  end

  def result
    :result
  end

  def stop
    return if @stopped

    @trace << :publisher_stop
    @running = false
    @stopped = true
  end
end

class DaisenkofunEventLoopFakeComponent
  def initialize(name, trace)
    @name = name
    @trace = trace
  end

  def start
    @trace << [@name, :start]
  end

  def stop
    @trace << [@name, :stop]
  end

  def tick(now)
    @trace << [@name, :tick, now]
  end
end

class DaisenkofunEventLoopTest < Picotest::Test
  def test_starts_components_before_publisher_and_stops_in_reverse_order
    trace = []
    publisher = DaisenkofunEventLoopFakePublisher.new(trace)
    first = DaisenkofunEventLoopFakeComponent.new(:first, trace)
    second = DaisenkofunEventLoopFakeComponent.new(:second, trace)
    event_loop = Daisenkofun::EventLoop.new(
      publisher: publisher,
      components: [first, second],
      clock: DaisenkofunEventLoopFakeClock.new(trace),
      logger: DaisenkofunEventLoopFakeLogger.new,
      mode: :generic
    )

    assert_equal :result, event_loop.run
    assert_equal [
      [:first, :start],
      [:second, :start],
      :publisher_start,
      [:publisher_tick, 10],
      :publisher_stop,
      [:second, :stop],
      [:first, :stop]
    ], trace
  end

  def test_tick_failure_still_stops_publisher_then_components
    trace = []
    publisher = DaisenkofunEventLoopFakePublisher.new(trace, RuntimeError.new("tick failed"))
    component = DaisenkofunEventLoopFakeComponent.new(:component, trace)
    event_loop = Daisenkofun::EventLoop.new(
      publisher: publisher,
      components: [component],
      clock: DaisenkofunEventLoopFakeClock.new(trace),
      logger: DaisenkofunEventLoopFakeLogger.new,
      mode: :generic
    )

    assert_raise(RuntimeError) { event_loop.run }
    assert_equal :publisher_stop, trace[-2]
    assert_equal [:component, :stop], trace[-1]
  end
end
