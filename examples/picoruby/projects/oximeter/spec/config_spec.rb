# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Oximeter::Config do
  it "defines the documented I2C and SPI wiring" do
    expect([described_class::I2C_SDA_PIN, described_class::I2C_SCL_PIN]).to eq([16, 17])
    expect([described_class::SPI_SCK_PIN, described_class::SPI_COPI_PIN]).to eq([2, 3])
  end

  it "defines bounded measurement windows and beat intervals" do
    expect(described_class::SMOOTH_SAMPLES).to eq(8)
    expect(described_class::BASELINE_SAMPLES).to eq(50)
    expect(described_class::SIGNAL_SAMPLES).to eq(100)
    expect(described_class::RESULT_SAMPLES).to eq(8)
    expect(described_class::MIN_BEAT_INTERVAL_MS).to be < described_class::MAX_BEAT_INTERVAL_MS
  end

  it "keeps the status LEDs dim and runs for the documented duration" do
    expect(described_class::LED_COUNT).to eq(8)
    expect(described_class::LED_BRIGHTNESS).to be_between(1, 32)
    expect(described_class::RUN_DURATION_MS).to eq(60_000)
  end
end
