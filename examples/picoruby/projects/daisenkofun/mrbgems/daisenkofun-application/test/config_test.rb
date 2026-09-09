# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunApplicationConfigTest < Picotest::Test
  def test_resolves_mode_defaults
    illumination = Daisenkofun::Application::Config.new(mode: :illumination)
    measurement = Daisenkofun::Application::Config.new(mode: :combined)

    assert_equal :highlights, illumination.setlist_name
    assert_nil illumination.duration_ms
    assert_equal 60_000, measurement.duration_ms
  end

  def test_validates_the_public_configuration
    validator = Daisenkofun::Application::Validator.new
    config = Daisenkofun::Application::Config.new(mode: :combined)

    assert_equal config, validator.validate(config)
    assert_raise(ArgumentError) do
      validator.validate(Daisenkofun::Application::Config.new(mode: :invalid))
    end
  end
end
