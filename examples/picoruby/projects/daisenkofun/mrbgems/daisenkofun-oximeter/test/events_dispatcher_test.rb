# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterDispatcherSubscriber
  def initialize(name, calls, error = nil)
    @name = name
    @calls = calls
    @error = error
  end

  def call(event, payload)
    @calls << [@name, event, payload]
    raise @error if @error
  end
end

class DaisenkofunOximeterEventDispatcherTest < Picotest::Test
  def test_delivers_synchronously_in_registration_order
    calls = []
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new
    dispatcher.subscribe(DaisenkofunOximeterDispatcherSubscriber.new(:first, calls))
    dispatcher.subscribe(DaisenkofunOximeterDispatcherSubscriber.new(:second, calls))
    payload = { bpm: 72.0 }

    assert_equal dispatcher, dispatcher.publish(:beat, payload)
    assert_equal [[:first, :beat, payload], [:second, :beat, payload]], calls
    assert_equal payload.object_id, calls[0][2].object_id
    assert_equal payload.object_id, calls[1][2].object_id
  end

  def test_propagates_an_error_and_stops_delivery
    calls = []
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new
    dispatcher.subscribe(
      DaisenkofunOximeterDispatcherSubscriber.new(
        :first,
        calls,
        RuntimeError.new("subscriber failed")
      )
    )
    dispatcher.subscribe(DaisenkofunOximeterDispatcherSubscriber.new(:second, calls))

    assert_raise(RuntimeError) { dispatcher.publish(:beat, {}) }
    assert_equal 1, calls.length
  end
end
