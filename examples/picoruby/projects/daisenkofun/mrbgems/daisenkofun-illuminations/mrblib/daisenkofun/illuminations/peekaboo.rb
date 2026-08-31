# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Peekaboo < Base
      def call
        rows = LedLayout.scene_rows
        each_loop do
          each_phase(9) do |phase|
            @display.clear_buffer
            reveal = sin_level(phase, 0.0, 1.0)
            limit = (4 + reveal * (rows.length - 4)).to_i
            row_index = 0
            while row_index < limit
              @display.fill_indices(rows[row_index], Color::PASTEL[row_index % Color::PASTEL.length], 0.14 + reveal * 0.18)
              row_index += 1
            end
            @display.attached(Color::PASTEL[1], 0.12 + reveal * 0.26, 0.12 + reveal * 0.22)
            show_frame
          end
        end
      end
    end
  end
end
