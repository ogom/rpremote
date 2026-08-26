# frozen_string_literal: true

require "i2c"

class BMI270
  class DeviceNotFoundError < StandardError; end
  class InitializationError < StandardError; end

  ADDRESS = 0x68
  ALTERNATE_ADDRESS = 0x69
  CHIP_ID = 0x00
  CHIP_ID_VALUE = 0x24
  CONFIG_SIZE = 8192
  INTERNAL_STATUS = 0x21
  ACC_DATA = 0x0C
  TEMPERATURE = 0x22
  ACC_CONF = 0x40
  ACC_RANGE = 0x41
  GYR_CONF = 0x42
  GYR_RANGE = 0x43
  INIT_CTRL = 0x59
  INIT_ADDR_0 = 0x5B
  INIT_ADDR_1 = 0x5C
  INIT_DATA = 0x5E
  PWR_CONF = 0x7C
  PWR_CTRL = 0x7D
  CMD = 0x7E
  SOFT_RESET_SETTLE_MS = 10
  CONFIG_CHUNK_SIZE = 128
  FEATURE_PAGE = 0x2F
  FEATURE_DATA = 0x30
  FEATURE_SIZE = 16
  GYRO_CROSS_SENSE_INDEX = 0x0C
  GYRO_CROSS_SENSE_MASK = 0x7F
  GYRO_CROSS_SENSE_SIGN = 0x40

  ACCEL_RANGES = { g2: [0, 2], g4: [1, 4], g8: [2, 8], g16: [3, 16] }
  GYRO_RANGES = { dps2000: [0, 2000], dps1000: [1, 1000], dps500: [2, 500], dps250: [3, 250], dps125: [4, 125] }
  ODR_CODES = { hz25: 0x06, hz50: 0x07, hz100: 0x08, hz200: 0x09, hz400: 0x0A, hz800: 0x0B, hz1600: 0x0C }

  attr_reader :address, :accel_range, :gyro_range, :odr

  def initialize(i2c:, configuration: nil, address: ADDRESS, accel_range: :g2, gyro_range: :dps2000, odr: :hz100)
    unless address == ADDRESS || address == ALTERNATE_ADDRESS
      raise ArgumentError, "address must be 0x68 or 0x69"
    end
    unless configuration.nil? || (configuration.is_a?(String) && configuration.bytesize == CONFIG_SIZE)
      raise ArgumentError, "configuration must be an #{CONFIG_SIZE}-byte String"
    end
    validate(accel_range, ACCEL_RANGES, "accel_range")
    validate(gyro_range, GYRO_RANGES, "gyro_range")
    validate(odr, ODR_CODES, "odr")
    @i2c = i2c
    @address = address
    raise DeviceNotFoundError, "BMI270 not found at 0x#{address.to_s(16)}" unless connected?
    soft_reset
    upload_configuration(configuration)
    read_gyro_cross_sensitivity
    configure(accel_range, gyro_range, odr)
  end

  def connected? = who_am_i == CHIP_ID_VALUE
  def who_am_i = read_register(CHIP_ID)

  def read_raw
    values = _decode_frame(read_registers(ACC_DATA, 12))
    gx = values[3] - (@gyro_cross_sensitivity_zx * values[5] / 512)
    gx = 32_767 if gx > 32_767
    gx = -32_768 if gx < -32_768
    {
      acceleration: [values[0], values[1], values[2]],
      gyroscope: [gx, values[4], values[5]]
    }
  end

  def read
    raw = read_raw
    as = ACCEL_RANGES[@accel_range][1] / 32_768.0
    gs = GYRO_RANGES[@gyro_range][1] / 32_768.0
    acceleration = raw[:acceleration]
    gyroscope = raw[:gyroscope]
    {
      acceleration: [acceleration[0] * as, acceleration[1] * as, acceleration[2] * as],
      gyroscope: [gyroscope[0] * gs, gyroscope[1] * gs, gyroscope[2] * gs],
      temperature: temperature
    }
  end

  def motion6 = motion6_from(read)
  def motion6_raw = motion6_from(read_raw)
  def acceleration = read[:acceleration]
  def gyroscope = read[:gyroscope]

  def temperature
    bytes = read_registers(TEMPERATURE, 2)
    raw = bytes.getbyte(0) | (bytes.getbyte(1) << 8)
    raw -= 65_536 if raw >= 32_768
    23.0 + raw / 512.0
  end

  private

  def soft_reset
    write_register(CMD, 0xB6)
    # Bosch specifies a 2 ms minimum. Give the device the same 10 ms settle
    # time used by the hardware I2C probe before its configuration upload.
    sleep_ms SOFT_RESET_SETTLE_MS
  end

  def upload_configuration(data)
    write_register(PWR_CONF, 0x00)
    sleep_ms 1
    write_register(INIT_CTRL, 0x00)
    offset = 0
    while offset < CONFIG_SIZE
      word = offset / 2
      write_register(INIT_ADDR_0, word & 0x0F)
      write_register(INIT_ADDR_1, (word >> 4) & 0xFF)
      length = CONFIG_CHUNK_SIZE
      remaining = CONFIG_SIZE - offset
      length = remaining if remaining < length
      chunk = data ? data.byteslice(offset, length) : _default_configuration_chunk(offset, length)
      write_registers(INIT_DATA, chunk)
      offset += chunk.bytesize
    end
    write_register(INIT_CTRL, 0x01)
    write_register(PWR_CONF, 0x01)
    sleep_ms 140
    raise InitializationError, "BMI270 configuration initialization failed" unless (read_register(INTERNAL_STATUS) & 0x0F) == 1
  end

  def read_gyro_cross_sensitivity
    write_register(FEATURE_PAGE, 0)
    sleep_ms 1
    value = read_registers(FEATURE_DATA, FEATURE_SIZE).getbyte(GYRO_CROSS_SENSE_INDEX)
    value &= GYRO_CROSS_SENSE_MASK
    value -= 128 if (value & GYRO_CROSS_SENSE_SIGN) != 0
    @gyro_cross_sensitivity_zx = value
  end

  def configure(accel_range, gyro_range, odr)
    @accel_range = accel_range; @gyro_range = gyro_range; @odr = odr
    write_register(ACC_CONF, 0xA0 | ODR_CODES[odr])
    sleep_ms 1
    write_register(ACC_RANGE, ACCEL_RANGES[accel_range][0])
    sleep_ms 1
    write_register(GYR_CONF, 0xA0 | ODR_CODES[odr])
    sleep_ms 1
    write_register(GYR_RANGE, GYRO_RANGES[gyro_range][0])
    sleep_ms 1
    write_register(PWR_CTRL, 0x0E)
    sleep_ms 50
  end

  def read_register(register) = read_registers(register, 1).getbyte(0)

  def read_registers(register, length) = @i2c.read(@address, length, register)

  def write_register(register, value) = write_registers(register, [value])

  def write_registers(register, data)
    @i2c.write(@address, register, data)
  end

  def motion6_from(sample)
    acceleration = sample[:acceleration]
    gyroscope = sample[:gyroscope]
    [
      acceleration[0], acceleration[1], acceleration[2],
      gyroscope[0], gyroscope[1], gyroscope[2]
    ]
  end

  def validate(value, choices, name)
    raise ArgumentError, "invalid #{name}: #{value.inspect}" unless choices[value]
  end
  private :_decode_frame, :_default_configuration_chunk
end
