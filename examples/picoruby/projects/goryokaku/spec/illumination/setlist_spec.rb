# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Illumination::Setlist do
  it "registers 21 unique pattern keys with executable classes" do
    keys = described_class::PATTERNS.map { |entry| entry[described_class::KEY] }

    expect(keys.length).to eq(21)
    expect(keys.uniq).to eq(keys)
    expect(keys).to all(satisfy { |key| described_class.pattern_class(key).is_a?(Class) })
  end

  it "uses only registered patterns in the four public setlists" do
    expected_counts = { tests: 1, highlights: 7, story: 15, showcase: 21 }

    expected_counts.each do |name, count|
      entries = described_class.resolve(name)
      expect(entries.length).to eq(count)
      expect(entries.map { |entry| described_class.key(entry) }).to all(satisfy { |key| described_class.valid_key?(key) })
    end
  end

  it "preserves the public frame waits and exceptional loop counts" do
    expect(described_class.resolve(:tests).map { |entry| described_class.wait_ms(entry) }.uniq).to eq([1])
    %i[highlights story showcase].each do |name|
      expect(described_class.resolve(name).map { |entry| described_class.wait_ms(entry) }.uniq).to eq([35])
    end
    expect(described_class.resolve(:showcase).find { |entry| described_class.key(entry) == :outer_comet }[2]).to eq(2)
    expect(described_class.resolve(:story).find { |entry| described_class.key(entry) == :fireworks }[2]).to eq(3)
  end

  it "rejects unknown setlists and returns nil for unknown pattern classes" do
    expect { described_class.resolve(:unknown) }.to raise_error(ArgumentError, /setlist_name/)
    expect(described_class.pattern_class(:unknown)).to be_nil
  end
end
