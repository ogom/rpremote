# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class LaunchFireworks < Base
      LAUNCH_STEPS = 21
      OUTLINE_PULSES = 3
      SPARKLE_STEPS = 24
      SPARK_COUNT = 12

      def call
        each_loop do
          @display.clear_buffer
          launch_trail
          expand_burst
          scatter_sparks
        end
      end

      private

      def launch_trail
        each_step(LAUNCH_STEPS) do |step|
          fade_trail(0.66)
          level = 0.18 + step * 0.012
          color = Color.blend(Color::SOFT_BLUE, Color::LAVENDER, step.to_f / (LAUNCH_STEPS - 1))
          range = LedLayout.outline_range(LedLayout::MOUND_TOP)
          index = range[1] - step * 2
          index = range[0] if index < range[0]
          @display.set(index, color, level)
          @display.attached(color, level * 0.7, level * 0.55)
          show_frame
        end
      end

      def expand_burst
        each_outline do |outline_index|
          each_step(OUTLINE_PULSES) do |pulse|
            fade_trail(0.74)
            level = Config::MAX_FIREWORK_LEVEL - pulse * 0.05
            @display.fill_outline(outline_index, Color::FIREWORK[outline_index], level)
            if outline_index == LedLayout::MIDDLE_BANK
              @display.attached(Color::FIREWORK[outline_index], level, level * 0.82)
            end
            show_frame
          end
        end
      end

      def scatter_sparks
        each_step(SPARKLE_STEPS) do |step|
          fade_trail(0.80)
          spark = 0
          while spark < SPARK_COUNT
            outline = LedLayout.outline_range(spark % LedLayout::OUTLINE_COUNT)
            count = outline[1] - outline[0] + 1
            index = outline[0] + (spark * 31 + step * 7) % count
            color = Color::FIREWORK[(spark + step) % Color::FIREWORK.length]
            @display.set(index, color, 0.22 + (spark % 4) * 0.04)
            spark += 1
          end
          @display.attached(Color::FIREWORK[step % Color::FIREWORK.length], 0.30, 0.24)
          show_frame
        end
      end
    end
  end
end
