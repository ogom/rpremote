# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuApplicationConfigTest < Picotest::Test
  def test_preserves_defaults_without_validating_during_construction
    config = Goryokaku::Application::Config.new
    assert_equal :illumination, config.mode
    assert_equal :highlights, config.setlist_name
    assert_equal 380, config.led_count
    assert_equal 14, config.led_pin
    assert_equal 21, config.touch_pin
    assert_equal 18, config.buzzer_pin
    assert_equal 16, config.i2c_sda_pin
    assert_equal 17, config.i2c_scl_pin
    assert_equal 5_000, config.heartbeat_interval_ms
    assert Goryokaku::Application::Validator.new(config).validate
  end

  def test_converts_legacy_heartbeat_ticks_to_milliseconds
    config = Goryokaku::Application::Config.new(heartbeat_interval: 250, poll_interval_ms: 20)
    assert_equal 5_000, config.heartbeat_interval_ms
  end

  def test_combined_mode_accepts_a_setlist
    config = Goryokaku::Application::Config.new(mode: :combined, setlist_name: :tests)
    assert Goryokaku::Application::Validator.new(config).validate
  end

  def test_combined_mode_defaults_to_highlights
    config = Goryokaku::Application::Config.new(mode: :combined)
    assert_equal :highlights, config.setlist_name
  end

  def test_combined_mode_rejects_pattern_and_repeat
    pattern = Goryokaku::Application::Config.new(mode: :combined, setlist_name: nil, pattern_key: :warm_white)
    repeating = Goryokaku::Application::Config.new(mode: :combined, repeat: true)
    assert_raise(ArgumentError) { Goryokaku::Application::Validator.new(pattern).validate }
    assert_raise(ArgumentError) { Goryokaku::Application::Validator.new(repeating).validate }
  end

  def test_musical_mode_has_no_setlist_and_is_valid
    config = Goryokaku::Application::Config.new(mode: :musical)
    assert_equal nil, config.setlist_name
    assert config.musical?
    assert Goryokaku::Application::Validator.new(config).validate
  end

  def test_validator_rejects_a_strip_that_cannot_cover_the_layout
    config = Goryokaku::Application::Config.new(led_count: 379)
    assert_raise(ArgumentError) { Goryokaku::Application::Validator.new(config).validate }
  end

  def test_validates_tambourine_thresholds_and_axis_signs
    invalid_signs = Goryokaku::Application::Config.new(musical_axis_signs: [1, 0, 1])
    invalid_thresholds = Goryokaku::Application::Config.new(strike_threshold: 0.4, strike_release_threshold: 0.5)

    assert_raise(ArgumentError) { Goryokaku::Application::Validator.new(invalid_signs).validate }
    assert_raise(ArgumentError) { Goryokaku::Application::Validator.new(invalid_thresholds).validate }
  end

  def test_accepts_integer_and_float_tambourine_thresholds
    config = Goryokaku::Application::Config.new(
      shake_threshold: 1,
      strike_threshold: 2.0,
      strike_release_threshold: 1
    )

    assert Goryokaku::Application::Validator.new(config).validate
  end
end
