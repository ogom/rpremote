# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Outputs
      class Base
        def start
          self
        end

        def measurement(_payload)
          self
        end

        def beat(_payload)
          self
        end

        def reset(_reason = nil)
          self
        end

        def tick(_now_ms)
          self
        end

        def stop
          self
        end
      end
    end
  end
end
