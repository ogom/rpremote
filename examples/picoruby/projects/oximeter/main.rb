# frozen_string_literal: true

require "i2c"
require "machine"
require "max30102"
require "spi"
require "ws2812_spi"
require "/lib/oximeter/config"
require "/lib/oximeter/monitor"
require "/lib/oximeter/status_leds"

spi = SPI.new(
  unit: Oximeter::Config::SPI_UNIT,
  frequency: WS2812SPI::FREQUENCY,
  sck_pin: Oximeter::Config::SPI_SCK_PIN,
  copi_pin: Oximeter::Config::SPI_COPI_PIN,
  mode: WS2812SPI::MODE
)
pixels = WS2812SPI.new(spi: spi, count: Oximeter::Config::LED_COUNT)
status_leds = Oximeter::StatusLeds.new(pixels)
status_leds.clear

begin
  i2c = I2C.new(
    unit: Oximeter::Config::I2C_UNIT,
    sda_pin: Oximeter::Config::I2C_SDA_PIN,
    scl_pin: Oximeter::Config::I2C_SCL_PIN,
    frequency: Oximeter::Config::I2C_FREQUENCY
  )
  sensor = MAX30102.new(i2c: i2c)
rescue => error
  status_leds.error
  puts "OXIMETER_ERROR,#{error.class},#{error.message}"
  sleep_ms 1_000
  status_leds.clear
  raise
end

monitor = Oximeter::Monitor.new(status_leds: status_leds)
started_at = Machine.board_millis
puts "OXIMETER_START,address=0x57,duration_ms=#{Oximeter::Config::RUN_DURATION_MS}"
puts "Place a fingertip steadily over the MAX30102."

begin
  while Machine.board_millis - started_at < Oximeter::Config::RUN_DURATION_MS
    available = sensor.available_samples
    while available > 0
      sample = sensor.read
      monitor.process(sample[:red], sample[:ir], Machine.board_millis)
      available -= 1
    end
    sleep_ms 2
  end
ensure
  begin
    sensor.shutdown
  rescue => error
    puts "OXIMETER_WARN,shutdown,#{error.class},#{error.message}"
  end
  status_leds.clear
end

puts sprintf(
  "OXIMETER_DONE,bpm=%.1f,spo2=%.1f",
  monitor.latest_bpm, monitor.latest_spo2
)
