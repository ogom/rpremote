# frozen_string_literal: true

module Machine
  def self.board_millis
    0
  end
end

module Kernel
  def sleep_ms(_milliseconds)
  end unless method_defined?(:sleep_ms)
end
