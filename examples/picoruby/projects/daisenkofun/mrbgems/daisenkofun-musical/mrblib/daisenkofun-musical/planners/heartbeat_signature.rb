# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Planners
      # Replaces every eighth canon beat with an eight-note biometric signature.
      class HeartbeatSignature
      SIGNATURE_BEATS = 8
      MOATS = [:inner, :middle, :outer]

      attr_reader :latest_cues, :signature_count

      def initialize(canon_planner: KofunCanon.new, timbre_translator: Translators::Timbre.new)
        @canon_planner = canon_planner
        @timbre_translator = timbre_translator
        @signature_count = 0
        reset
      end

      def measurement(payload)
        @canon_planner.measurement(payload)
        value = payload[:spo2]
        @latest_spo2 = value if numeric?(value) && value > 0 && value <= 100
        self
      end

      def plan(payload, received_at)
        canon_cues = @canon_planner.plan(payload, received_at)
        return unless canon_cues

        @beats << { interval_ms: payload[:interval_ms], pulse_width_ratio: payload[:pulse_width_ratio], spo2: @latest_spo2 }
        if @beats.length < SIGNATURE_BEATS
          @latest_cues = canon_cues
        else
          @signature_count += 1
          @latest_cues = build_signature(payload, received_at)
          @beats = []
        end
        @latest_cues
      end

      def reset
        @canon_planner.reset
        @beats = []
        @latest_cues = []
        @latest_spo2 = nil
        self
      end

      private

      def build_signature(payload, received_at)
        interval = payload[:interval_ms]
        slot_ms = interval / SIGNATURE_BEATS
        first_spo2 = @beats[0][:spo2]
        cues = []
        index = 0
        while index < @beats.length
          beat = @beats[index]
          note_index = nearest_note_index(256_000.0 / beat[:interval_ms])
          if index > 0
            difference = beat[:interval_ms] - @beats[index - 1][:interval_ms]
            note_index += 1 if difference <= -40
            note_index -= 1 if difference >= 40
          end
          if first_spo2 && beat[:spo2]
            oxygen_difference = beat[:spo2] - first_spo2
            note_index += 1 if oxygen_difference > 0.5
            note_index -= 1 if oxygen_difference < -0.5
          end
          note_index = 0 if note_index < 0
          note_index = Translators::Pulse::NOTES.length - 1 if note_index >= Translators::Pulse::NOTES.length
          timbre = @timbre_translator.translate(beat)
          due = received_at + slot_ms * index
          moat = MOATS[index % MOATS.length]
          duration = beat[:interval_ms] / 12
          duration = 45 if duration < 45
          duration = 90 if duration > 90
          cues << {
            moat: moat,
            slot: index,
            due_ms: due,
            end_ms: due + slot_ms,
            beat_ms: payload[:timestamp_ms],
            interval_ms: interval,
            frequency_hz: Translators::Pulse::NOTES[note_index],
            duration_ms: duration,
            duty_percent: timbre[:duty_percent],
            pulse_width_ratio: timbre[:pulse_width_ratio],
            direction: oxygen_direction(first_spo2, beat[:spo2]),
            travel_direction: 0,
            phrase: @signature_count,
            phrase_order: MOATS,
            source: :heartbeat_signature
          }
          index += 1
        end
        cues
      end

      def nearest_note_index(frequency)
        notes = Translators::Pulse::NOTES
        nearest = 0
        index = 1
        while index < notes.length
          nearest = index if (notes[index] - frequency).abs < (notes[nearest] - frequency).abs
          index += 1
        end
        nearest
      end

      def oxygen_direction(first, current)
        return 0 unless first && current
        return 1 if current - first > 0.5
        return -1 if current - first < -0.5

        0
      end

      def numeric?(value)
        value.is_a?(Integer) || value.is_a?(Float)
      end
      end
    end
  end
end
