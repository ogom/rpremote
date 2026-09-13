# frozen_string_literal: true
module Goryokaku
  module Musical
    module Cues
      TONES = {
        "C4" => 262, "D4" => 294, "E4" => 330, "F4" => 349,
        "G4" => 392, "A4" => 440, "B4" => 494,
        "C5" => 523, "D5" => 587, "E5" => 659, "F5" => 698,
        "G5" => 784, "A5" => 880, "B5" => 988,
        "C6" => 1047, "D6" => 1175, "E6" => 1319, "F6" => 1397,
        "G6" => 1568, "A6" => 1760, "B6" => 1976,
        "C7" => 2093, "D7" => 2349, "E7" => 2637, "R" => 0, "REST" => 0
      }
      MOTION = {
        x: [3_000, 60],
        y: [1_000, 60],
        z: [150, 120]
      }
      SHAKE_FREQUENCIES = {
        left: [4_600, 7_400, 5_200, 6_500, 4_200],
        right: [4_200, 6_500, 5_200, 7_400, 4_600]
      }
      SHAKE_LEVELS = [1.0, 0.82, 0.66, 0.48, 0.30]
      STRIKE_FREQUENCIES = [5_200, 7_800, 4_600, 6_900, 4_100, 5_800]
      STRIKE_LEVELS = [1.0, 0.90, 0.76, 0.60, 0.44, 0.28]

      def self.frequency(note)
        value = TONES[note]
        raise ArgumentError, "unknown note: #{note}" unless value
        value
      end

      def self.motion(axis)
        cue = MOTION[axis]
        raise ArgumentError, "unknown motion axis: #{axis}" unless cue

        cue
      end

      def self.shake(direction, duration_ms)
        frequencies = SHAKE_FREQUENCIES[direction]
        raise ArgumentError, "unknown shake direction: #{direction}" unless frequencies

        step_ms = duration_ms / frequencies.length
        step_ms = 1 if step_ms < 1
        sequence = []
        index = 0
        while index < frequencies.length
          sequence << [index * step_ms, frequencies[index], step_ms, SHAKE_LEVELS[index]]
          index += 1
        end
        sequence
      end

      def self.strike(duration_ms)
        step_ms = duration_ms / STRIKE_FREQUENCIES.length
        step_ms = 1 if step_ms < 1
        sequence = []
        index = 0
        while index < STRIKE_FREQUENCIES.length
          sequence << [index * step_ms, STRIKE_FREQUENCIES[index], step_ms, STRIKE_LEVELS[index]]
          index += 1
        end
        sequence
      end
    end
  end
end
