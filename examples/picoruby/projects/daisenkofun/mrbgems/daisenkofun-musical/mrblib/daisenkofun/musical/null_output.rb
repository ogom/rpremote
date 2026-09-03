# frozen_string_literal: true

module Daisenkofun
  module Musical
    # Safe default until the installation's audio pins and output device are chosen.
    class NullOutput
      def start
        self
      end

      def beat(_payload)
        self
      end

      def tick(_now)
        self
      end

      def stop
        self
      end
    end
  end
end
