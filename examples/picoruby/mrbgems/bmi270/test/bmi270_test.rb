class BMI270FakeI2C
  attr_reader :reads, :writes
  def initialize(frame: "\x00" * 12, chip_id: 0x24, status: 1, cross_sensitivity: 0)
    @frame = frame; @chip_id = chip_id; @status = status; @cross_sensitivity = cross_sensitivity
    @reads = []; @writes = []
  end

  def read(address, length, register)
    @reads << [address, length, register]
    data = if register == BMI270::ACC_DATA
             @frame
           elsif register == BMI270::TEMPERATURE
             "\x00\x00"
           elsif register == BMI270::FEATURE_DATA
             feature = "\x00" * BMI270::FEATURE_SIZE
             feature.setbyte(BMI270::GYRO_CROSS_SENSE_INDEX, @cross_sensitivity & 0x7F)
             feature
           else
             (register == BMI270::CHIP_ID ? @chip_id : @status).chr
           end
    data.byteslice(0, length)
  end

  def write(*data)
    @writes << data
    data.length - 1
  end
end

class BMI270Test < Picotest::Test
  CONFIGURATION = "\x00" * 8192
  FRAME = "\x00\x40\x00\xC0\xFF\x7F\x00\x80\xFF\xFF\x01\x00"
  def setup; require "bmi270"; end

  def test_initializes_and_reads_a_coherent_frame
    i2c = BMI270FakeI2C.new(frame: FRAME)
    sensor = BMI270.new(i2c: i2c, configuration: CONFIGURATION)
    assert_equal [16_384, -16_384, 32_767, -32_768, -1, 1], sensor.motion6_raw
    assert_equal [0x68, 12, 0x0C], i2c.reads[-1]
    assert i2c.writes.any? { |write| write[1] == BMI270::INIT_DATA }
  end

  def test_scales_default_ranges
    sample = BMI270.new(i2c: BMI270FakeI2C.new(frame: FRAME), configuration: CONFIGURATION).read
    assert_in_delta 1.0, sample[:acceleration][0]
    assert_in_delta(-2000.0, sample[:gyroscope][0])
    assert_in_delta 23.0, sample[:temperature]
  end

  def test_rejects_bad_configuration_and_chip_id
    assert_raise(ArgumentError) { BMI270.new(i2c: BMI270FakeI2C.new, configuration: "bad") }
    assert_raise(ArgumentError) { BMI270.new(i2c: BMI270FakeI2C.new, address: 0x67) }
    assert_raise(BMI270::DeviceNotFoundError) do
      BMI270.new(i2c: BMI270FakeI2C.new(chip_id: 0), configuration: CONFIGURATION)
    end
  end

  def test_uses_bundled_configuration_by_default
    i2c = BMI270FakeI2C.new
    BMI270.new(i2c: i2c)
    chunks = 0
    i2c.writes.each { |write| chunks += 1 if write[1] == BMI270::INIT_DATA }
    assert_equal 64, chunks
  end
  def test_applies_bosch_gyro_cross_axis_correction
    frame = "\x00" * 6 + "\x00\x04\x00\x00\x00\x08"
    sensor = BMI270.new(i2c: BMI270FakeI2C.new(frame: frame, cross_sensitivity: 32),
                        configuration: CONFIGURATION)
    assert_equal 896, sensor.motion6_raw[3]
  end

  def test_uses_alternate_address
    i2c = BMI270FakeI2C.new
    BMI270.new(i2c: i2c, address: 0x69, configuration: CONFIGURATION)
    assert_equal 0x69, i2c.reads[0][0]
  end
end
