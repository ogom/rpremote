# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Musical::PerformanceVerification do
  it "requires ten prompt pulse notes, two baselines, and ten pulse-shaped notes" do
    output = double(
      main_note_count: 10, max_main_delay_ms: 25, baseline_count: 2, pulse_timbre_count: 10,
      min_duty_percent: 2.0, max_duty_percent: 6.0
    )

    expect(described_class.pulse(output)).to include(
      status: :ok, main_notes: 10, max_main_delay_ms: 25, baselines: 2, pulse_notes: 10
    )
    allow(output).to receive(:max_main_delay_ms).and_return(26)
    expect(described_class.pulse(output)[:status]).to eq(:incomplete)
  end

  it "requires fifteen canon cues with no more than 25 ms maximum delay" do
    expect(described_class.canon(double(cue_count: 15, max_delay_ms: 25))[:status]).to eq(:ok)
    expect(described_class.canon(double(cue_count: 14, max_delay_ms: 25))[:status]).to eq(:incomplete)
    expect(described_class.canon(double(cue_count: 15, max_delay_ms: 26))[:status]).to eq(:incomplete)
  end
end
