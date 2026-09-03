# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunMainTestLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunMainTestClock
  def millis
    100
  end

  def wait_ms(_milliseconds)
  end
end

class DaisenkofunMainTestDispatcher
  attr_reader :subscribers

  def initialize
    @subscribers = []
  end

  def subscribe(subscriber)
    @subscribers << subscriber
    self
  end

  def publish(event, payload)
    @subscribers.each { |subscriber| subscriber.call(event, payload) }
  end
end

class DaisenkofunMainTestComponent
  attr_reader :events, :start_count, :stop_count, :ticks

  def initialize
    @events = []
    @ticks = []
    @start_count = 0
    @stop_count = 0
    @stopped = true
  end

  def start
    @start_count += 1
    @stopped = false
  end

  def call(event, payload)
    @events << [event, payload]
  end

  def tick(now)
    @ticks << now
  end

  def stop
    return if @stopped

    @stop_count += 1
    @stopped = true
  end
end

class DaisenkofunMainTestIllumination
  attr_reader :pattern_key, :setlist_name, :stop_count
  attr_accessor :error

  def initialize
    @stop_count = 0
    @stopped = false
  end

  def play_setlist(setlist_name)
    @setlist_name = setlist_name
    raise @error if @error

    :illumination_result
  end

  def play_pattern(pattern_key)
    @pattern_key = pattern_key
    raise @error if @error

    :pattern_result
  end

  def stop
    return if @stopped

    @stop_count += 1
    @stopped = true
  end
end

class DaisenkofunMainTestRunner
  attr_reader :start_count, :stop_count
  attr_accessor :dispatcher

  def initialize
    @start_count = 0
    @stop_count = 0
    @stopped = true
  end

  def start
    @start_count += 1
    @stopped = false
  end

  def stop
    return if @stopped

    @stop_count += 1
    @stopped = true
  end

  def result
    { bpm: 72.0, spo2: 98.0 }
  end
end

class DaisenkofunMainTestEventLoop
  def initialize(context, publisher:, components:, clock:, mode:, **)
    @context = context
    @publisher = publisher
    @components = components
    @clock = clock
    @mode = mode
  end

  def run
    @context.event_loop_mode = @mode
    @context.event_loop_components = @components
    @components.each(&:start)
    @publisher.start
    @publisher.dispatcher.publish(:beat, { timestamp_ms: @clock.millis, bpm: 72.0 })
    @components.each { |component| component.tick(@clock.millis) }
    @publisher.stop
    @components.reverse_each(&:stop)
    @publisher.result
  end
end

class DaisenkofunMainTestContext
  attr_accessor :event_loop_components, :event_loop_mode
  attr_reader :beat_illumination, :clock, :illumination, :logger, :musical, :runner
  attr_reader :runner_options, :setlist_resolutions

  def initialize
    @logger = DaisenkofunMainTestLogger.new
    @clock = DaisenkofunMainTestClock.new
    @illumination = DaisenkofunMainTestIllumination.new
    @runner = DaisenkofunMainTestRunner.new
    @beat_illumination = DaisenkofunMainTestComponent.new
    @musical = DaisenkofunMainTestComponent.new
    @setlist_resolutions = []
  end

  def build_runner(options)
    @runner_options = options
    @runner.dispatcher = options[:dispatcher]
    @runner
  end
end

module Daisenkofun
  module Setlist
    def self.resolve(name)
      $daisenkofun_main_test_context.setlist_resolutions << name
      return [[:structure_guide, 1, 1]] if [:tests, :highlights, :story, :showcase].include?(name)

      raise ArgumentError, "unknown setlist"
    end

    def self.valid_key?(key)
      key == :structure_guide
    end
  end

  class ConsoleLogger
    def self.new
      $daisenkofun_main_test_context.logger
    end
  end

  class EventLoop
    def self.new(**options)
      DaisenkofunMainTestEventLoop.new($daisenkofun_main_test_context, **options)
    end
  end

  class Illumination
    def self.new(**)
      $daisenkofun_main_test_context.illumination
    end
  end

  class BeatIllumination
    def self.new(**)
      $daisenkofun_main_test_context.beat_illumination
    end
  end

  module Musical
    class NullOutput
    end

    class BeatSubscriber
      def self.new(**)
        $daisenkofun_main_test_context.musical
      end
    end
  end

  module Oximeter
    module Config
      RUN_DURATION_MS = 60_000
    end

    class BoardClock
      def self.new
        $daisenkofun_main_test_context.clock
      end
    end

    class Dispatcher
      def self.new
        DaisenkofunMainTestDispatcher.new
      end
    end

    class Runner
      def self.new(**options)
        $daisenkofun_main_test_context.build_runner(options)
      end
    end

    module StatusLed
      class Factory
        def call
          :status_renderer
        end
      end
    end
  end
end

class DaisenkofunMainTest < Picotest::Test
  MAIN_PATH = File.expand_path("../main.rb", __dir__)

  def setup
    $daisenkofun_main_test_context = DaisenkofunMainTestContext.new
  end

  def teardown
    $daisenkofun_main_test_context = nil
  end

  def test_runs_tests_setlist_and_preserves_logs
    result = run_main(mode: :illumination, setlist_name: :tests)
    context = $daisenkofun_main_test_context

    assert_equal :illumination_result, result
    assert_equal :tests, context.illumination.setlist_name
    assert_equal [:tests], context.setlist_resolutions
    assert_equal 1, context.illumination.stop_count
    assert_equal "DAISENKOFUN mode=illumination event=start", context.logger.messages[0]
    assert_equal "DAISENKOFUN mode=illumination event=done status=ok", context.logger.messages[-1]
  end

  def test_runs_one_pattern
    result = run_main(mode: :illumination, pattern_key: :structure_guide)

    assert_equal :pattern_result, result
    assert_equal :structure_guide, $daisenkofun_main_test_context.illumination.pattern_key
  end

  def test_runs_oximeter_without_combined_components
    result = run_main(mode: :oximeter)
    context = $daisenkofun_main_test_context

    assert_equal({ bpm: 72.0, spo2: 98.0 }, result)
    assert_equal :oximeter, context.event_loop_mode
    assert_equal [], context.event_loop_components
    assert_equal 60_000, context.runner_options[:duration_ms]
    assert_equal 1, context.runner.stop_count
  end

  def test_runs_combined_mode_with_one_dispatcher
    result = run_main(mode: :combined, duration_ms: 1_000)
    context = $daisenkofun_main_test_context

    assert_equal({ bpm: 72.0, spo2: 98.0 }, result)
    assert_equal :combined, context.event_loop_mode
    assert_equal [context.beat_illumination, context.musical], context.event_loop_components
    assert_equal 2, context.runner_options[:dispatcher].subscribers.length
    assert_equal :beat, context.beat_illumination.events[0][0]
    assert_equal :beat, context.musical.events[0][0]
    assert_equal 1, context.runner.stop_count
    assert_equal 1, context.musical.stop_count
    assert_equal 1, context.beat_illumination.stop_count
  end

  def test_rejects_invalid_settings_before_hardware_initialization
    assert_raise(ArgumentError) { run_main(mode: :unknown) }
    assert_raise(ArgumentError) do
      run_main(mode: :illumination, setlist_name: :tests, pattern_key: :structure_guide)
    end
    assert_raise(ArgumentError) { run_main(mode: :illumination, duration_ms: 1_000) }
    assert_raise(ArgumentError) { run_main(mode: :oximeter, setlist_name: :tests) }
    assert_raise(ArgumentError) { run_main(mode: :combined, pattern_key: :structure_guide) }
    assert_raise(ArgumentError) { run_main(mode: :oximeter, duration_ms: 0) }
    assert_equal [], $daisenkofun_main_test_context.logger.messages
  end

  def test_failure_still_stops_mode_and_reports_error
    context = $daisenkofun_main_test_context
    context.illumination.error = RuntimeError.new("pattern failed")

    assert_raise(RuntimeError) { run_main(mode: :illumination) }
    assert_equal 1, context.illumination.stop_count
    assert_equal(
      "DAISENKOFUN mode=illumination event=done status=error " \
      "error=RuntimeError message=pattern failed",
      context.logger.messages[-1]
    )
  end

  private

  def run_main(mode:, setlist_name: nil, pattern_key: nil, duration_ms: nil)
    source = File.read(MAIN_PATH)
    source = source.lines.reject { |line| line.start_with?("require \"") }.join
    source.sub!(/^mode = .*$/, "mode = #{mode.inspect}")
    source.sub!(/^setlist_name = .*$/, "setlist_name = #{setlist_name.inspect}")
    source.sub!(/^pattern_key = .*$/, "pattern_key = #{pattern_key.inspect}")
    source.sub!(/^duration_ms = .*$/, "duration_ms = #{duration_ms.inspect}")
    eval(source, TOPLEVEL_BINDING, MAIN_PATH)
  end
end
