# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Application::Config do
  subject(:validator) { Daisenkofun::Application::Validator.new }

  it "resolves the public defaults for measurement hardware and audio" do
    config = described_class.new

    expect(config.mode).to eq(:combined)
    expect(config.duration_ms).to eq(60_000)
    expect([config.ws2812_pin, config.i2c_sda_pin, config.i2c_scl_pin]).to eq([14, 16, 17])
    expect([config.spi_sck_pin, config.spi_copi_pin, config.buzzer_pin]).to eq([2, 3, 18])
    expect([config.buzzer_volume, config.musical_style]).to eq([3, :heartbeat_signature])
  end

  it "selects highlights only when illumination has no explicit pattern" do
    expect(described_class.new(mode: :illumination).setlist_name).to eq(:highlights)
    expect(described_class.new(mode: :illumination, pattern_key: :moonlight).setlist_name).to be_nil
  end

  it "accepts every documented mode, musical style, and volume boundary" do
    Daisenkofun::Application::Validator::MODES.each do |mode|
      config = described_class.new(mode: mode, duration_ms: mode == :illumination ? nil : 1)
      expect { validator.validate(config) }.not_to raise_error
    end

    Daisenkofun::Application::Validator::MUSICAL_STYLES.each do |style|
      expect { validator.validate(described_class.new(musical_style: style)) }.not_to raise_error
    end
    [0, 100, 1.5].each do |volume|
      expect { validator.validate(described_class.new(buzzer_volume: volume)) }.not_to raise_error
    end
  end

  it "rejects conflicting illumination selectors and measurement-only duration" do
    expect do
      validator.validate(described_class.new(mode: :illumination, setlist_name: :tests, pattern_key: :moonlight))
    end.to raise_error(ArgumentError, /mutually exclusive/)
    expect do
      validator.validate(described_class.new(mode: :illumination, duration_ms: 1))
    end.to raise_error(ArgumentError, /duration_ms/)
  end

  it "rejects selectors in measurement modes and invalid pins or volume" do
    expect do
      validator.validate(described_class.new(mode: :combined, pattern_key: :moonlight))
    end.to raise_error(ArgumentError, /only valid/)
    expect { validator.validate(described_class.new(ws2812_pin: -1)) }.to raise_error(ArgumentError, /ws2812_pin/)
    expect { validator.validate(described_class.new(buzzer_volume: 101)) }.to raise_error(ArgumentError, /0 and 100/)
  end
end
