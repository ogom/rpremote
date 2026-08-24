# frozen_string_literal: true

RSpec.describe Rpremote::Target do
  it "derives source and firmware paths from one target" do
    target = described_class.new(language_version: "3.4.2", cache_dir: "tmp")

    expect(target.source_dir(root: "/project")).to eq("/project/tmp/picoruby-3.4.2")
    expect(target.firmware_path).to eq("tmp/picoruby-3.4.2-pico2.uf2")
  end

  it "uses an explicit firmware path" do
    target = described_class.new(firmware: "dist/custom.uf2")

    expect(target.firmware_path).to eq("dist/custom.uf2")
    expect(target.firmware_path(root: "/project")).to eq("/project/dist/custom.uf2")
  end

  it "expands a version placeholder in the cache path" do
    target = described_class.new(language_version: "3.4.2", cache_dir: "tmp/{version}")

    expect(target.source_dir(root: "/project")).to eq("/project/tmp/3.4.2/picoruby-3.4.2")
    expect(target.firmware_path).to eq("tmp/3.4.2/picoruby-3.4.2-pico2.uf2")
  end

  it "rejects identifiers that could escape the cache directory" do
    expect { described_class.new(language: "../picoruby") }
      .to raise_error(ArgumentError, /invalid language/)
  end
end
