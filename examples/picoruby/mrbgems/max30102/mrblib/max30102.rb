# frozen_string_literal: true

require "i2c"

class MAX30102
  class DeviceNotFoundError < StandardError; end
  class ResetTimeoutError < StandardError; end

  ADDRESS = 0x57
  PART_ID_VALUE = 0x15

  INTERRUPT_STATUS_1 = 0x00
  FIFO_WRITE_POINTER = 0x04
  OVERFLOW_COUNTER = 0x05
  FIFO_READ_POINTER = 0x06
  FIFO_DATA = 0x07
  FIFO_CONFIG = 0x08
  MODE_CONFIG = 0x09
  SPO2_CONFIG = 0x0A
  LED1_PA = 0x0C
  LED2_PA = 0x0D
  DIE_TEMP_INTEGER = 0x1F
  DIE_TEMP_FRACTION = 0x20
  DIE_TEMP_CONFIG = 0x21
  REVISION_ID = 0xFE
  PART_ID = 0xFF

  RESET_BIT = 0x40
  SHUTDOWN_BIT = 0x80
  MODE_SPO2 = 0x03
  FIFO_POINTER_MASK = 0x1F
  FRAME_SIZE = 6
  RESET_TIMEOUT_MS = 200
  TEMPERATURE_TIMEOUT_MS = 100

  FIFO_AVERAGES = { avg1: 0, avg2: 1, avg4: 2, avg8: 3, avg16: 4, avg32: 5 }
  SAMPLE_RATES = { hz50: 0, hz100: 1, hz200: 2, hz400: 3, hz800: 4, hz1000: 5, hz1600: 6, hz3200: 7 }
  PULSE_WIDTHS = { us69: 0, us118: 1, us215: 2, us411: 3 }
  ADC_RANGES = { n2048: 0, n4096: 1, n8192: 2, n16384: 3 }

  attr_reader :address, :fifo_average, :sample_rate, :pulse_width, :adc_range

  def initialize(i2c:, address: ADDRESS, fifo_average: :avg4, sample_rate: :hz100,
                 pulse_width: :us411, adc_range: :n4096,
                 red_led_amplitude: 0x24, ir_led_amplitude: 0x24)
    raise ArgumentError, "address must be 0x57" unless address == ADDRESS

    validate(fifo_average, FIFO_AVERAGES, "fifo_average")
    validate(sample_rate, SAMPLE_RATES, "sample_rate")
    validate(pulse_width, PULSE_WIDTHS, "pulse_width")
    validate(adc_range, ADC_RANGES, "adc_range")
    validate_amplitude(red_led_amplitude, "red_led_amplitude")
    validate_amplitude(ir_led_amplitude, "ir_led_amplitude")

    @i2c = i2c
    @address = address
    raise DeviceNotFoundError, "MAX30102 not found at 0x57" unless connected?

    reset
    configure(
      fifo_average: fifo_average,
      sample_rate: sample_rate,
      pulse_width: pulse_width,
      adc_range: adc_range,
      red_led_amplitude: red_led_amplitude,
      ir_led_amplitude: ir_led_amplitude
    )
  end

  def connected?
    part_id == PART_ID_VALUE
  end

  def part_id
    read_register(PART_ID)
  end

  def revision_id
    read_register(REVISION_ID)
  end

  def reset
    write_register(MODE_CONFIG, RESET_BIT)
    elapsed = 0
    while (read_register(MODE_CONFIG) & RESET_BIT) != 0
      raise ResetTimeoutError, "MAX30102 reset timed out" if elapsed >= RESET_TIMEOUT_MS

      sleep_ms 1
      elapsed += 1
    end
    true
  end

  def clear_fifo
    write_register(FIFO_WRITE_POINTER, 0)
    write_register(OVERFLOW_COUNTER, 0)
    write_register(FIFO_READ_POINTER, 0)
    self
  end

  def available_samples
    write_pointer = read_register(FIFO_WRITE_POINTER) & FIFO_POINTER_MASK
    read_pointer = read_register(FIFO_READ_POINTER) & FIFO_POINTER_MASK
    (write_pointer - read_pointer) & FIFO_POINTER_MASK
  end

  def sample_available?
    available_samples > 0
  end

  def read_fifo
    red, ir = _decode_frame(read_registers(FIFO_DATA, FRAME_SIZE))
    { red: red, ir: ir }
  end

  alias read read_fifo

  def temperature
    write_register(DIE_TEMP_CONFIG, 0x01)
    elapsed = 0
    while (read_register(DIE_TEMP_CONFIG) & 0x01) != 0
      raise ResetTimeoutError, "MAX30102 temperature conversion timed out" if elapsed >= TEMPERATURE_TIMEOUT_MS

      sleep_ms 1
      elapsed += 1
    end

    integer = read_register(DIE_TEMP_INTEGER)
    integer -= 256 if integer >= 128
    integer + read_register(DIE_TEMP_FRACTION) / 16.0
  end

  def shutdown
    write_register(MODE_CONFIG, read_register(MODE_CONFIG) | SHUTDOWN_BIT)
    self
  end

  def wake
    write_register(MODE_CONFIG, read_register(MODE_CONFIG) & ~SHUTDOWN_BIT)
    self
  end

  private

  def configure(fifo_average:, sample_rate:, pulse_width:, adc_range:,
                red_led_amplitude:, ir_led_amplitude:)
    @fifo_average = fifo_average
    @sample_rate = sample_rate
    @pulse_width = pulse_width
    @adc_range = adc_range

    clear_fifo
    fifo = (FIFO_AVERAGES[fifo_average] << 5) | 0x0F
    spo2 = (ADC_RANGES[adc_range] << 5) |
           (SAMPLE_RATES[sample_rate] << 2) |
           PULSE_WIDTHS[pulse_width]
    write_register(FIFO_CONFIG, fifo)
    write_register(MODE_CONFIG, MODE_SPO2)
    write_register(SPO2_CONFIG, spo2)
    write_register(LED1_PA, red_led_amplitude)
    write_register(LED2_PA, ir_led_amplitude)
  end

  def read_register(register)
    read_registers(register, 1).getbyte(0)
  end

  def read_registers(register, length)
    @i2c.read(@address, length, register)
  end

  def write_register(register, value)
    @i2c.write(@address, register, value)
  end

  def validate(value, choices, name)
    raise ArgumentError, "invalid #{name}: #{value.inspect}" unless choices[value]
  end

  def validate_amplitude(value, name)
    return if value.is_a?(Integer) && value >= 0 && value <= 0xFF

    raise ArgumentError, "#{name} must be an Integer from 0 to 255"
  end

  private :_decode_frame
end
