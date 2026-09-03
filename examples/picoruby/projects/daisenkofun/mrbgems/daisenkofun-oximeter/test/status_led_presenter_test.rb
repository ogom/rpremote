# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterPresenterRenderer
  attr_reader :updates

  def initialize
    @updates = []
  end

  def render(mode, now, spo2:, bpm:, last_beat_at:)
    @updates << [mode, now, spo2, bpm, last_beat_at]
  end
end

class DaisenkofunOximeterStatusLedPresenterTest < Picotest::Test
  def test_translates_measurement_events_into_led_display_state
    renderer = DaisenkofunOximeterPresenterRenderer.new
    presenter = Daisenkofun::Oximeter::StatusLed::Presenter.new(renderer)
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new.subscribe(presenter)

    presenter.tick(100)
    assert_equal [:no_finger, 100, 0.0, 0.0, 0], renderer.updates[-1]

    dispatcher.publish(Daisenkofun::Oximeter::Measurement::Events::FINGER_DETECTED, {
      timestamp_ms: 110,
      ir: 30_000
    })
    dispatcher.publish(Daisenkofun::Oximeter::Measurement::Events::BEAT, {
      timestamp_ms: 700,
      red: 28_000,
      ir: 29_000,
      interval_ms: 590,
      bpm: 72.0
    })
    dispatcher.publish(Daisenkofun::Oximeter::Measurement::Events::MEASUREMENT_COMPLETED, {
      timestamp_ms: 700,
      red: 28_000,
      ir: 29_000,
      bpm: 72.0,
      spo2: 98.0
    })
    presenter.tick(710)
    assert_equal [:result, 710, 98.0, 72.0, 700], renderer.updates[-1]

    dispatcher.publish(Daisenkofun::Oximeter::Measurement::Events::FINGER_REMOVED, {
      timestamp_ms: 800,
      ir: 10_000
    })
    presenter.tick(810)
    assert_equal [:no_finger, 810, 0.0, 0.0, 0], renderer.updates[-1]
  end
end
