# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunApplicationConfigTest < Picotest::Test
  def test_resolves_mode_defaults
    illumination = Daisenkofun::Application::Config.new(mode: :illumination)
    measurement = Daisenkofun::Application::Config.new(mode: :combined)

    assert_equal :highlights, illumination.setlist_name
    assert_nil illumination.duration_ms
    assert_equal 60_000, measurement.duration_ms
    assert_equal 16, measurement.i2c_sda_pin
    assert_equal 17, measurement.i2c_scl_pin
    assert_equal 3, measurement.buzzer_volume
  end

  def test_validates_the_public_configuration
    validator = Daisenkofun::Application::Validator.new
    config = Daisenkofun::Application::Config.new(mode: :combined)

    assert_equal config, validator.validate(config)
    assert_raise(ArgumentError) do
      validator.validate(Daisenkofun::Application::Config.new(mode: :invalid))
    end
    assert_equal 1.5, validator.validate(
      Daisenkofun::Application::Config.new(mode: :combined, buzzer_volume: 1.5)
    ).buzzer_volume
    assert_raise(ArgumentError) do
      validator.validate(Daisenkofun::Application::Config.new(mode: :combined, buzzer_volume: -1))
    end
    assert_raise(ArgumentError) do
      validator.validate(Daisenkofun::Application::Config.new(mode: :combined, buzzer_volume: 101))
    end
  end
end
