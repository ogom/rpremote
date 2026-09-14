# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Interaction::Detector do
  subject(:detector) { described_class.new(vertical_threshold: 0.7, horizontal_threshold: 0.7) }

  it "reports each upward orientation only when it changes and gives Z priority" do
    expect(detector.prime([0.8, 0.8, 0.8])).to eq(%i[orientation_changed z_up])
    expect(detector.detect(1, [0.8, 0.8, 0.8])).to be_empty
    expect(detector.detect(1, [0.8, 0.8, 0.0])).to eq([%i[orientation_changed y_up]])
    expect(detector.detect(1, [0.8, 0.0, 0.0])).to eq([%i[orientation_changed x_up]])
    expect(detector.detect(1, [-1.0, -1.0, -1.0])).to eq([%i[orientation_changed unknown]])
  end

  it "publishes a touch only on the pull-up input's falling edge" do
    detector.prime([0.0, 1.0, 0.0])

    expect(detector.detect(0, [0.0, 1.0, 0.0])).to eq([[:touch_pressed]])
    expect(detector.detect(0, [0.0, 1.0, 0.0])).to be_empty
    expect(detector.detect(1, [0.0, 1.0, 0.0])).to be_empty
    expect(detector.detect(0, [0.0, 1.0, 0.0])).to eq([[:touch_pressed]])
  end
end
