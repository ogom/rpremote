# frozen_string_literal: true

class PWM
  attr_reader :frequencies, :duties

  def initialize(_pin)
    @frequencies = []
    @duties = []
  end

  def frequency(value)
    @frequencies << value
  end

  def duty(value)
    @duties << value
  end
end
