# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Application::Runner do
  let(:logger) { GoryokakuSpec::Logger.new }
  let(:dfu) { double(:dfu, confirm: nil) }

  def composition(player: nil, event_loop: nil)
    result = Goryokaku::Application::Composition::Result.new(player: player, event_loop: event_loop)
    double(:composition, build: result)
  end

  it "validates, confirms DFU, runs a setlist, cleans up, and reports success" do
    player = double(:player, play_setlist: nil, stop: nil)
    config = Goryokaku::Application::Config.new(setlist_name: :tests)
    runner = described_class.new(config: config, logger: logger, clock: GoryokakuSpec::Clock.new,
                                 composition: composition(player: player), dfu: dfu)

    runner.call

    expect(player).to have_received(:play_setlist).with(:tests, repeat: false)
    expect(player).to have_received(:stop)
    expect(dfu).to have_received(:confirm)
    expect(logger.messages).to eq([
                                    "GORYOKAKU mode=illumination event=start",
                                    "GORYOKAKU mode=illumination event=done status=ok"
                                  ])
  end

  it "runs an individual pattern when pattern_key is selected" do
    player = double(:player, play_pattern: nil, stop: nil)
    config = Goryokaku::Application::Config.new(pattern_key: :fireworks)

    described_class.new(config: config, logger: logger, clock: GoryokakuSpec::Clock.new,
                        composition: composition(player: player), dfu: dfu).call

    expect(player).to have_received(:play_pattern).with(:fireworks, repeat: false)
  end

  it "passes bounded iterations to musical and combined event loops" do
    event_loop = double(:event_loop, call: nil)
    config = Goryokaku::Application::Config.new(mode: :musical)

    described_class.new(config: config, logger: logger, clock: GoryokakuSpec::Clock.new,
                        composition: composition(event_loop: event_loop), dfu: dfu)
                   .call(iterations: 3)

    expect(event_loop).to have_received(:call).with(iterations: 3)
  end

  it "logs an error and stops illumination before re-raising a playback failure" do
    failure = RuntimeError.new("drawing failed")
    player = double(:player, stop: nil)
    allow(player).to receive(:play_setlist).and_raise(failure)
    config = Goryokaku::Application::Config.new
    runner = described_class.new(config: config, logger: logger, clock: GoryokakuSpec::Clock.new,
                                 composition: composition(player: player), dfu: dfu)

    expect { runner.call }.to raise_error(failure)
    expect(player).to have_received(:stop)
    expect(logger.messages.last).to eq("GORYOKAKU mode=illumination event=done status=error")
  end
end
