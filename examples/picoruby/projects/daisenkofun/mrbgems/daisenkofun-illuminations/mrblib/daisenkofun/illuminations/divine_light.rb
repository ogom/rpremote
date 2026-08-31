# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class DivineLight < Base
      def call
        each_loop do
          @display.clear_buffer

          each_outline do |outline_index|
            light_sides(outline_index)
            light_circle(outline_index)
          end

          # 中堤上の2基は補色で同時に点灯します。
          @display.attached(
            Daisenkofun::Color.rainbow(0),
            Config::MAX_FULL_SCENE_LEVEL,
            Config::MAX_FULL_SCENE_LEVEL
          )
          @display.set(
            LedLayout::DAIANJIYAMA,
            Daisenkofun::Color.rainbow(3),
            Config::MAX_FULL_SCENE_LEVEL
          )
          show_frame
        end
      end

      private

      def light_sides(outline_index)
        left = LedLayout.left_order(outline_index)
        right = LedLayout.right_order(outline_index)
        count = left.length > right.length ? left.length : right.length
        position = 0
        while position < count
          if position < left.length
            @display.set(
              left[position],
              Daisenkofun::Color.rainbow(position * Daisenkofun::Color::RAINBOW.length / left.length),
              Config::MAX_FULL_SCENE_LEVEL
            )
          end
          if position < right.length
            @display.set(
              right[position],
              Daisenkofun::Color.rainbow(position * Daisenkofun::Color::RAINBOW.length / right.length),
              Config::MAX_FULL_SCENE_LEVEL
            )
          end
          show_frame
          position += 1
        end
      end

      def light_circle(outline_index)
        circle = LedLayout.circle_order(outline_index)
        half = (circle.length + 1) / 2
        position = 0
        while position < half
          color = Daisenkofun::Color.rainbow(position * Daisenkofun::Color::RAINBOW.length / half)
          @display.set(circle[position], color, Config::MAX_FULL_SCENE_LEVEL)
          @display.set(circle[circle.length - 1 - position], color, Config::MAX_FULL_SCENE_LEVEL)
          show_frame
          position += 1
        end
      end
    end
  end
end
