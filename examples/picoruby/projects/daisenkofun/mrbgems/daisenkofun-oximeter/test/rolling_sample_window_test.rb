# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterRollingSampleWindowTest < Picotest::Test
  def test_calculates_rolling_values_and_clears_them
    statistics = Daisenkofun::Oximeter::Measurement::RollingSampleWindow.new(3)
    statistics.push(1)
    statistics.push(2)
    statistics.push(3)

    assert_equal 3, statistics.count
    assert_in_delta 2.0, statistics.average
    assert_in_delta 0.816_497, statistics.standard_deviation

    statistics.push(7)
    assert_equal 3, statistics.count
    assert_in_delta 4.0, statistics.average

    statistics.clear
    assert_equal 0, statistics.count
    assert_in_delta 0.0, statistics.average
  end

  def test_requires_a_positive_integer_capacity
    window = Daisenkofun::Oximeter::Measurement::RollingSampleWindow

    assert_raise(ArgumentError) { window.new(0) }
    assert_raise(ArgumentError) { window.new(-1) }
    assert_raise(ArgumentError) { window.new(1.5) }
  end
end
