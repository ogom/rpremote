# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Illumination::Setlist do
  it "registers every pattern key once with an executable pattern class" do
    keys = described_class::PATTERNS.map { |entry| entry[described_class::KEY] }
    classes = described_class::PATTERNS.map { |entry| entry[described_class::PATTERN_CLASS] }

    expect(keys.length).to eq(32)
    expect(keys.uniq).to eq(keys)
    expect(classes.all? { |klass| klass < Daisenkofun::Illumination::Patterns::Base }).to be(true)
  end

  it "uses only registered patterns in every public setlist" do
    registered = described_class::PATTERNS.map { |entry| entry[described_class::KEY] }
    expected_lengths = { tests: 1, highlights: 7, story: 19, showcase: 30 }

    expected_lengths.each do |name, length|
      entries = described_class.resolve(name)
      expect(entries.length).to eq(length)
      expect(entries.map { |entry| described_class.key(entry) } - registered).to be_empty
      expect(entries.all? { |entry| described_class.wait_ms(entry).positive? && described_class.loops(entry).positive? }).to be(true)
    end
  end

  it "rejects unknown setlists and returns nil for unknown pattern classes" do
    expect { described_class.resolve(:unknown) }.to raise_error(ArgumentError, /setlist_name/)
    expect(described_class.pattern_class(:unknown)).to be_nil
  end
end
