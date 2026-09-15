# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Application::Config do
  def validate(config)
    Goryokaku::Application::Validator.new(config).validate
  end

  it "resolves the public hardware, interaction, and tambourine defaults" do
    config = described_class.new

    expect([config.mode, config.setlist_name, config.repeat]).to eq([:illumination, :highlights, false])
    expect([config.led_pin, config.led_count, config.touch_pin, config.buzzer_pin]).to eq([14, 380, 21, 18])
    expect([config.i2c_sda_pin, config.i2c_scl_pin, config.i2c_frequency]).to eq([16, 17, 400_000])
    expect([config.shake_threshold, config.strike_threshold, config.strike_release_threshold]).to eq([0.2, 0.45, 0.15])
  end

  it "selects highlights for illumination and combined but not musical mode" do
    expect(described_class.new(mode: :illumination).setlist_name).to eq(:highlights)
    expect(described_class.new(mode: :combined).setlist_name).to eq(:highlights)
    expect(described_class.new(mode: :musical).setlist_name).to be_nil
    expect(described_class.new(mode: :illumination, pattern_key: :fireworks).setlist_name).to be_nil
  end

  it "converts legacy heartbeat ticks to milliseconds" do
    config = described_class.new(heartbeat_interval: 250, poll_interval_ms: 20)

    expect(config.heartbeat_interval_ms).to eq(5_000)
  end

  it "accepts all modes, setlists, threshold number types, and axis signs" do
    %i[illumination musical combined].each do |mode|
      expect { validate(described_class.new(mode: mode)) }.not_to raise_error
    end
    %i[tests highlights story showcase].each do |setlist|
      expect { validate(described_class.new(setlist_name: setlist)) }.not_to raise_error
    end
    expect do
      validate(described_class.new(shake_threshold: 1, strike_threshold: 2.0, strike_release_threshold: 1,
                                   musical_axis_signs: [-1, 1, -1]))
    end.not_to raise_error
  end

  it "rejects conflicting selectors and selectors unsupported by the mode" do
    expect do
      validate(described_class.new(setlist_name: :tests, pattern_key: :warm_white))
    end.to raise_error(ArgumentError, /mutually exclusive/)
    expect do
      validate(described_class.new(mode: :combined, pattern_key: :warm_white))
    end.to raise_error(ArgumentError, /only valid/)
    expect do
      validate(described_class.new(mode: :musical, setlist_name: :tests))
    end.to raise_error(ArgumentError, /not valid/)
  end

  it "rejects an undersized strip and invalid tambourine thresholds" do
    expect { validate(described_class.new(led_count: 379)) }.to raise_error(ArgumentError, /physical LED layout/)
    expect { validate(described_class.new(musical_axis_signs: [1, 0, 1])) }.to raise_error(ArgumentError, /axis_signs/)
    expect do
      validate(described_class.new(strike_threshold: 0.4, strike_release_threshold: 0.5))
    end.to raise_error(ArgumentError, /lower than/)
  end
end
