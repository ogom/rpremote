# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterProcessorLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunOximeterEventCollector
  attr_reader :events

  def initialize
    @events = []
  end

  def call(event, payload)
    @events << [event, payload]
  end
end

class DaisenkofunOximeterTransitioningFingerDetector
  def initialize
    @present = false
  end

  def update(_ir)
    @present = !@present
    @present ? :detected : :removed
  end

  def present?
    @present
  end
end

class DaisenkofunOximeterClearableBeatDetector
  attr_reader :clear_count

  def initialize
    @clear_count = 0
  end

  def clear
    @clear_count += 1
    self
  end

  def start(_timestamp_ms)
    self
  end

  def process_sample(ir:, timestamp_ms:)
    nil
  end
end


class DaisenkofunOximeterClearableEstimator
  attr_reader :clear_count

  def initialize
    @clear_count = 0
  end

  def clear
    @clear_count += 1
    self
  end

  def push(_red, _ir)
    self
  end
end


class DaisenkofunOximeterClearableSession
  attr_reader :clear_count

  def initialize
    @clear_count = 0
  end

  def clear
    @clear_count += 1
    self
  end
end

class DaisenkofunOximeterMeasurementProcessorTest < Picotest::Test
  def test_processes_finger_events_without_a_logger_or_led_component
    collector = DaisenkofunOximeterEventCollector.new
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new.subscribe(collector)
    processor = Daisenkofun::Oximeter::Measurement::Processor.new(dispatcher: dispatcher)

    processor.process_sample(red: 30_000, ir: 30_000, timestamp_ms: 100)
    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 200)

    assert_equal Daisenkofun::Oximeter::Measurement::Events::FINGER_DETECTED, collector.events[0][0]
    assert_equal Daisenkofun::Oximeter::Measurement::Events::FINGER_REMOVED, collector.events[1][0]
    assert_in_delta 0.0, processor.latest_bpm
    assert_in_delta 0.0, processor.latest_spo2
  end

  def test_emits_finger_events_without_an_led_display
    logger = DaisenkofunOximeterProcessorLogger.new
    collector = DaisenkofunOximeterEventCollector.new
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new.subscribe(collector)
    processor = Daisenkofun::Oximeter::Measurement::Processor.new(
      dispatcher: dispatcher,
      logger: logger
    )

    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 1_000)
    assert logger.messages.include?(
      "DAISENKOFUN component=oximeter event=wait timestamp_ms=1000 red=10000 ir=10000"
    )
    assert_equal [], collector.events

    processor.process_sample(red: 30_000, ir: 30_000, timestamp_ms: 1_100)
    assert logger.messages.include?(
      "DAISENKOFUN component=oximeter event=finger_detected timestamp_ms=1100 ir=30000"
    )
    assert_equal Daisenkofun::Oximeter::Measurement::Events::FINGER_DETECTED, collector.events[-1][0]

    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 1_200)
    assert logger.messages.include?(
      "DAISENKOFUN component=oximeter event=finger_removed timestamp_ms=1200 ir=10000"
    )
    assert_equal Daisenkofun::Oximeter::Measurement::Events::FINGER_REMOVED, collector.events[-1][0]
  end

  def test_emits_beat_and_measurement_events
    collector = DaisenkofunOximeterEventCollector.new
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new.subscribe(collector)
    processor = Daisenkofun::Oximeter::Measurement::Processor.new(
      dispatcher: dispatcher,
      logger: DaisenkofunOximeterProcessorLogger.new
    )

    index = 0
    while index < 100
      offset = index.even? ? -10 : 10
      processor.process_sample(
        red: 30_000 + offset * 10,
        ir: 30_000 + offset,
        timestamp_ms: index * 10
      )
      index += 1
    end

    beat_index = 0
    while beat_index < 8
      beat_at = 1_100 + beat_index * 600
      8.times do
        processor.process_sample(red: 32_000, ir: 31_000, timestamp_ms: beat_at - 10)
      end
      8.times do
        processor.process_sample(red: 28_000, ir: 29_000, timestamp_ms: beat_at)
      end
      beat_index += 1
    end

    names = collector.events.map { |event| event[0] }
    assert_equal 8, names.count { |name| name == Daisenkofun::Oximeter::Measurement::Events::BEAT }
    updated_count = names.count do |name|
      name == Daisenkofun::Oximeter::Measurement::Events::MEASUREMENT_UPDATED
    end
    completed_count = names.count do |name|
      name == Daisenkofun::Oximeter::Measurement::Events::MEASUREMENT_COMPLETED
    end
    assert_equal 6, updated_count
    assert_equal 1, completed_count
    assert_equal Daisenkofun::Oximeter::Measurement::Events::FINGER_DETECTED, names[0]
    assert_equal Daisenkofun::Oximeter::Measurement::Events::MEASUREMENT_COMPLETED, names[-1]
    completed_payload = collector.events[-1][1]
    assert completed_payload.key?(:timestamp_ms)
    assert completed_payload.key?(:red)
    assert completed_payload.key?(:ir)
    assert completed_payload.key?(:bpm)
    assert completed_payload.key?(:spo2)
    assert processor.latest_bpm > 0.0
    assert processor.latest_spo2 > 0.0
  end

  def test_clears_measurement_state_when_a_finger_is_removed
    beat_detector = DaisenkofunOximeterClearableBeatDetector.new
    spo2_estimator = DaisenkofunOximeterClearableEstimator.new
    session = DaisenkofunOximeterClearableSession.new
    processor = Daisenkofun::Oximeter::Measurement::Processor.new(
      logger: DaisenkofunOximeterProcessorLogger.new,
      finger_detector: DaisenkofunOximeterTransitioningFingerDetector.new,
      beat_detector: beat_detector,
      spo2_estimator: spo2_estimator,
      session: session
    )

    processor.process_sample(red: 30_000, ir: 30_000, timestamp_ms: 100)
    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 200)

    assert_equal 2, beat_detector.clear_count
    assert_equal 2, spo2_estimator.clear_count
    assert_equal 2, session.clear_count
    assert_in_delta 0.0, processor.latest_bpm
    assert_in_delta 0.0, processor.latest_spo2
  end

  def test_public_class_names_match_the_file_layout
    namespace = Daisenkofun::Oximeter

    assert namespace.const_defined?(:BoardClock, false)
    assert namespace.const_defined?(:ConsoleLogger, false)
    assert namespace.const_defined?(:Dispatcher, false)
    assert namespace.const_defined?(:SensorFactory, false)

    assert_false namespace.const_defined?(:Clock, false)
    assert_false namespace.const_defined?(:Events, false)
    assert_false namespace.const_defined?(:Logging, false)
    assert_false namespace.const_defined?(:Sensor, false)
    assert_false namespace.const_defined?(:Monitor, false)
    assert_false namespace.const_defined?(:EventBus, false)
    assert_false namespace.const_defined?(:StatusLedSubscriber, false)
    assert_false namespace.const_defined?(:StatusLeds, false)
    assert_false namespace.const_defined?(:RollingStatistics, false)
    assert_false namespace.const_defined?(:StatusDisplayFactory, false)
    assert_false namespace.const_defined?(:NullStatusDisplay, false)
  end
end
