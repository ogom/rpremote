# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Application::Composition do
  let(:logger) { GoryokakuSpec::Logger.new }
  let(:clock) { GoryokakuSpec::Clock.new }
  let(:output) { GoryokakuSpec::Output.new }

  before do
    allow(Goryokaku::Musical::Outputs::Pwm).to receive(:new).and_return(output)
  end

  it "builds standalone illumination with a soundtrack and no event loop" do
    soundtrack = double(:soundtrack)
    player = double(:player)
    allow(Goryokaku::Musical::IlluminationSoundtrack).to receive(:new).and_return(soundtrack)
    allow(Goryokaku::Illumination::Player).to receive(:new).and_return(player)

    result = described_class.new(config: Goryokaku::Application::Config.new, logger: logger, clock: clock).build

    expect(result.player).to equal(player)
    expect(result.event_loop).to be_nil
    expect(Goryokaku::Illumination::Player).to have_received(:new).with(
      pin: 14, num: 380, logger: logger, soundtrack: soundtrack
    )
  end

  it "builds musical mode without a touch device and subscribes gestures, lights, then sound" do
    config = Goryokaku::Application::Config.new(mode: :musical)
    dispatcher, gestures, lights, musical, event_loop = prepare_event_components
    expect(Goryokaku::Interaction::Device).to receive(:new).with(hash_including(touch_pin: nil))
    allow(Goryokaku::Illumination::TambourinePlayer).to receive(:new).and_return(lights)
    expect(dispatcher).to receive(:subscribe).with(gestures).ordered
    expect(dispatcher).to receive(:subscribe).with(lights).ordered
    expect(dispatcher).to receive(:subscribe).with(musical).ordered

    result = described_class.new(config: config, logger: logger, clock: clock).build

    expect(result.event_loop).to equal(event_loop)
  end

  it "builds combined mode with touch selection, an interactive player, and a shared soundtrack output" do
    config = Goryokaku::Application::Config.new(mode: :combined, setlist_name: :story)
    dispatcher, gestures, lights, musical, event_loop = prepare_event_components
    soundtrack = double(:soundtrack)
    expect(Goryokaku::Interaction::Device).to receive(:new).with(hash_including(touch_pin: 21))
    allow(Goryokaku::Musical::IlluminationSoundtrack).to receive(:new).with(output: output, volume: 1).and_return(soundtrack)
    expect(Goryokaku::Illumination::InteractivePlayer).to receive(:new).with(
      pin: 14, num: 380, setlist_name: :story, logger: logger, soundtrack: soundtrack
    ).and_return(lights)
    expect(dispatcher).to receive(:subscribe).with(gestures).ordered
    expect(dispatcher).to receive(:subscribe).with(lights).ordered
    expect(dispatcher).to receive(:subscribe).with(musical).ordered

    result = described_class.new(config: config, logger: logger, clock: clock).build

    expect(result.event_loop).to equal(event_loop)
  end

  it "uses silent output and no illumination soundtrack when volume is zero" do
    silent = double(:silent)
    player = double(:player)
    allow(Goryokaku::Musical::Outputs::Null).to receive(:new).and_return(silent)
    allow(Goryokaku::Illumination::Player).to receive(:new).and_return(player)
    config = Goryokaku::Application::Config.new(buzzer_volume: 0)

    described_class.new(config: config, logger: logger, clock: clock).build

    expect(Goryokaku::Illumination::Player).to have_received(:new).with(
      pin: 14, num: 380, logger: logger, soundtrack: nil
    )
  end

  def prepare_event_components
    dispatcher = double(:dispatcher)
    gestures = double(:gestures)
    lights = double(:lights)
    musical = double(:musical)
    event_loop = double(:event_loop)
    stub_event_components(dispatcher, gestures, musical, event_loop)
    [dispatcher, gestures, lights, musical, event_loop]
  end

  def stub_event_components(dispatcher, gestures, musical, event_loop)
    allow(Goryokaku::Interaction::Dispatcher).to receive(:new).and_return(dispatcher)
    allow(Goryokaku::Interaction::Device).to receive(:new).and_return(double(:device))
    allow(Goryokaku::Interaction::Detector).to receive(:new).and_return(double(:detector))
    allow(Goryokaku::Interaction::Runner).to receive(:new).and_return(double(:publisher))
    allow(Goryokaku::Musical::TambourineDetector).to receive(:new).and_return(double(:tambourine_detector))
    allow(Goryokaku::Musical::GesturePublisher).to receive(:new).and_return(gestures)
    allow(Goryokaku::Musical::Subscriber).to receive(:new).and_return(musical)
    allow(Goryokaku::Runtime::EventLoop).to receive(:new).and_return(event_loop)
  end
end
