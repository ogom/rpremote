# frozen_string_literal: true

module Goryokaku
  module Musical
    class IlluminationSoundtrack
      GAP_MS = 50
      MELODY = Buzzer::MELODIES["twinkle"]

      def initialize(output:, volume: 1, waiter: nil)
        @output = output
        @volume = volume
        @waiter = waiter
        @active = false
      end

      def start(repeat: false)
        stop
        @repeat = repeat
        @active = true
        @index = 0
        @phase = :note
        @output.start
        play_current_note
        self
      end

      def join
        wait_ms(@remaining_ms) while @active && !@repeat
        self
      end

      def stop
        @active = false
        @output.stop
        self
      end

      # Advances the melody during the same wait used by an LED frame. This
      # keeps sound and light concurrent on mruby/c, where a Task created from
      # an rpremote shell job cannot be relied on as a nested background job.
      def wait_ms(milliseconds)
        remaining = milliseconds
        while remaining > 0
          unless @active
            wait(remaining)
            break
          end

          duration = remaining < @remaining_ms ? remaining : @remaining_ms
          wait(duration)
          remaining -= duration
          @remaining_ms -= duration
          advance if @remaining_ms <= 0
        end
        self
      end

      private

      def play_current_note
        note = MELODY[@index]
        @output.play(Buzzer::TONES[note[0]], @volume)
        @remaining_ms = note[1]
      end

      def advance
        if @phase == :note
          @output.stop
          @phase = :gap
          @remaining_ms = GAP_MS
          return
        end

        @index += 1
        if @index >= MELODY.length
          unless @repeat
            @active = false
            @output.stop
            return
          end
          @index = 0
        end
        @phase = :note
        play_current_note
      end

      def wait(milliseconds)
        if @waiter
          @waiter.wait_ms(milliseconds)
        else
          sleep_ms(milliseconds)
        end
      end
    end
  end
end
