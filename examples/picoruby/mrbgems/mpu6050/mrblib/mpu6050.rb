# frozen_string_literal: true

require "i2c"

class MPU6050
  class DeviceNotFoundError < StandardError; end

  ADDRESS = 0x68
  ALTERNATE_ADDRESS = 0x69

  GYRO_CONFIG = 0x1B
  ACCEL_CONFIG = 0x1C
  ACCEL_XOUT_H = 0x3B
  PWR_MGMT_1 = 0x6B
  WHO_AM_I = 0x75

  FRAME_SIZE = 14
  RANGE_MASK = 0x18
  RANGE_MASK_INVERSE = 0xE7
  CLOCK_PLL_X_GYRO = 0x01
  DEVICE_ID = 0x68

  ACCEL_RANGE_CODES = {
    g2: 0,
    g4: 1,
    g8: 2,
    g16: 3
  }
  ACCEL_FULL_SCALES = {
    g2: 2,
    g4: 4,
    g8: 8,
    g16: 16
  }
  GYRO_RANGE_CODES = {
    dps250: 0,
    dps500: 1,
    dps1000: 2,
    dps2000: 3
  }
  GYRO_FULL_SCALES = {
    dps250: 250,
    dps500: 500,
    dps1000: 1000,
    dps2000: 2000
  }

  attr_reader :address, :accel_range, :gyro_range

  def initialize(i2c:, address: ADDRESS, accel_range: :g2, gyro_range: :dps250)
    unless address == ADDRESS || address == ALTERNATE_ADDRESS
      raise ArgumentError, "address must be 0x68 or 0x69"
    end
    validate_range(accel_range, ACCEL_RANGE_CODES, "accel_range")
    validate_range(gyro_range, GYRO_RANGE_CODES, "gyro_range")

    @i2c = i2c
    @address = address

    unless connected?
      raise DeviceNotFoundError, "MPU6050 not found at 0x#{address.to_s(16)}"
    end

    write_register(PWR_MGMT_1, CLOCK_PLL_X_GYRO)
    self.accel_range = accel_range
    self.gyro_range = gyro_range
  end

  def connected?
    who_am_i == DEVICE_ID
  end

  def who_am_i
    read_register(WHO_AM_I)
  end

  def accel_range=(range)
    code = validate_range(range, ACCEL_RANGE_CODES, "accel_range")
    update_range(ACCEL_CONFIG, code)
    @accel_range = range
  end

  def gyro_range=(range)
    code = validate_range(range, GYRO_RANGE_CODES, "gyro_range")
    update_range(GYRO_CONFIG, code)
    @gyro_range = range
  end

  # Reads all sensor output registers in one I2C burst. The returned raw sample
  # keeps acceleration, temperature, and gyroscope data from the same frame.
  def read_raw
    values = _decode_frame(@i2c.read(@address, FRAME_SIZE, ACCEL_XOUT_H))
    {
      acceleration: [values[0], values[1], values[2]],
      temperature: values[3],
      gyroscope: [values[4], values[5], values[6]]
    }
  end

  # Returns acceleration in g, gyroscope rotation in degrees per second, and
  # temperature in degrees Celsius.
  def read
    raw = read_raw
    accel_scale = ACCEL_FULL_SCALES[@accel_range] / 32_768.0
    gyro_scale = GYRO_FULL_SCALES[@gyro_range] / 32_768.0
    acceleration = raw[:acceleration]
    gyroscope = raw[:gyroscope]

    {
      acceleration: [
        acceleration[0] * accel_scale,
        acceleration[1] * accel_scale,
        acceleration[2] * accel_scale
      ],
      temperature: raw[:temperature] / 340.0 + 36.53,
      gyroscope: [
        gyroscope[0] * gyro_scale,
        gyroscope[1] * gyro_scale,
        gyroscope[2] * gyro_scale
      ]
    }
  end

  def motion6_raw
    sample = read_raw
    acceleration = sample[:acceleration]
    gyroscope = sample[:gyroscope]
    [
      acceleration[0], acceleration[1], acceleration[2],
      gyroscope[0], gyroscope[1], gyroscope[2]
    ]
  end

  def motion6
    sample = read
    acceleration = sample[:acceleration]
    gyroscope = sample[:gyroscope]
    [
      acceleration[0], acceleration[1], acceleration[2],
      gyroscope[0], gyroscope[1], gyroscope[2]
    ]
  end

  def acceleration
    read[:acceleration]
  end

  def gyroscope
    read[:gyroscope]
  end

  def temperature
    read[:temperature]
  end

  private

  def read_register(register)
    @i2c.read(@address, 1, register).getbyte(0)
  end

  def write_register(register, value)
    @i2c.write(@address, register, value)
  end

  def update_range(register, code)
    current = read_register(register)
    value = (current & RANGE_MASK_INVERSE) | ((code << 3) & RANGE_MASK)
    write_register(register, value)
  end

  def validate_range(range, ranges, name)
    code = ranges[range]
    return code unless code.nil?

    raise ArgumentError, "invalid #{name}: #{range.inspect}"
  end

  private :_decode_frame
end
