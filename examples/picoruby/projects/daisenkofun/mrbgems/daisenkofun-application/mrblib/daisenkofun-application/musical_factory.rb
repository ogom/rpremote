# frozen_string_literal: true

module Daisenkofun
  module Application
    class MusicalFactory
      class Result
        attr_reader :planner, :output, :pattern

        def initialize(planner:, output:, pattern:)
          @planner = planner
          @output = output
          @pattern = pattern
        end
      end

      def initialize(clock:, logger:)
        @clock = clock
        @logger = logger
      end

      def build(config)
        return silent_result unless config.buzzer_pin
        return pulse_result(config.buzzer_pin) if config.musical_style == :pulse_translation

        canon_result(config)
      end

      private

      def silent_result
        Result.new(planner: nil, output: Daisenkofun::Musical::Outputs::Null.new, pattern: nil)
      end

      def pulse_result(pin)
        output = Daisenkofun::Musical::Outputs::PWM.new(pin: pin, clock: @clock, logger: @logger)
        Result.new(planner: nil, output: output, pattern: nil)
      end

      def canon_result(config)
        planner = Daisenkofun::Musical::Planners::KofunCanon.new
        if config.musical_style == :heartbeat_signature
          planner = Daisenkofun::Musical::Planners::HeartbeatSignature.new(canon_planner: planner)
        end
        pattern = Daisenkofun::Illumination::Biometrics::MoatCanon.new(cue_source: planner)
        output = Daisenkofun::Musical::Outputs::KofunCanon.new(pin: config.buzzer_pin, clock: @clock, logger: @logger, planner: planner)
        Result.new(planner: planner, output: output, pattern: pattern)
      end
    end
  end
end
