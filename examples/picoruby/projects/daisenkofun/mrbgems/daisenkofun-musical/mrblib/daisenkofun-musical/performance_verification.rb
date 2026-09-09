# frozen_string_literal: true

module Daisenkofun
  module Musical
    # Builds stable, machine-readable summaries for normal and diagnostic runs.
    class PerformanceVerification
      def self.pulse(output, min_main_notes: 10, max_main_delay_ms: 25, min_baselines: 2, min_pulse_notes: 10)
        verified = output.main_note_count >= min_main_notes && output.max_main_delay_ms <= max_main_delay_ms &&
          output.baseline_count >= min_baselines && output.pulse_timbre_count >= min_pulse_notes
        {
          status: verified ? :ok : :incomplete,
          main_notes: output.main_note_count,
          max_main_delay_ms: output.max_main_delay_ms,
          baselines: output.baseline_count,
          pulse_notes: output.pulse_timbre_count,
          duty_min: output.min_duty_percent,
          duty_max: output.max_duty_percent
        }
      end

      def self.canon(output, min_cues: 15, max_delay_ms: 25)
        verified = output.cue_count >= min_cues && output.max_delay_ms <= max_delay_ms
        { status: verified ? :ok : :incomplete, cues: output.cue_count, max_delay_ms: output.max_delay_ms }
      end
    end
  end
end
