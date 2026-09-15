# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Oximeter main lifecycle" do
  let(:main_path) { File.join(OXIMETER_ROOT, "main.rb") }
  let(:clock) { instance_double(Oximeter::BoardClock, wait_ms: nil) }
  let(:logger) { instance_spy(Oximeter::ConsoleLogger) }
  let(:dispatcher) { instance_double(Oximeter::Dispatcher, subscribe: nil) }
  let(:renderer) { instance_double(Oximeter::StatusLed::Renderer, clear: nil, error: nil) }
  let(:presenter) { instance_double(Oximeter::StatusLed::Presenter) }
  let(:sensor_factory) { instance_double(Oximeter::SensorFactory) }

  before do
    allow(Oximeter::BoardClock).to receive(:new).and_return(clock)
    allow(Oximeter::ConsoleLogger).to receive(:new).and_return(logger)
    allow(Oximeter::Dispatcher).to receive(:new).and_return(dispatcher)
    allow(Oximeter::SensorFactory).to receive(:new).and_return(sensor_factory)
    allow(Oximeter::StatusLed::Factory).to receive(:new).and_return(double(:renderer_factory, call: renderer))
    allow(Oximeter::StatusLed::Presenter).to receive(:new).with(renderer).and_return(presenter)
  end

  it "shows the sensor error, waits briefly, clears the LEDs, and re-raises" do
    allow(sensor_factory).to receive(:call).and_raise(IOError, "I2C write failed")

    expect { load main_path }.to raise_error(IOError, "I2C write failed")
    expect(renderer).to have_received(:error)
    expect(renderer).to have_received(:clear).twice
    expect(clock).to have_received(:wait_ms).with(1_000)
    expect(logger).to have_received(:puts).with("OXIMETER_ERROR,IOError,I2C write failed")
  end

  it "warns about shutdown failure, clears the LEDs, and still reports completion" do
    sensor = double(:sensor)
    processor = double(:processor, latest_bpm: 72.0, latest_spo2: 98.0)
    allow(clock).to receive(:millis).and_return(0, 60_000)
    allow(sensor_factory).to receive(:call).and_return(sensor)
    allow(sensor).to receive(:shutdown).and_raise(IOError, "I2C write failed")
    allow(Oximeter::Measurement::Processor).to receive(:new).and_return(processor)

    expect { load main_path }.not_to raise_error
    expect(renderer).to have_received(:clear).twice
    expect(logger).to have_received(:puts).with("OXIMETER_WARN,shutdown,IOError,I2C write failed")
    expect(logger).to have_received(:puts).with("OXIMETER_DONE,bpm=72.0,spo2=98.0")
  end
end
