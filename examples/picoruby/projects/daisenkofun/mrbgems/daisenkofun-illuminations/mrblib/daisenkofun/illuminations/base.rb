# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Base
      def initialize(display, wait_ms = Config::SINGLE_FRAME_INTERVAL_MS, loops = 1)
        @display = display
        @wait_ms = wait_ms
        @loops = loops
      end

      private

      def draw_structure(visible_count, level)
        index = 0
        while index < visible_count
          @display.fill_outline(index, structure_color(index), level)
          index += 1
        end
      end

      def pulse_level(step, low, high)
        position = step % 20
        position = 20 - position if position > 10
        low + (high - low) * position / 10.0
      end

      def sin_level(phase, low, high)
        low + (high - low) * (Math.sin(phase * Math::PI / 180.0) + 1.0) * 0.5
      end

      def each_loop
        loop_index = 0
        while loop_index < @loops
          yield
          loop_index += 1
        end
      end

      def each_phase(increment)
        phase = 0
        while phase < 360
          yield phase
          phase += increment
        end
      end

      def each_step(count, increment = 1)
        step = 0
        while step < count
          yield step
          step += increment
        end
      end

      def each_outline
        outline = 0
        while outline < LedLayout::OUTLINE_COUNT
          yield outline
          outline += 1
        end
      end

      def each_scene_row
        rows = LedLayout.scene_rows
        index = 0
        while index < rows.length
          yield rows[index], index, index.to_f / (rows.length - 1)
          index += 1
        end
      end

      def show_frame
        @display.show
        sleep_ms @wait_ms
      end

      def fade_trail(level)
        @display.scale_all(level)
      end

      def fill_outline_palette(colors, level)
        each_outline do |outline|
          @display.fill_outline(outline, colors[outline % colors.length], level)
        end
      end

      def draw_row_wave(first_color, second_color, phase, phase_offset, base_level, wave_level)
        each_scene_row do |row, row_index, _row_amount|
          wave = sin_level(phase + row_index * phase_offset, 0.0, 1.0)
          @display.fill_indices(row, Color.blend(first_color, second_color, wave), base_level + wave * wave_level)
        end
      end

      def draw_soft_base(color, level = 0.12)
        @display.fill_indices(LedLayout.main_order, color, level)
      end

      def pulse_attached(phase, color, offset = 0, low = 0.08, high = 0.50)
        @display.attached(
          color,
          sin_level(phase, low, high),
          sin_level(phase + offset, low, high)
        )
      end

      def arrival_marker(position, total, color)
        return if total <= 0

        phase = position * 360 / total
        pulse_attached(phase, color, 60, 0.10, 0.44)
      end

      def draw_comet(order, head, color, tail = 14, head_level = 0.50)
        offset = 0
        while offset < tail
          level = head_level * (tail - offset).to_f / tail
          @display.set(order[(head - offset) % order.length], color, level)
          offset += 1
        end
      end

      def deterministic_sparks(order, color, count, step, level = 0.38)
        spark = 0
        while spark < count
          @display.set(order[(step * 47 + spark * 83) % order.length], color, level)
          spark += 1
        end
      end

      def structure_color(index)
        case index
        when LedLayout::MOUND_TOP
          Color::SOFT_GOLD
        when LedLayout::MOUND_MIDDLE
          Color::SUNRISE_ORANGE
        when LedLayout::MOUND_BASE
          Color::FOREST_SUNLIGHT
        when LedLayout::INNER_BANK
          Color::FOREST_CANOPY_GREEN
        else
          Color::FOREST_DEEP_GREEN
        end
      end
    end
  end
end
