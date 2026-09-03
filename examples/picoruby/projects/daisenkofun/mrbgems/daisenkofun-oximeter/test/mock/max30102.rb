# frozen_string_literal: true

class MAX30102
  def initialize(i2c:)
    @i2c = i2c
  end
end
