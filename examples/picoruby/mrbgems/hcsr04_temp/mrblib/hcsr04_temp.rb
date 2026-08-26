# frozen_string_literal: true

class HCSR04Temp
  DEFAULT_TIMEOUT_US = 30_000
  DEFAULT_MEASUREMENT_INTERVAL_US = 60_000
  INITIAL_SETTLE_US = 20_000
  TRIGGER_SETTLE_US = 2
  TRIGGER_PULSE_US = 10
  BASE_SOUND_SPEED_MPS = 331.5
  SOUND_SPEED_TEMPERATURE_COEFFICIENT = 0.6

  class Timing
    def now_us
      Machine.uptime_us
    end

    def delay_us(microseconds)
      started_at = now_us
      milliseconds = microseconds / 1_000
      sleep_ms milliseconds if milliseconds > 0
      while now_us - started_at < microseconds
      end
    end
  end

  attr_reader :timeout_us, :measurement_interval_us, :temperature_c

  def initialize(
    trigger:,
    echo:,
    timeout_us: DEFAULT_TIMEOUT_US,
    measurement_interval_us: DEFAULT_MEASUREMENT_INTERVAL_US,
    temperature_c: 20.0,
    timing: nil
  )
    unless timeout_us.is_a?(Integer) && timeout_us > 0
      raise ArgumentError, "timeout_us must be a positive Integer"
    end
    unless measurement_interval_us.is_a?(Integer) && measurement_interval_us >= 0
      raise ArgumentError, "measurement_interval_us must be a non-negative Integer"
    end
    unless temperature_c.is_a?(Integer) || temperature_c.is_a?(Float)
      raise ArgumentError, "temperature_c must be an Integer or Float"
    end

    @trigger = trigger
    @echo = echo
    @timeout_us = timeout_us
    @measurement_interval_us = measurement_interval_us
    @temperature_c = temperature_c * 1.0
    @timing = timing
    @last_trigger_at = nil
    @trigger.write(0)
    @initializing_at = @timing ? @timing.now_us : Machine.uptime_us
  end

  def pulse_width_us
    return _pulse_width_us unless @timing

    pulse_width_us_with_timing
  end

  def distance_cm
    _calculate_distance_cm(pulse_width_us)
  end

  def distance_mm
    distance_cm * 10.0
  end

  def read
    width = pulse_width_us
    centimeters = _calculate_distance_cm(width)
    {
      pulse_width_us: width,
      distance_cm: centimeters,
      distance_mm: centimeters * 10.0
    }
  end

  private

  def pulse_width_us_with_timing
    wait_for_initial_settle
    wait_for_measurement_interval
    send_trigger_pulse

    rising_at = wait_for_echo(1, "to rise")
    falling_at = wait_for_echo(0, "to fall")
    falling_at - rising_at
  end

  def wait_for_initial_settle
    return unless @initializing_at

    elapsed = @timing.now_us - @initializing_at
    remaining = INITIAL_SETTLE_US - elapsed
    @timing.delay_us(remaining) if remaining > 0
    @initializing_at = nil
  end

  def wait_for_measurement_interval
    return unless @last_trigger_at

    elapsed = @timing.now_us - @last_trigger_at
    remaining = @measurement_interval_us - elapsed
    @timing.delay_us(remaining) if remaining > 0
  end

  def send_trigger_pulse
    @trigger.write(0)
    @timing.delay_us(TRIGGER_SETTLE_US)
    @trigger.write(1)
    @timing.delay_us(TRIGGER_PULSE_US)
    @trigger.write(0)
    @last_trigger_at = @timing.now_us
  end

  def wait_for_echo(level, state)
    started_at = @timing.now_us
    loop do
      now = @timing.now_us
      return now if @echo.read == level
      if now - started_at >= @timeout_us
        raise TimeoutError, "timed out waiting for ECHO #{state}"
      end
    end
  end

  private :_pulse_width_us, :_calculate_distance_cm
end
