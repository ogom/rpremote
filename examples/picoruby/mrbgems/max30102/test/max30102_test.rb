class MAX30102FakeI2C
  attr_reader :reads, :writes

  def initialize(frame: "\x00" * 6, part_id: 0x15, reset_stuck: false)
    @frame = frame
    @reset_stuck = reset_stuck
    @registers = {
      MAX30102::PART_ID => part_id,
      MAX30102::REVISION_ID => 0x03,
      MAX30102::MODE_CONFIG => 0,
      MAX30102::FIFO_WRITE_POINTER => 0,
      MAX30102::FIFO_READ_POINTER => 0,
      MAX30102::DIE_TEMP_CONFIG => 0,
      MAX30102::DIE_TEMP_INTEGER => 0xFE,
      MAX30102::DIE_TEMP_FRACTION => 0x08
    }
    @reads = []
    @writes = []
  end

  def read(address, length, register)
    @reads << [address, length, register]
    return @frame if register == MAX30102::FIFO_DATA

    ((@registers[register] || 0).chr * length)
  end

  def write(address, register, value)
    @writes << [address, register, value]
    if register == MAX30102::MODE_CONFIG && value == MAX30102::RESET_BIT
      @registers[register] = @reset_stuck ? value : 0
    elsif register == MAX30102::DIE_TEMP_CONFIG
      @registers[register] = 0
    else
      @registers[register] = value
    end
    2
  end

  def set_fifo_pointers(write_pointer, read_pointer)
    @registers[MAX30102::FIFO_WRITE_POINTER] = write_pointer
    @registers[MAX30102::FIFO_READ_POINTER] = read_pointer
  end
end

class MAX30102Test < Picotest::Test
  FRAME = "\x03\xFF\xFF\x02\x00\x01"

  def setup
    require "max30102"
  end

  def test_initializes_with_reference_configuration
    i2c = MAX30102FakeI2C.new
    sensor = MAX30102.new(i2c: i2c)

    assert_equal 0x15, sensor.part_id
    assert i2c.writes.include?([0x57, 0x08, 0x4F])
    assert i2c.writes.include?([0x57, 0x09, 0x03])
    assert i2c.writes.include?([0x57, 0x0A, 0x27])
    assert i2c.writes.include?([0x57, 0x0C, 0x24])
    assert i2c.writes.include?([0x57, 0x0D, 0x24])
  end

  def test_decodes_two_18_bit_fifo_channels
    sensor = MAX30102.new(i2c: MAX30102FakeI2C.new(frame: FRAME))
    assert_equal({ red: 262_143, ir: 131_073 }, sensor.read)
  end

  def test_reports_fifo_samples_across_pointer_wrap
    i2c = MAX30102FakeI2C.new
    sensor = MAX30102.new(i2c: i2c)
    i2c.set_fifo_pointers(2, 30)

    assert_equal 4, sensor.available_samples
    assert sensor.sample_available?
  end

  def test_reads_signed_fractional_temperature
    sensor = MAX30102.new(i2c: MAX30102FakeI2C.new)
    assert_in_delta(-1.5, sensor.temperature)
  end

  def test_rejects_unknown_device_and_invalid_configuration
    assert_raise(MAX30102::DeviceNotFoundError) do
      MAX30102.new(i2c: MAX30102FakeI2C.new(part_id: 0))
    end
    assert_raise(ArgumentError) do
      MAX30102.new(i2c: MAX30102FakeI2C.new, sample_rate: :hz25)
    end
    assert_raise(ArgumentError) do
      MAX30102.new(i2c: MAX30102FakeI2C.new, red_led_amplitude: 256)
    end
  end

  def test_rejects_a_short_fifo_frame
    sensor = MAX30102.new(i2c: MAX30102FakeI2C.new(frame: "\x00" * 5))
    assert_raise(ArgumentError) { sensor.read }
  end
end
