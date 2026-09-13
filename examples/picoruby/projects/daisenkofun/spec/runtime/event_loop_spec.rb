# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Runtime::EventLoop do
  def component(name, trace)
    Object.new.tap do |object|
      object.define_singleton_method(:start) { trace << "#{name}:start" }
      object.define_singleton_method(:tick) { |_now| trace << "#{name}:tick" }
      object.define_singleton_method(:stop) { trace << "#{name}:stop" }
    end
  end

  def publisher(trace, result: :complete, tick_error: nil)
    running = true
    Object.new.tap do |object|
      object.define_singleton_method(:start) { trace << "publisher:start" }
      object.define_singleton_method(:running?) { running }
      object.define_singleton_method(:tick) do |_now|
        trace << "publisher:tick"
        raise tick_error if tick_error

        running = false
      end
      object.define_singleton_method(:result) { result }
      object.define_singleton_method(:stop) { trace << "publisher:stop" }
    end
  end

  it "starts subscribers before the publisher, ticks the publisher first, and stops in reverse" do
    trace = []
    clock = DaisenkofunSpec::Clock.new
    first = component(:first, trace)
    second = component(:second, trace)
    loop = described_class.new(
      publisher: publisher(trace), components: [first, second], clock: clock,
      logger: DaisenkofunSpec::Logger.new, mode: :combined
    )

    expect(loop.call).to eq(:complete)
    expect(trace).to eq([
                          "first:start", "second:start", "publisher:start", "publisher:tick",
                          "publisher:stop", "second:stop", "first:stop"
                        ])
  end

  it "still stops the publisher and subscribers after a tick failure" do
    trace = []
    failure = RuntimeError.new("sensor failed")
    loop = described_class.new(
      publisher: publisher(trace, tick_error: failure), components: [component(:audio, trace)],
      clock: DaisenkofunSpec::Clock.new, logger: DaisenkofunSpec::Logger.new, mode: :combined
    )

    expect { loop.call }.to raise_error(failure)
    expect(trace.last(2)).to eq(["publisher:stop", "audio:stop"])
  end
end
