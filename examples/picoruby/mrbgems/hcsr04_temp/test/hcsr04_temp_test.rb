class HCSR04TempFakeTiming
  attr_reader :current_us, :delays

  def initialize(step_us: 10)
    @current_us = 0
    @step_us = step_us
    @delays = []
  end

  def now_us
    value = @current_us
    @current_us += @step_us
    value
  end

  def delay_us(microseconds)
    @delays << microseconds
    @current_us += microseconds
  end
end

class HCSR04TempFakeTrigger
  attr_reader :writes

  def initialize
    @writes = []
  end

  def write(value)
    @writes << value
  end
end

class HCSR04TempFakeEcho
  def initialize(timing:, rising_at_us: nil, falling_at_us: nil)
    @timing = timing
    @rising_at_us = rising_at_us
    @falling_at_us = falling_at_us
  end

  def read
    return 0 unless @rising_at_us && @falling_at_us

    current = @timing.current_us
    current >= @rising_at_us && current < @falling_at_us ? 1 : 0
  end
end

class HCSR04TempTest < Picotest::Test
  def setup
    require "hcsr04_temp"
  end

  def test_reads_pulse_width_and_distances
    timing = HCSR04TempFakeTiming.new
    trigger = HCSR04TempFakeTrigger.new
    echo = HCSR04TempFakeEcho.new(
      timing: timing,
      rising_at_us: 20_100,
      falling_at_us: 21_100
    )
    sensor = HCSR04Temp.new(trigger: trigger, echo: echo, timing: timing)

    result = sensor.read

    assert_equal 1_000, result[:pulse_width_us]
    assert_in_delta 17.175, result[:distance_cm]
    assert_in_delta 171.75, result[:distance_mm]
    assert_equal [0, 0, 1, 0], trigger.writes
    assert timing.delays.any? { |delay| delay > 19_000 }
  end

  def test_compensates_for_air_temperature
    timing = HCSR04TempFakeTiming.new
    echo = HCSR04TempFakeEcho.new(
      timing: timing,
      rising_at_us: 20_100,
      falling_at_us: 21_100
    )
    sensor = HCSR04Temp.new(
      trigger: HCSR04TempFakeTrigger.new,
      echo: echo,
      temperature_c: 0,
      timing: timing
    )

    assert_in_delta 16.575, sensor.read[:distance_cm]
    assert_in_delta 0.0, sensor.temperature_c
  end

  def test_raises_when_echo_does_not_rise
    timing = HCSR04TempFakeTiming.new
    sensor = HCSR04Temp.new(
      trigger: HCSR04TempFakeTrigger.new,
      echo: HCSR04TempFakeEcho.new(timing: timing),
      timing: timing,
      timeout_us: 100
    )

    assert_raise(HCSR04Temp::TimeoutError) { sensor.read }
  end

  def test_waits_between_measurements
    timing = HCSR04TempFakeTiming.new
    echo = HCSR04TempFakeEcho.new(
      timing: timing,
      rising_at_us: 20_100,
      falling_at_us: 21_100
    )
    sensor = HCSR04Temp.new(
      trigger: HCSR04TempFakeTrigger.new,
      echo: echo,
      timing: timing,
      measurement_interval_us: 60_000
    )

    sensor.read
    second_rise = timing.current_us + 60_000
    echo = HCSR04TempFakeEcho.new(
      timing: timing,
      rising_at_us: second_rise,
      falling_at_us: second_rise + 1_000
    )
    sensor.instance_variable_set(:@echo, echo)
    sensor.read

    assert timing.delays.any? { |delay| delay > 50_000 }
  end

  def test_rejects_invalid_timing_options
    timing = HCSR04TempFakeTiming.new
    trigger = HCSR04TempFakeTrigger.new
    echo = HCSR04TempFakeEcho.new(timing: timing)

    assert_raise(ArgumentError) do
      HCSR04Temp.new(trigger: trigger, echo: echo, timeout_us: 0, timing: timing)
    end
    assert_raise(ArgumentError) do
      HCSR04Temp.new(
        trigger: trigger,
        echo: echo,
        measurement_interval_us: -1,
        timing: timing
      )
    end
    assert_raise(ArgumentError) do
      HCSR04Temp.new(
        trigger: trigger,
        echo: echo,
        temperature_c: "20",
        timing: timing
      )
    end
  end
end
