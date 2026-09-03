# frozen_string_literal: true

require_relative "test_helper"

class OximeterMainTestClock
  attr_reader :sleeps

  def initialize
    @now = 0
    @sleeps = []
  end

  def millis
    @now
  end

  def wait_ms(milliseconds)
    @sleeps << milliseconds
    @now += milliseconds
  end
end

class OximeterMainTestLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class OximeterMainTestDispatcher
  attr_reader :subscribers

  def initialize
    @subscribers = []
  end

  def subscribe(subscriber)
    @subscribers << subscriber
    self
  end
end

class OximeterMainTestSensor
  attr_reader :shutdown_count

  def initialize(samples)
    @samples = samples
    @shutdown_count = 0
  end

  def available_samples
    @samples.length
  end

  def read
    @samples.shift
  end

  def shutdown
    @shutdown_count += 1
  end
end

class OximeterMainTestRenderer
  attr_reader :clear_count, :frames

  def initialize
    @clear_count = 0
    @frames = []
  end

  def clear
    @clear_count += 1
  end

  def render(timestamp_ms)
    @frames << timestamp_ms
  end
end

class OximeterMainTestProcessor
  attr_reader :samples

  def initialize
    @samples = []
  end

  def process_sample(red:, ir:, timestamp_ms:)
    @samples << [red, ir, timestamp_ms]
  end

  def latest_bpm
    72.0
  end

  def latest_spo2
    98.0
  end
end

class OximeterMainTest < Picotest::Test
  def test_composes_components_runs_the_loop_and_cleans_up
    clock = OximeterMainTestClock.new
    logger = OximeterMainTestLogger.new
    dispatcher = OximeterMainTestDispatcher.new
    sensor = OximeterMainTestSensor.new([{ red: 10, ir: 20 }, { red: 11, ir: 21 }])
    renderer = OximeterMainTestRenderer.new
    processor = OximeterMainTestProcessor.new
    originals = []

    replace_constant(Oximeter, :BoardClock, singleton_factory(clock), originals)
    replace_constant(Oximeter, :ConsoleLogger, singleton_factory(logger), originals)
    replace_constant(Oximeter, :Dispatcher, singleton_factory(dispatcher), originals)
    replace_constant(Oximeter, :SensorFactory, singleton_factory(callable_factory(sensor)), originals)
    replace_constant(Oximeter, :Config, test_config, originals)
    replace_constant(Oximeter, :StatusLed, test_status_led(renderer), originals)
    replace_constant(Oximeter::Measurement, :Processor, processor_factory(processor), originals)

    load File.expand_path("../main.rb", __dir__)

    assert_equal [[10, 20, 0], [11, 21, 0]], processor.samples
    assert_equal [0, 2], renderer.frames
    assert_equal 2, renderer.clear_count
    assert_equal 1, sensor.shutdown_count
    assert_equal 1, dispatcher.subscribers.length
    assert logger.messages.include?("OXIMETER_START,address=0x57,duration_ms=4")
    assert logger.messages.include?("OXIMETER_DONE,bpm=72.0,spo2=98.0")
    assert_equal [2, 2], clock.sleeps
  ensure
    restore_constants(originals)
  end

  private

  def singleton_factory(instance)
    factory = Class.new
    factory.define_singleton_method(:new) { instance }
    factory
  end

  def callable_factory(value)
    factory = Object.new
    factory.define_singleton_method(:call) { value }
    factory
  end

  def processor_factory(processor)
    factory = Class.new
    factory.define_singleton_method(:new) { |**| processor }
    factory
  end

  def test_config
    Module.new.tap do |config|
      config.const_set(:RUN_DURATION_MS, 4)
      config.const_set(:POLL_INTERVAL_MS, 2)
      config.const_set(:ERROR_DISPLAY_MS, 1_000)
    end
  end

  def test_status_led(renderer)
    Module.new.tap do |status_led|
      factory = Class.new do
        define_method(:call) { renderer }
      end
      presenter = Class.new do
        define_method(:initialize) { |value| @renderer = value }
        define_method(:tick) { |timestamp_ms| @renderer.render(timestamp_ms); self }
      end
      status_led.const_set(:Factory, factory)
      status_led.const_set(:Presenter, presenter)
    end
  end

  def replace_constant(parent, name, value, originals)
    originals << [parent, name, parent.const_get(name, false)]
    parent.send(:remove_const, name)
    parent.const_set(name, value)
  end

  def restore_constants(originals)
    originals.reverse_each do |parent, name, value|
      parent.send(:remove_const, name)
      parent.const_set(name, value)
    end
  end
end
