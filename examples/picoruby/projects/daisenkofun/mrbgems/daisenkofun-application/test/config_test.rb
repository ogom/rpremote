# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunApplicationConfigTest < Picotest::Test
  def test_accepts_defaults_and_float_volume_on_picoruby
    validator = Daisenkofun::Application::Validator.new
    config = Daisenkofun::Application::Config.new(mode: :combined)

    assert_equal config, validator.validate(config)
    assert_equal 16, config.i2c_sda_pin
    assert_equal 17, config.i2c_scl_pin
    assert_equal 1.5, validator.validate(
      Daisenkofun::Application::Config.new(mode: :combined, buzzer_volume: 1.5)
    ).buzzer_volume
  end
end
