# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module StatusLed
      class NullRenderer
        def render(mode, timestamp_ms, spo2:, bpm:, last_beat_at:)
          self
        end

        def clear
          self
        end

        def error
          self
        end
      end
    end
  end
end
