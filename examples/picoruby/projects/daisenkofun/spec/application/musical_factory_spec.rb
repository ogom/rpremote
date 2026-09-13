# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Application::MusicalFactory do
  subject(:factory) { described_class.new(clock: DaisenkofunSpec::Clock.new, logger: DaisenkofunSpec::Logger.new) }

  it "selects silent output when the pin or volume disables audio" do
    pin_disabled = Daisenkofun::Application::Config.new(buzzer_pin: nil)
    volume_disabled = Daisenkofun::Application::Config.new(buzzer_volume: 0)

    expect(factory.build(pin_disabled).output).to be_a(Daisenkofun::Musical::Outputs::Null)
    expect(factory.build(volume_disabled).output).to be_a(Daisenkofun::Musical::Outputs::Null)
  end

  it "selects pulse output without a shared moat planner" do
    result = factory.build(Daisenkofun::Application::Config.new(musical_style: :pulse_translation))

    expect(result.output).to be_a(Daisenkofun::Musical::Outputs::PWM)
    expect(result.planner).to be_nil
    expect(result.pattern).to be_nil
  end

  it "shares one planner between canon audio and moat illumination" do
    result = factory.build(Daisenkofun::Application::Config.new(musical_style: :heartbeat_signature))

    expect(result.planner).to be_a(Daisenkofun::Musical::Planners::HeartbeatSignature)
    expect(result.output.planner).to equal(result.planner)
    expect(result.pattern.instance_variable_get(:@cue_source)).to equal(result.planner)
  end
end
