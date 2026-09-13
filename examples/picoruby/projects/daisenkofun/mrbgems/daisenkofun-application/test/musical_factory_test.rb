# frozen_string_literal: true

require_relative "test_helper"

module Daisenkofun
  module Musical
    module Outputs
      class Null
      end

      class PWM
        attr_reader :options
        def initialize(**options); @options = options; end
      end

      class KofunCanon
        attr_reader :options
        def initialize(**options); @options = options; end
      end
    end

    module Planners
      class KofunCanon
      end

      class HeartbeatSignature
        def initialize(canon_planner:); @canon_planner = canon_planner; end
      end
    end
  end

  module Illumination
    module Biometrics
      class MoatCanon
        def initialize(cue_source:); @cue_source = cue_source; end
      end
    end
  end
end

application_dir = File.expand_path("../mrblib/daisenkofun-application", __dir__)
require File.join(application_dir, "musical_factory")

class DaisenkofunApplicationMusicalFactoryTest < Picotest::Test
  def setup
    @factory = Daisenkofun::Application::MusicalFactory.new(
      clock: nil, logger: nil
    )
  end

  def test_passes_volume_to_pulse_output
    config = Daisenkofun::Application::Config.new(
      mode: :combined, musical_style: :pulse_translation, buzzer_volume: 1.5
    )

    result = @factory.build(config)

    assert_equal 1.5, result.output.options[:volume]
  end

  def test_passes_volume_to_canon_output
    config = Daisenkofun::Application::Config.new(
      mode: :combined, musical_style: :heartbeat_signature, buzzer_volume: 2
    )

    result = @factory.build(config)

    assert_equal 2, result.output.options[:volume]
  end

  def test_zero_volume_selects_silent_output
    config = Daisenkofun::Application::Config.new(mode: :combined, buzzer_volume: 0)

    result = @factory.build(config)

    assert result.output.is_a?(Daisenkofun::Musical::Outputs::Null)
  end
end
