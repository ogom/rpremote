# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Planners
      # Builds three sequential moat voices from one measured heartbeat.
      class KofunCanon
      MOATS = [:inner, :middle, :outer]
      SCALE_OFFSETS = { inner: 0, middle: 2, outer: 4 }
      DUTY_OFFSETS = { inner: 0.4, middle: 0.0, outer: -0.4 }
      INTERVAL_DIRECTION_THRESHOLD_MS = 40
      PHRASE_BEATS = 4

      attr_reader :latest_cues

      def initialize(pulse_translator: Translators::Pulse.new, timbre_translator: Translators::Timbre.new)
        @pulse_translator = pulse_translator
        @timbre_translator = timbre_translator
        reset
      end

      def measurement(payload)
        @pulse_translator.measurement(payload)
        self
      end

      def plan(payload, received_at)
        interval = payload[:interval_ms]
        at = payload[:timestamp_ms]
        notes = @pulse_translator.notes(interval, at)
        return unless notes

        update_travel_direction(interval)
        update_phrase_order if @beat_count % PHRASE_BEATS == 0
        @position = (@position + @travel_direction) % MOATS.length
        timbre = @timbre_translator.translate(payload)
        order = rotate(@phrase_order, @position)
        phrase = @beat_count / PHRASE_BEATS + 1
        duration = interval / 8
        duration = 90 if duration > 90
        @latest_cues = []
        slot = 0
        while slot < order.length
          moat = order[slot]
          due = received_at + interval * slot / 3
          @latest_cues << {
            moat: moat,
            slot: slot,
            due_ms: due,
            end_ms: received_at + interval * (slot + 1) / 3,
            beat_ms: at,
            interval_ms: interval,
            frequency_hz: moat_frequency(notes[0], moat),
            duration_ms: duration,
            duty_percent: moat_duty(timbre[:duty_percent], moat),
            pulse_width_ratio: timbre[:pulse_width_ratio],
            direction: @pulse_translator.direction,
            travel_direction: @travel_direction,
            phrase: phrase,
            phrase_order: @phrase_order
          }
          slot += 1
        end
        @previous_interval = interval
        @beat_count += 1
        @latest_cues
      end

      def reset
        @pulse_translator.reset
        @latest_cues = []
        @previous_interval = nil
        @travel_direction = 1
        @position = -1
        @beat_count = 0
        @phrase_order = MOATS
        self
      end

      private

      def update_travel_direction(interval)
        return unless @previous_interval

        difference = interval - @previous_interval
        if difference <= -INTERVAL_DIRECTION_THRESHOLD_MS
          @travel_direction = 1
        elsif difference >= INTERVAL_DIRECTION_THRESHOLD_MS
          @travel_direction = -1
        end
      end

      def update_phrase_order
        @phrase_order = if @pulse_translator.direction > 0
                          [:middle, :outer, :inner]
                        elsif @pulse_translator.direction < 0
                          [:outer, :inner, :middle]
                        else
                          MOATS
                        end
      end

      def rotate(order, position)
        rotated = []
        index = 0
        while index < order.length
          rotated << order[(index + position) % order.length]
          index += 1
        end
        rotated
      end

      def moat_frequency(base_frequency, moat)
        notes = Translators::Pulse::NOTES
        base_index = 0
        base_index += 1 while base_index < notes.length && notes[base_index] != base_frequency
        index = base_index + SCALE_OFFSETS[moat]
        index = notes.length - 1 if index >= notes.length
        notes[index]
      end

      def moat_duty(base_duty, moat)
        duty = base_duty + DUTY_OFFSETS[moat]
        duty = Translators::Timbre::MIN_DUTY if duty < Translators::Timbre::MIN_DUTY
        duty = Translators::Timbre::MAX_DUTY if duty > Translators::Timbre::MAX_DUTY
        duty.round(1)
      end
      end
    end
  end
end
