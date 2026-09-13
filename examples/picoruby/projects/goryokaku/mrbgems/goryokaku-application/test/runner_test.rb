# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuApplicationRunnerTest < Picotest::Test
  def test_runs_illumination_and_reports_lifecycle
    player = FakeGoryokakuPlayer.new
    logger = FakeGoryokakuLogger.new
    dfu = FakeGoryokakuDfu.new
    runner = Goryokaku::Application::Runner.new(
      config: Goryokaku::Application::Config.new(setlist_name: :tests),
      logger: logger, clock: FakeGoryokakuClock.new, dfu: dfu,
      composition: FakeGoryokakuComposition.new(player: player)
    )
    runner.call
    assert_equal [[:setlist, :tests, false], [:stop]], player.events
    assert dfu.confirmed
    assert_equal "GORYOKAKU mode=illumination event=start", logger.lines[0]
    assert_equal "GORYOKAKU mode=illumination event=done status=ok", logger.lines[-1]
  end

  def test_runs_combined_event_loop_for_requested_iterations
    event_loop = FakeGoryokakuEventLoop.new
    runner = Goryokaku::Application::Runner.new(
      config: Goryokaku::Application::Config.new(mode: :combined),
      logger: FakeGoryokakuLogger.new, clock: FakeGoryokakuClock.new, dfu: FakeGoryokakuDfu.new,
      composition: FakeGoryokakuComposition.new(event_loop: event_loop)
    )
    runner.call(iterations: 3)
    assert_equal 3, event_loop.iterations
  end

  def test_logs_error_and_re_raises_after_cleanup
    player = FakeGoryokakuPlayer.new
    def player.play_setlist(*); raise "drawing failed"; end
    logger = FakeGoryokakuLogger.new
    runner = Goryokaku::Application::Runner.new(
      config: Goryokaku::Application::Config.new,
      logger: logger, clock: FakeGoryokakuClock.new, dfu: FakeGoryokakuDfu.new,
      composition: FakeGoryokakuComposition.new(player: player)
    )
    assert_raise(RuntimeError) { runner.call }
    assert_equal [:stop], player.events[-1]
    assert_equal "GORYOKAKU mode=illumination event=done status=error", logger.lines[-1]
  end
end
