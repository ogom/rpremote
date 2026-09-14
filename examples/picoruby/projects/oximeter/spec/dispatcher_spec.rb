# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Oximeter::Dispatcher do
  it "delivers the same payload synchronously in subscription order" do
    calls = []
    payload = { bpm: 72.0 }
    first = ->(event, value) { calls << [:first, event, value] }
    second = ->(event, value) { calls << [:second, event, value] }

    result = described_class.new.subscribe(first).subscribe(second).publish(:beat, payload)

    expect(result).to be_a(described_class)
    expect(calls).to eq([[:first, :beat, payload], [:second, :beat, payload]])
    expect(calls.map { |call| call[2].object_id }.uniq).to contain_exactly(payload.object_id)
  end

  it "propagates a subscriber failure without calling later subscribers" do
    later = spy(:later)
    dispatcher = described_class.new
                                .subscribe(->(*) { raise "subscriber failed" })
                                .subscribe(later)

    expect { dispatcher.publish(:beat, {}) }.to raise_error(RuntimeError, "subscriber failed")
    expect(later).not_to have_received(:call)
  end
end
