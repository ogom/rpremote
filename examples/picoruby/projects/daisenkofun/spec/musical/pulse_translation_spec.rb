# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Musical::Translators::Pulse do
  it "maps an 800 ms beat to the nearest pentatonic PWM frequency" do
    expect(described_class.new.notes(800, 1_000)).to eq([330, 330])
  end

  it "rejects physiologically unsupported beat intervals" do
    translator = described_class.new

    expect(translator.notes(350, 1_000)).to be_nil
    expect(translator.notes(1_500, 1_000)).to be_nil
  end

  it "establishes its SpO2 baseline from eight samples and expires stale direction" do
    translator = described_class.new
    [96, 97, 98, 99, 97, 98, 96, 99].each_with_index do |spo2, index|
      translator.measurement(spo2: spo2, timestamp_ms: index * 100)
    end
    expect(translator.baseline).to eq(97.5)

    translator.measurement(spo2: 100, timestamp_ms: 800)
    translator.notes(800, 800)
    expect(translator.direction).to eq(1)

    translator.notes(800, 5_801)
    expect(translator.direction).to eq(0)
  end
end
