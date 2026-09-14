# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Runtime::EventLoop do
  def part(name, trace, running: true, tick_error: nil)
    Object.new.tap do |object|
      object.define_singleton_method(:start) { trace << "#{name}:start" }
      object.define_singleton_method(:running?) { running }
      object.define_singleton_method(:tick) do |_now|
        trace << "#{name}:tick"
        raise tick_error if tick_error
      end
      object.define_singleton_method(:stop) { trace << "#{name}:stop" }
    end
  end

  it "starts components before the publisher, ticks the publisher first, and stops in reverse" do
    trace = []
    clock = GoryokakuSpec::Clock.new
    publisher = part(:publisher, trace)
    first = part(:first, trace)
    second = part(:second, trace)

    described_class.new(publisher: publisher, components: [first, second], clock: clock, interval_ms: 20).call(iterations: 1)

    expect(trace).to eq([
                          "first:start", "second:start", "publisher:start", "publisher:tick",
                          "first:tick", "second:tick", "publisher:stop", "second:stop", "first:stop"
                        ])
    expect(clock.waits).to be_empty
  end

  it "still stops every started component after a tick failure" do
    trace = []
    failure = RuntimeError.new("motion failed")
    publisher = part(:publisher, trace, tick_error: failure)
    component = part(:illumination, trace)
    loop = described_class.new(publisher: publisher, components: [component], clock: GoryokakuSpec::Clock.new)

    expect { loop.call(iterations: 2) }.to raise_error(failure)
    expect(trace.last(2)).to eq(["publisher:stop", "illumination:stop"])
  end
end
