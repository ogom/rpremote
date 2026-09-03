# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterFakeClock
  attr_reader :sleeps

  def initialize(now = 0)
    @now = now
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

class DaisenkofunOximeterFakeLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunOximeterFakeStatusRenderer
  attr_reader :clear_count, :error_count, :updates

  def initialize
    @clear_count = 0
    @error_count = 0
    @updates = []
  end

  def clear
    @clear_count += 1
  end

  def error
    @error_count += 1
  end

  def render(mode, now, spo2:, bpm:, last_beat_at:)
    @updates << [mode, now, spo2, bpm, last_beat_at]
  end
end

class DaisenkofunOximeterFakeSensor
  attr_reader :shutdown_count

  def initialize(samples = [])
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

class DaisenkofunOximeterFailingSensor < DaisenkofunOximeterFakeSensor
  def available_samples
    1
  end

  def read
    raise RuntimeError, "sensor read failed"
  end
end

class DaisenkofunOximeterFakeSensorFactory
  attr_reader :call_count

  def initialize(sensor: nil, error: nil)
    @sensor = sensor
    @error = error
    @call_count = 0
  end

  def call
    @call_count += 1
    raise @error if @error

    @sensor
  end
end

class DaisenkofunOximeterFakeProcessor
  attr_reader :processed

  def initialize(bpm: 72.0, spo2: 98.0)
    @processed = []
    @latest_bpm = bpm
    @latest_spo2 = spo2
  end

  def process_sample(red:, ir:, timestamp_ms:)
    @processed << [red, ir, timestamp_ms]
  end

  attr_reader :latest_bpm, :latest_spo2
end

class DaisenkofunOximeterRunnerTest < Picotest::Test
  def test_start_tick_and_stop_with_injected_collaborators
    sensor = DaisenkofunOximeterFakeSensor.new([
      { red: 11, ir: 21 },
      { red: 12, ir: 22 }
    ])
    factory = DaisenkofunOximeterFakeSensorFactory.new(sensor: DaisenkofunOximeterFakeSensor.new)
    clock = DaisenkofunOximeterFakeClock.new(100)
    logger = DaisenkofunOximeterFakeLogger.new
    renderer = DaisenkofunOximeterFakeStatusRenderer.new
    processor = DaisenkofunOximeterFakeProcessor.new
    runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: renderer,
      sensor: sensor,
      sensor_factory: factory,
      clock: clock,
      logger: logger,
      processor: processor,
      duration_ms: 1_000
    )

    assert_equal runner, runner.start
    assert runner.running?
    assert_equal 0, factory.call_count
    runner.tick(125)
    assert_equal [[11, 21, 125], [12, 22, 125]], processor.processed
    assert_equal [:no_finger, 125, 0.0, 0.0, 0], renderer.updates[-1]

    assert_equal runner, runner.stop
    assert_false runner.running?
    assert_equal 1, sensor.shutdown_count
    assert_equal 2, renderer.clear_count
    assert_equal({ bpm: 72.0, spo2: 98.0 }, runner.result)
    assert logger.messages.include?(
      "DAISENKOFUN component=oximeter event=measurement_done bpm=72.0 spo2=98.0"
    )
  end

  def test_run_uses_factory_clock_and_duration
    sensor = DaisenkofunOximeterFakeSensor.new
    factory = DaisenkofunOximeterFakeSensorFactory.new(sensor: sensor)
    clock = DaisenkofunOximeterFakeClock.new
    runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: DaisenkofunOximeterFakeStatusRenderer.new,
      sensor_factory: factory,
      clock: clock,
      logger: DaisenkofunOximeterFakeLogger.new,
      processor: DaisenkofunOximeterFakeProcessor.new,
      duration_ms: 4,
      poll_interval_ms: 2
    )

    assert_equal({ bpm: 72.0, spo2: 98.0 }, runner.run)
    assert_equal 1, factory.call_count
    assert_equal [2, 2], clock.sleeps
    assert_equal 1, sensor.shutdown_count
  end

  def test_tick_limits_samples_so_other_components_can_run
    sensor = DaisenkofunOximeterFakeSensor.new([
      { red: 11, ir: 21 },
      { red: 12, ir: 22 },
      { red: 13, ir: 23 },
      { red: 14, ir: 24 },
      { red: 15, ir: 25 }
    ])
    processor = DaisenkofunOximeterFakeProcessor.new
    runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: DaisenkofunOximeterFakeStatusRenderer.new,
      sensor: sensor,
      clock: DaisenkofunOximeterFakeClock.new,
      logger: DaisenkofunOximeterFakeLogger.new,
      processor: processor,
      max_samples_per_tick: 2
    )

    runner.start
    runner.tick(10)
    assert_equal 2, runner.last_tick_samples
    assert_equal 5, runner.max_sample_backlog
    assert_equal [[11, 21, 10], [12, 22, 10]], processor.processed

    runner.tick(12)
    assert_equal 2, runner.last_tick_samples
    assert_equal 4, processor.processed.length
  ensure
    runner.stop if runner
  end

  def test_start_reports_sensor_initialization_failure
    error = RuntimeError.new("sensor unavailable")
    factory = DaisenkofunOximeterFakeSensorFactory.new(error: error)
    clock = DaisenkofunOximeterFakeClock.new
    logger = DaisenkofunOximeterFakeLogger.new
    renderer = DaisenkofunOximeterFakeStatusRenderer.new
    runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: renderer,
      sensor_factory: factory,
      clock: clock,
      logger: logger
    )

    assert_raise(RuntimeError) { runner.start }
    assert_false runner.running?
    assert_equal 1, renderer.error_count
    assert_equal 2, renderer.clear_count
    assert_equal [Daisenkofun::Oximeter::Config::ERROR_DISPLAY_MS], clock.sleeps
    assert logger.messages.include?(
      "DAISENKOFUN component=oximeter event=error " \
      "error=RuntimeError message=sensor unavailable"
    )
  end

  def test_tick_requires_a_running_runner
    runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: DaisenkofunOximeterFakeStatusRenderer.new,
      sensor: DaisenkofunOximeterFakeSensor.new,
      clock: DaisenkofunOximeterFakeClock.new,
      logger: DaisenkofunOximeterFakeLogger.new,
      processor: DaisenkofunOximeterFakeProcessor.new
    )

    assert_raise(RuntimeError) { runner.tick(0) }
  end

  def test_run_shuts_down_sensor_and_clears_leds_after_tick_error
    sensor = DaisenkofunOximeterFailingSensor.new
    renderer = DaisenkofunOximeterFakeStatusRenderer.new
    runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: renderer,
      sensor: sensor,
      clock: DaisenkofunOximeterFakeClock.new,
      logger: DaisenkofunOximeterFakeLogger.new,
      processor: DaisenkofunOximeterFakeProcessor.new,
      duration_ms: 1_000
    )

    assert_raise(RuntimeError) { runner.run }
    assert_equal 1, sensor.shutdown_count
    assert_equal 2, renderer.clear_count
    assert_false runner.running?
  end
end
