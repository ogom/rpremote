# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuMusicalBuzzerTest < Picotest::Test
  def test_plays_named_notes_and_stops
    pwm = PWM.new(2)
    buzzer = Goryokaku::Musical::Buzzer.new(pin: 2, volume: 0.5, pwm: pwm)

    buzzer.play_note("A4", 10)
    buzzer.stop

    assert_equal [440], pwm.frequencies
    assert_equal [0.5, 0], pwm.duties
  end

  def test_plays_the_migrated_named_melody
    pwm = PWM.new(2)
    buzzer = Goryokaku::Musical::Buzzer.new(pin: 2, pwm: pwm)

    buzzer.play_melody("tan_tan", 0)

    assert_equal [1047, 1047], pwm.frequencies
    assert_equal 0, pwm.duties[-1]
  end

  def test_rejects_an_unknown_note
    buzzer = Goryokaku::Musical::Buzzer.new(pin: 2, pwm: PWM.new(2))

    assert_raise(ArgumentError) { buzzer.play_note("H4", 10) }
  end
end
