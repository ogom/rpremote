# frozen_string_literal: true

require "rpremote/build_command"

RSpec.describe Rpremote::BuildCommand do
  it "uses --firmware as the custom UF2 destination" do
    builder = instance_double(Rpremote::Builder, build: nil)

    described_class.run(
      ["--firmware", "firmware/custom.uf2"], defaults: {}, builder: builder
    )

    expect(builder).to have_received(:build).with(
      hash_including(firmware: "firmware/custom.uf2")
    )
  end

  it "lets --firmware override the configured destination" do
    builder = instance_double(Rpremote::Builder, build: nil)

    described_class.run(
      ["--firmware", "firmware/custom.uf2"],
      defaults: { firmware: "firmware/configured.uf2" },
      builder: builder
    )

    expect(builder).to have_received(:build).with(
      hash_including(firmware: "firmware/custom.uf2")
    )
  end

  it "uses the shared firmware setting as the default build destination" do
    builder = instance_double(Rpremote::Builder, build: nil)

    described_class.run(
      [], defaults: { firmware: "firmware/custom.uf2" }, builder: builder
    )

    expect(builder).to have_received(:build).with(
      hash_including(firmware: "firmware/custom.uf2")
    )
  end

  it "rejects the removed build --output option" do
    builder = instance_double(Rpremote::Builder)

    expect do
      described_class.run(["--output", "firmware/custom.uf2"], defaults: {}, builder: builder)
    end.to raise_error(OptionParser::InvalidOption, /--output/)
  end
end
