# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Application::Composition do
  let(:clock) { DaisenkofunSpec::Clock.new }
  let(:logger) { DaisenkofunSpec::Logger.new }

  it "builds illumination without measurement components" do
    config = Daisenkofun::Application::Config.new(mode: :illumination)
    result = described_class.new(config: config, clock: clock, logger: logger).build

    expect(result.player).to be_a(Daisenkofun::Illumination::Player)
    expect(result.publisher).to be_nil
    expect(result.components).to be_empty
    expect(result.cleanup_components).to eq([result.player])
  end

  it "builds oximeter mode without musical or 572-LED subscribers" do
    publisher = double(:publisher)
    prepare_measurement_dependencies(publisher)
    config = Daisenkofun::Application::Config.new(mode: :oximeter)

    result = described_class.new(config: config, clock: clock, logger: logger).build

    expect(result.publisher).to equal(publisher)
    expect(result.components).to be_empty
    expect(result.cleanup_components).to eq([publisher])
  end

  it "subscribes musical before illumination and shares the canon planner" do
    publisher = double(:publisher)
    dispatcher = prepare_measurement_dependencies(publisher)
    musical = double(:musical)
    illumination = double(:illumination)
    planner = double(:planner)
    output = double(:output)
    factory_result = Daisenkofun::Application::MusicalFactory::Result.new(
      planner: planner, output: output, pattern: double(:pattern)
    )
    allow(Daisenkofun::Application::MusicalFactory).to receive(:new).and_return(double(build: factory_result))
    allow(Daisenkofun::Musical::Subscriber).to receive(:new).and_return(musical)
    allow(Daisenkofun::Illumination::BiometricPlayer).to receive(:new).and_return(illumination)
    expect(dispatcher).to receive(:subscribe).with(musical).ordered
    expect(dispatcher).to receive(:subscribe).with(illumination).ordered

    result = described_class.new(
      config: Daisenkofun::Application::Config.new(mode: :combined), clock: clock, logger: logger
    ).build

    expect(result.components).to eq([musical, illumination])
    expect(result.cleanup_components).to eq([publisher, musical, illumination])
    expect([result.musical_planner, result.musical_output]).to eq([planner, output])
  end

  def prepare_measurement_dependencies(publisher)
    dispatcher = double(:dispatcher)
    status_factory = class_double("DaisenkofunStatusFactory").as_stubbed_const
    sensor_factory = class_double("DaisenkofunSensorFactory").as_stubbed_const
    runner = class_double("DaisenkofunOximeterRunner").as_stubbed_const
    stub_const("Daisenkofun::Oximeter::StatusLed::Factory", status_factory)
    stub_const("Daisenkofun::Oximeter::SensorFactory", sensor_factory)
    stub_const("Daisenkofun::Oximeter::Runner", runner)
    allow(Daisenkofun::Oximeter::Dispatcher).to receive(:new).and_return(dispatcher)
    allow(status_factory).to receive(:new).and_return(double(call: double(:renderer)))
    allow(sensor_factory).to receive(:new).and_return(double(:sensor_factory))
    allow(runner).to receive(:new).and_return(publisher)
    dispatcher
  end
end
