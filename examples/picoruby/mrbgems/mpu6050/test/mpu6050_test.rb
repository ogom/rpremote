class MPU6050FakeI2C
  attr_reader :reads, :writes

  def initialize(frame: nil, device_id: 0x68, accel_config: 0, gyro_config: 0)
    @frame = frame || (0.chr * 14)
    @registers = {
      MPU6050::WHO_AM_I => device_id,
      MPU6050::ACCEL_CONFIG => accel_config,
      MPU6050::GYRO_CONFIG => gyro_config
    }
    @reads = []
    @writes = []
  end

  def read(address, length, register)
    @reads << [address, length, register]
    return @frame if length == MPU6050::FRAME_SIZE

    (@registers[register] || 0).chr
  end

  def write(address, register, value)
    @writes << [address, register, value]
    @registers[register] = value
    2
  end
end

class MPU6050Test < Picotest::Test
  FRAME = "\x40\x00\xC0\x00\x7F\xFF\x00\x00\x80\x00\xFF\xFF\x00\x01"

  def setup
    require "mpu6050"
  end

  def test_initializes_and_reads_one_coherent_frame
    i2c = MPU6050FakeI2C.new(frame: FRAME)
    sensor = MPU6050.new(i2c: i2c)

    assert_equal [0x68, 0x6B, 0x01], i2c.writes[0]
    assert_equal [16_384, -16_384, 32_767, -32_768, -1, 1], sensor.motion6_raw
    assert_equal [0x68, 14, 0x3B], i2c.reads[-1]
  end

  def test_scales_acceleration_gyroscope_and_temperature
    sensor = MPU6050.new(i2c: MPU6050FakeI2C.new(frame: FRAME))
    sample = sensor.read

    assert_in_delta 1.0, sample[:acceleration][0]
    assert_in_delta(-1.0, sample[:acceleration][1])
    assert_in_delta(-250.0, sample[:gyroscope][0])
    assert_in_delta 36.53, sample[:temperature]
  end

  def test_supports_all_ranges_without_clobbering_other_bits
    i2c = MPU6050FakeI2C.new(accel_config: 0xA5, gyro_config: 0xA5)
    sensor = MPU6050.new(i2c: i2c)

    sensor.accel_range = :g16
    sensor.gyro_range = :dps2000

    assert_equal :g16, sensor.accel_range
    assert_equal :dps2000, sensor.gyro_range
    assert_equal [0x68, 0x1C, 0xBD], i2c.writes[-2]
    assert_equal [0x68, 0x1B, 0xBD], i2c.writes[-1]
  end

  def test_scales_non_default_ranges
    sensor = MPU6050.new(
      i2c: MPU6050FakeI2C.new(frame: FRAME),
      accel_range: :g16,
      gyro_range: :dps2000
    )
    sample = sensor.read

    assert_in_delta 8.0, sample[:acceleration][0]
    assert_in_delta(-8.0, sample[:acceleration][1])
    assert_in_delta(-2000.0, sample[:gyroscope][0])
  end

  def test_routes_reads_and_writes_to_alternate_address
    i2c = MPU6050FakeI2C.new(frame: FRAME)
    sensor = MPU6050.new(i2c: i2c, address: 0x69)

    assert_equal [0x69, 0x6B, 0x01], i2c.writes[0]
    sensor.motion6_raw
    assert_equal [0x69, 14, 0x3B], i2c.reads[-1]
  end

  def test_rejects_unknown_device_address_and_range
    assert_raise(MPU6050::DeviceNotFoundError) do
      MPU6050.new(i2c: MPU6050FakeI2C.new(device_id: 0x00))
    end
    assert_raise(ArgumentError) do
      MPU6050.new(i2c: MPU6050FakeI2C.new, address: 0x67)
    end
    assert_raise(ArgumentError) do
      MPU6050.new(i2c: MPU6050FakeI2C.new, accel_range: :g32)
    end
  end

  def test_rejects_a_short_frame
    sensor = MPU6050.new(i2c: MPU6050FakeI2C.new(frame: 0.chr * 13))
    assert_raise(ArgumentError) { sensor.read_raw }
  end
end
