# frozen_string_literal: true

require_relative "test_helper"

class OximeterMeasurementTestCollector
  attr_reader :events

  def initialize
    @events = []
  end

  def call(event, payload)
    @events << [event, payload]
  end
end

class OximeterMeasurementProcessorTest < Picotest::Test
  def test_processes_finger_events_without_an_led_component
    collector = OximeterMeasurementTestCollector.new
    dispatcher = Oximeter::Dispatcher.new.subscribe(collector)
    processor = Oximeter::Measurement::Processor.new(dispatcher: dispatcher)

    processor.process_sample(red: 30_000, ir: 30_000, timestamp_ms: 100)
    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 200)

    assert_equal Oximeter::Measurement::Events::FINGER_DETECTED, collector.events[0][0]
    assert_equal Oximeter::Measurement::Events::FINGER_REMOVED, collector.events[1][0]
    assert_in_delta 0.0, processor.latest_bpm
    assert_in_delta 0.0, processor.latest_spo2
  end

  def test_public_class_names_match_the_file_layout
    assert Oximeter.const_defined?(:BoardClock, false)
    assert Oximeter.const_defined?(:ConsoleLogger, false)
    assert Oximeter.const_defined?(:Dispatcher, false)
    assert Oximeter.const_defined?(:SensorFactory, false)

    assert_false Oximeter.const_defined?(:Clock, false)
    assert_false Oximeter.const_defined?(:Events, false)
    assert_false Oximeter.const_defined?(:Logging, false)
    assert_false Oximeter.const_defined?(:Sensor, false)
    assert_false Oximeter.const_defined?(:Monitor, false)
    assert_false Oximeter.const_defined?(:EventBus, false)
    assert_false Oximeter.const_defined?(:StatusLedSubscriber, false)
    assert_false Oximeter.const_defined?(:StatusLeds, false)
    assert_false Oximeter.const_defined?(:RollingStatistics, false)
  end
end
