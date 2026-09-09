# frozen_string_literal: true

module Daisenkofun
  module Illumination
    module Biometrics
      class Base
        def beat(_payload)
          self
        end

        def tick(_display, _now_ms)
          false
        end

        def reset
          self
        end

        def pending?
          false
        end
      end
    end
  end
end
