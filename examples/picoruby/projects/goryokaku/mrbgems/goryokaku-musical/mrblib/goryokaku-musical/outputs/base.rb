# frozen_string_literal: true
module Goryokaku
  module Musical
    module Outputs
      class Base
        def start; self; end
        def play(_frequency, _volume); end
        def stop; end
      end
    end
  end
end
