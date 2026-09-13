# frozen_string_literal: true

module Goryokaku
  module Musical
    class Buzzer
      # Kept as a self-contained compatibility facade. New event-driven code uses Cues.
      TONES = {
        "C4" => 262, "D4" => 294, "E4" => 330, "F4" => 349,
        "G4" => 392, "A4" => 440, "B4" => 494,
        "C5" => 523, "D5" => 587, "E5" => 659, "F5" => 698,
        "G5" => 784, "A5" => 880, "B5" => 988,
        "C6" => 1047, "D6" => 1175, "E6" => 1319, "F6" => 1397,
        "G6" => 1568, "A6" => 1760, "B6" => 1976,
        "C7" => 2093, "D7" => 2349, "E7" => 2637,
        "R" => 0, "REST" => 0
      }

      MELODIES = {
        "tan_tan" => [
          ["C6", 60], ["R", 30], ["C6", 60]
        ],
        "shaka_cw" => [
          ["E7", 30], ["R", 15], ["C7", 30], ["R", 15],
          ["E7", 30], ["R", 15], ["C7", 30], ["R", 15],
          ["E7", 30], ["R", 15], ["C7", 30], ["R", 15],
          ["E7", 30], ["R", 15], ["C7", 30]
        ],
        "shaka_ccw" => [
          ["D7", 30], ["R", 15], ["A6", 30], ["R", 15],
          ["D7", 30], ["R", 15], ["A6", 30], ["R", 15],
          ["D7", 30], ["R", 15], ["A6", 30], ["R", 15],
          ["D7", 30], ["R", 15], ["A6", 30]
        ],
        "twinkle" => [
          ["C4", 400], ["C4", 400], ["G4", 400], ["G4", 400],
          ["A4", 400], ["A4", 400], ["G4", 800],
          ["F4", 400], ["F4", 400], ["E4", 400], ["E4", 400],
          ["D4", 400], ["D4", 400], ["C4", 800]
        ]
      }

      attr_reader :volume

      def initialize(pin:, volume: 1, pwm: nil)
        unless pwm
          require "pwm"
          pwm = ::PWM.new(pin)
        end
        @pwm = pwm
        @volume = volume
      end

      def volume=(value)
        @volume = value
      end

      def play_tone(frequency, duration_ms)
        if frequency == 0
          @pwm.duty(0)
        else
          @pwm.frequency(frequency)
          @pwm.duty(@volume)
        end
        sleep_ms(duration_ms)
      end

      def play_note(note, duration_ms)
        frequency = TONES[note]
        raise ArgumentError, "unknown note: #{note}" unless frequency

        play_tone(frequency, duration_ms)
      end

      def stop
        @pwm.duty(0)
      end

      def play_melody(melody, gap_ms = 50)
        if melody.is_a?(String)
          melody = MELODIES[melody]
          raise ArgumentError, "unknown melody" unless melody
        end

        index = 0
        while index < melody.length
          play_note(melody[index][0], melody[index][1])
          stop
          sleep_ms(gap_ms)
          index += 1
        end
        stop
      end
    end
  end
end
