# frozen_string_literal: true

module Goryokaku
  module Illumination
    class TambourinePlayer
      STRIKE_FRAME_COUNT = 6
      STRIKE_TRAIL_LENGTH = 4

      def initialize(device: nil, pin: Config::LED_PIN, num: LedLayout::LED_COUNT)
        @device = device || Device.new(pin: pin, num: num)
        @effect = nil
      end

      def start
        @device.open
        @device.clear
        self
      end

      def on_event(event)
        type = event[0]
        if type == :tambourine_shaken
          @effect = [:shake, event[1], event[2], event[3], event[4]]
        elsif type == :tambourine_struck
          @effect = [:strike, event[1], event[2], event[3]]
        elsif type == :tambourine_inactive
          clear
        end
      end

      def tick(now)
        return unless @effect

        elapsed = now - @effect[1]
        return clear if elapsed >= duration

        @effect[0] == :shake ? draw_shake(elapsed) : draw_strike(elapsed)
      end

      def clear
        @effect = nil
        @device.clear
      end

      def stop
        @effect = nil
        @device.close
      end

      private

      def duration; @effect[0] == :shake ? @effect[4] : @effect[3]; end
      def display; @device.display; end

      def draw_shake(elapsed)
        groups = LedLayout.musical_groups(@effect[3])
        frame_duration = duration / groups.length
        frame_duration = 1 if frame_duration < 1
        frame = (elapsed / frame_duration) % groups.length
        group = groups[frame]
        level = Config::BRIGHTNESS * (0.5 + @effect[2] * 0.5)
        display.clear_buffer
        display.fill_indices(group, Color::FIREWORK[frame % Color::FIREWORK.length], level)
        if frame > 0
          display.fill_indices(groups[frame - 1], Color::FIREWORK[(frame - 1) % Color::FIREWORK.length], level * 0.42)
        end
        display.fill_zone(LedLayout::RAVELIN, frame % 2 == 0 ? Color::WHITE : Color::GOLD, level * 0.55)
        draw_outer_sparks(frame, level * 0.70)
        display.show
      end

      def draw_strike(elapsed)
        frame = elapsed * STRIKE_FRAME_COUNT / duration
        frame = STRIKE_FRAME_COUNT - 1 if frame >= STRIKE_FRAME_COUNT
        level = Config::BRIGHTNESS * (0.5 + @effect[2] * 0.5)
        rays = LedLayout.star_rays
        display.clear_buffer
        display.fill_zone(LedLayout::STAR, Color::GOLD, level * 0.10)
        ray_index = 0
        while ray_index < rays.length
          head = (rays[ray_index].length - 1) * frame / (STRIKE_FRAME_COUNT - 1)
          trail = 0
          while trail < STRIKE_TRAIL_LENGTH
            position = head - trail
            if position >= 0
              color = Color::FIREWORK[(ray_index + frame + trail) % Color::FIREWORK.length]
              trail_level = level * (STRIKE_TRAIL_LENGTH - trail) / STRIKE_TRAIL_LENGTH.to_f
              display.set(rays[ray_index][position], color, trail_level)
            end
            trail += 1
          end
          ray_index += 1
        end
        accent = frame % 2 == 0 ? Color::WHITE : Color::FIREWORK[frame % Color::FIREWORK.length]
        display.fill_zone(LedLayout::RAVELIN, accent, level)
        if frame >= STRIKE_FRAME_COUNT / 2
          outer_level = level * (STRIKE_FRAME_COUNT - frame) / (STRIKE_FRAME_COUNT / 2).to_f
          display.fill_zone(LedLayout::OUTER, Color::FIREWORK[(frame + 2) % Color::FIREWORK.length], outer_level)
        else
          draw_outer_sparks(frame, level * 0.70)
        end
        display.show
      end

      def draw_outer_sparks(frame, level)
        order = LedLayout.outer_order(frame * 7)
        index = 0
        while index < order.length
          color = Color::FIREWORK[(frame + index / 19) % Color::FIREWORK.length]
          display.set(order[index], color, level)
          index += 19
        end
      end
    end
  end
end
