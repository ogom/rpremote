# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterRendererPixels
  attr_reader :colors, :show_count, :clear_count

  def initialize(count)
    @colors = Array.new(count) { [0, 0, 0] }
    @show_count = 0
    @clear_count = 0
  end

  def fill(red, green, blue)
    index = 0
    while index < @colors.length
      @colors[index] = [red, green, blue]
      index += 1
    end
    self
  end

  def set_rgb(index, red, green, blue)
    @colors[index] = [red, green, blue]
    self
  end

  def show
    @show_count += 1
    self
  end

  def clear
    fill(0, 0, 0)
    @clear_count += 1
    self
  end
end

class DaisenkofunOximeterStatusLedRendererTest < Picotest::Test
  def setup
    @pixels = DaisenkofunOximeterRendererPixels.new(
      Daisenkofun::Oximeter::Config::LED_COUNT
    )
    @renderer = Daisenkofun::Oximeter::StatusLed::Renderer.new(@pixels)
  end

  def test_throttles_frames_and_renders_waiting_and_measuring_states
    @renderer.render(:no_finger, 119, spo2: 0.0, bpm: 0.0, last_beat_at: 0)
    assert_equal 0, @pixels.show_count

    @renderer.render(:no_finger, 120, spo2: 0.0, bpm: 0.0, last_beat_at: 0)
    assert_equal 1, @pixels.show_count
    assert_equal [6, 6, 6], @pixels.colors[0]

    @renderer.render(:measuring, 210, spo2: 0.0, bpm: 0.0, last_beat_at: 0)
    assert_equal 2, @pixels.show_count
    assert_equal [0, 3, 12], @pixels.colors[1]
  end

  def test_renders_result_color_from_spo2
    @renderer.render(:result, 120, spo2: 98.0, bpm: 60.0, last_beat_at: 120)
    assert_equal [0, 12, 3], @pixels.colors[0]

    @renderer.render(:result, 160, spo2: 96.0, bpm: 60.0, last_beat_at: 160)
    assert_equal [12, 0, 0], @pixels.colors[0]
  end

  def test_error_and_clear_delegate_to_pixels
    @renderer.error
    assert_equal [12, 0, 0], @pixels.colors[0]
    assert_equal 1, @pixels.show_count

    @renderer.clear
    assert_equal [0, 0, 0], @pixels.colors[0]
    assert_equal 1, @pixels.clear_count
  end
end
