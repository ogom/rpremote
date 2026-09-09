# frozen_string_literal: true

module Daisenkofun
  module Illumination
    module Biometrics
    # Shows the moat voice that is currently sounding in the kofun canon.
      class MoatCanon < Base
        FRAME_INTERVAL_MS = 50
        MOAT_INDEX = { inner: 0, middle: 1, outer: 2 }
        MOAT_COLORS = [Color::SOFT_BLUE, Color::WATER_BLUE, Color::DEEP_WATER_BLUE]

        def initialize(cue_source:, frame_interval_ms: FRAME_INTERVAL_MS)
          @cue_source = cue_source
          @frame_interval_ms = frame_interval_ms
          @cues = []
          @last_frame_at = nil
          @clear_pending = false
          @shown_moat = nil
          @shown_level = nil
        end

        def beat(_payload)
          @cues = @cue_source.latest_cues
          @last_frame_at = nil
          @clear_pending = false
          self
        end

        def tick(display, now)
          if @clear_pending
            display.clear_buffer
            display.show
            @clear_pending = false
            @last_frame_at = now
            @shown_moat = nil
            @shown_level = nil
            return true
          end
          return false if @cues.empty?
          if @last_frame_at && now - @last_frame_at < @frame_interval_ms
            return false
          end

          cue = active_cue(now)
          moat = cue && cue[:moat]
          level = cue && (0.18 + cue[:duty_percent] * 0.08)
          return false if moat == @shown_moat && level == @shown_level

          display.clear_buffer
          if cue
            moat_index = MOAT_INDEX[cue[:moat]]
            boundaries = LedLayout::MOAT_BOUNDARIES[moat_index]
            index = 0
            while index < boundaries.length
              display.fill_outline(boundaries[index], MOAT_COLORS[moat_index], level)
              index += 1
            end
          elsif now >= @cues[@cues.length - 1][:end_ms]
            @cues = []
          end
          display.show
          @last_frame_at = now
          @shown_moat = moat
          @shown_level = level
          true
        end

        def pending?
          !@cues.empty? || @clear_pending
        end

        def reset
          @cues = []
          @last_frame_at = nil
          @clear_pending = true
          @shown_moat = nil
          @shown_level = nil
          self
        end

        private

        def active_cue(now)
          index = 0
          while index < @cues.length
            cue = @cues[index]
            return cue if now >= cue[:due_ms] && now < cue[:end_ms]

            index += 1
          end
          nil
        end
      end
    end
  end
end
