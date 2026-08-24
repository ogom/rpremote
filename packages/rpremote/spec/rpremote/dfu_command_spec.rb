# frozen_string_literal: true

require "tmpdir"
require "stringio"

RSpec.describe Rpremote::DfuCommand do
  it "rejects RITE bytecode that does not match the connected R2P2" do
    Dir.mktmpdir do |directory|
      source = File.join(directory, "app.mrb")
      File.binwrite(source, "RITE0400")
      port = Object.new
      serial = class_double(Rpremote::Serial)
      device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
      runner_instance = instance_double(Rpremote::Runner, run: "3.4.5\n")
      runner = class_double(Rpremote::Runner, new: runner_instance)
      modem = class_double(Rpremote::PicoModem)
      allow(modem).to receive(:new)
      allow(serial).to receive(:open).and_yield(port)

      expect do
        described_class.run(
          ["app", source], defaults: {}, services: { serial: serial, device: device, runner: runner, modem: modem }
        )
      end.to raise_error(Rpremote::Error, /RITE0400 does not match connected R2P2 RITE0300/)
      expect(modem).not_to have_received(:new)
    end
  end

  it "prints a compact DFU status" do
    port = Object.new
    serial = class_double(Rpremote::Serial)
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    runner_instance = instance_double(
      Rpremote::Runner,
      run: "active_slot=a\ntry_slot=a\nboot_count=0/3\nslot_a=confirmed mrb\nslot_b=confirmed mrb\n"
    )
    runner = class_double(Rpremote::Runner, new: runner_instance)
    output = StringIO.new
    allow(serial).to receive(:open).and_yield(port)

    described_class.run(
      ["status"], defaults: {}, output: output, services: { serial: serial, device: device, runner: runner }
    )

    expect(runner_instance).to have_received(:run).with(include("require \"dfu\""))
    expect(output.string).to include("active_slot=a", "slot_b=confirmed mrb")
  end
end
