# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Oximeter estimation and measurement session" do
  it "waits for the configured signal window before estimating SpO2" do
    estimator = Oximeter::Measurement::SpO2Estimator.new(signal_samples: 4)
    3.times { |index| estimator.push(100 + index, 200 + index) }

    expect(estimator.count).to eq(3)
    expect(estimator.estimate).to be_nil
  end

  it "uses the ratio of AC to DC components and clamps the estimate" do
    estimator = Oximeter::Measurement::SpO2Estimator.new(signal_samples: 4)
    [[100, 100], [120, 110], [100, 100], [120, 110]].each { |red, ir| estimator.push(red, ir) }

    expect(estimator.estimate).to be_within(0.01).of(62.27)

    clamped = Oximeter::Measurement::SpO2Estimator.new(signal_samples: 2, intercept: 150, ratio_scale: 1)
    clamped.push(100, 100).push(110, 110)
    expect(clamped.estimate).to eq(100.0)
  end

  it "returns no estimate for a signal without usable DC or IR variation" do
    estimator = Oximeter::Measurement::SpO2Estimator.new(signal_samples: 2)
    estimator.push(100, 100).push(100, 100)

    expect(estimator.estimate).to be_nil
  end

  it "reports interim values after three beats and completion exactly once" do
    session = Oximeter::Measurement::Session.new(result_samples: 4)
    3.times { session.record_beat(1_000) }
    interim = session.record_spo2(98, bpm: 60)
    session.record_beat(1_000)
    complete = session.record_spo2(96, bpm: 60)
    repeated = session.record_spo2(94, bpm: 60)

    expect(interim).to include(complete: false, completed_now: false)
    expect(complete).to include(complete: true, completed_now: true, bpm: 60)
    expect(repeated).to include(complete: true, completed_now: false)
  end
end
