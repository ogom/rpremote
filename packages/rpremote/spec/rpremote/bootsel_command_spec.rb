# frozen_string_literal: true

require "rpremote/bootsel_command"

RSpec.describe Rpremote::BootselCommand do
  let(:output) { StringIO.new }
  let(:device) { class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101") }
  let(:serial) { class_double(Rpremote::Serial) }
  let(:connection) { Object.new }
  let(:shell_instance) { instance_double(Rpremote::Shell) }
  let(:shell) { class_double(Rpremote::Shell, new: shell_instance) }
  let(:flasher_instance) { instance_double(Rpremote::Flasher) }
  let(:flasher) { class_double(Rpremote::Flasher, new: flasher_instance) }
  let(:services) { { device: device, serial: serial, shell: shell, flasher: flasher } }

  it "asks R2P2 to enter BOOTSEL and waits for its mount" do
    expect(device).to receive(:main_port).with(nil).and_return("/dev/cu.usbmodem101")
    expect(serial).to receive(:open).with("/dev/cu.usbmodem101", baud: 115_200).and_yield(connection)
    expect(shell_instance).to receive(:synchronize!).ordered
    expect(shell_instance).to receive(:execute).ordered.with("type bootsel").and_return("bootsel is /bin/bootsel\n")
    expect(shell_instance).to receive(:send_command).ordered.with("bootsel")
    expect(flasher).to receive(:new).with(timeout: be_within(0.1).of(20.0)).and_return(flasher_instance)
    expect(flasher_instance).to receive(:wait_for_mount).with(mount: nil).and_return("/Volumes/RP2350")

    described_class.run([], defaults: {}, output: output, services: services)

    expect(output.string).to include("BOOTSEL ready: /Volumes/RP2350")
  end

  it "resets external flash memory in BOOTSEL mode" do
    allow(device).to receive(:main_port).and_return("/dev/cu.usbmodem101")
    allow(serial).to receive(:open).and_yield(connection)
    allow(shell_instance).to receive(:synchronize!)
    allow(shell_instance).to receive(:execute).with("type bootsel").and_return("bootsel is /bin/bootsel\n")
    allow(shell_instance).to receive(:send_command).with("bootsel")
    allow(flasher).to receive(:new).with(timeout: 20.0).and_return(flasher_instance)
    allow(flasher_instance).to receive(:find_mounted).with(nil).and_return("/Volumes/RP2350")
    allow(flasher_instance).to receive(:flash)
    allow(File).to receive(:file?).with(File.expand_path("firmware/nuke_universal.uf2")).and_return(true)

    described_class.run(
      ["--reset-flash-memory"], defaults: {}, output: output, services: services
    )

    expect(flasher_instance).to have_received(:flash).with(
      File.expand_path("firmware/nuke_universal.uf2"),
      mount: "/Volumes/RP2350",
      wait_for_port: false
    )
    expect(output.string).to include("external flash memory", "rpremote flash")
    expect(serial).not_to have_received(:open)
  end

  it "explains how to bootstrap firmware without the BOOTSEL command" do
    allow(device).to receive(:main_port).and_return("/dev/cu.usbmodem101")
    allow(serial).to receive(:open).and_yield(connection)
    allow(shell_instance).to receive(:synchronize!)
    allow(shell_instance).to receive(:execute).with("type bootsel").and_return("bootsel: not found\n")
    expect(shell_instance).not_to receive(:send_command)
    expect(flasher).not_to receive(:new)

    expect { described_class.run([], defaults: {}, output: output, services: services) }
      .to raise_error(described_class::Error, /flash a current rpremote UF2 once while holding BOOTSEL/)
  end

  it "retries until the R2P2 Shell is ready" do
    clock_values = [0.0, 0.0, 0.0, 0.25, 0.25, 0.25]
    clock = -> { clock_values.shift || 0.25 }
    allow(device).to receive(:main_port).and_return("/dev/cu.usbmodem101")
    allow(serial).to receive(:open).and_yield(connection)
    allow(shell_instance).to receive(:execute).with("type bootsel").and_return("bootsel is /bin/bootsel\n")
    expect(shell_instance).to receive(:synchronize!).ordered.and_raise(Rpremote::Shell::TimeoutError)
    expect(shell_instance).to receive(:synchronize!).ordered
    expect(shell_instance).to receive(:send_command).with("bootsel")
    expect(flasher).to receive(:new).with(timeout: 19.75).and_return(flasher_instance)
    expect(flasher_instance).to receive(:wait_for_mount).with(mount: nil).and_return("/Volumes/RP2350")

    described_class.run(
      [],
      defaults: {},
      output: output,
      services: services.merge(sleeper: ->(_seconds) {},
                               clock: clock)
    )
  end
end
