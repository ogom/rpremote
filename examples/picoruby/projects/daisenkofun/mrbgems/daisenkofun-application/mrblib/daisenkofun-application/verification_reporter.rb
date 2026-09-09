# frozen_string_literal: true

module Daisenkofun
  module Application
    class VerificationReporter
      def initialize(logger:)
        @logger = logger
      end

      def report(config, composition)
        return unless config.combined?
        return unless config.buzzer_pin
        return if config.musical_style == :pulse_translation

        verification = composition.musical_output.verification
        summary = "DAISENKOFUN mode=combined component=musical event=verification " \
                  "status=#{verification[:status]} cues=#{verification[:cues]} max_delay_ms=#{verification[:max_delay_ms]}"
        if config.musical_style == :heartbeat_signature
          summary += " signatures=#{composition.musical_planner.signature_count}"
        end
        @logger.puts(summary)
      end
    end
  end
end
