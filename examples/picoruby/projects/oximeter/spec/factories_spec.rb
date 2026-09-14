# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "Oximeter hardware factories" do
  it "constructs the MAX30102 with the documented I2C bus" do
    i2c = double(:i2c)
    sensor = double(:sensor)
    i2c_class = double(:i2c_class, new: i2c)
    sensor_class = double(:sensor_class, new: sensor)

    result = Oximeter::SensorFactory.new(i2c_class: i2c_class, sensor_class: sensor_class).call

    expect(result).to equal(sensor)
    expect(i2c_class).to have_received(:new).with(
      unit: :RP2040_I2C0, sda_pin: 16, scl_pin: 17, frequency: 400_000
    )
    expect(sensor_class).to have_received(:new).with(i2c: i2c)
  end

  it "constructs eight status LEDs on the documented SPI bus" do
    spi = double(:spi)
    pixels = double(:pixels)
    spi_class = Class.new
    pixels_class = Class.new
    pixels_class.const_set(:FREQUENCY, 2_400_000)
    pixels_class.const_set(:MODE, 0)
    allow(spi_class).to receive(:new).and_return(spi)
    allow(pixels_class).to receive(:new).and_return(pixels)
    stub_const("SPI", spi_class)
    stub_const("WS2812SPI", pixels_class)

    renderer = Oximeter::StatusLed::Factory.new.call

    expect(renderer).to be_a(Oximeter::StatusLed::Renderer)
    expect(spi_class).to have_received(:new).with(
      unit: :RP2040_SPI0, frequency: 2_400_000, sck_pin: 2, copi_pin: 3, mode: 0
    )
    expect(pixels_class).to have_received(:new).with(spi: spi, count: 8)
  end
end
