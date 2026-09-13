# frozen_string_literal: true
module Goryokaku
  module Musical
    class Subscriber
      def initialize(output:, volume: 1, mode: :illumination)
        @output = output
        @volume = volume
        @queue = []
        @playing_until = nil
        @mode = mode
      end

      def start; @output.start; self; end
      def on_event(event)
        if event[0] == :mode_changed
          change_mode(event[1])
        elsif event[0] == :tambourine_shaken && @mode == :tambourine
          enqueue_sequence(event[1], event[2], Cues.shake(event[3], event[4]))
        elsif event[0] == :tambourine_struck && @mode == :tambourine
          enqueue_sequence(event[1], event[2], Cues.strike(event[3]))
        elsif event[0] == :tambourine_inactive
          silence
        end
      end

      def tick(now)
        if @playing_until && now >= @playing_until
          @output.stop
          @playing_until = nil
        end
        return if @playing_until || @queue.empty?

        while !@queue.empty? && now >= @queue[0][0] + @queue[0][2]
          @queue.shift
        end
        return if @queue.empty? || now < @queue[0][0]

        cue = @queue.shift
        level = (0.5 + cue[3] * 0.5) * cue[4]
        @output.play(cue[1], @volume * level)
        @playing_until = cue[0] + cue[2]
      end

      def stop
        @queue = []
        @playing_until = nil
        @output.stop
      end

      private

      def enqueue_sequence(started_at, intensity, sequence)
        return if @playing_until || !@queue.empty?

        index = 0
        while index < sequence.length
          cue = sequence[index]
          @queue << [started_at + cue[0], cue[1], cue[2], intensity, cue[3]]
          index += 1
        end
      end

      def silence
        @queue = []
        @playing_until = nil
        @output.stop
      end

      def change_mode(mode)
        @mode = mode
        return unless @mode == :illumination
        silence
      end
    end
  end
end
