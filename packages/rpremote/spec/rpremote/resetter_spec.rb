# frozen_string_literal: true

RSpec.describe Rpremote::Resetter do
  let(:port) { Object.new }
  let(:serial) { class_double(Rpremote::Serial) }
  let(:command_shell) { instance_double(Rpremote::Shell, synchronize!: nil, send_command: nil) }

  it "reboots and retries until the R2P2 Shell is ready" do
    failed_shell = instance_double(Rpremote::Shell)
    allow(failed_shell).to receive(:synchronize!).and_raise(Rpremote::Shell::TimeoutError, "not ready")
    ready_shell = instance_double(Rpremote::Shell, synchronize!: nil)
    shell_class = class_double(Rpremote::Shell)
    allow(shell_class).to receive(:new).and_return(command_shell, failed_shell, ready_shell)
    allow(serial).to receive(:open).and_yield(port)
    sleeps = []

    result = described_class.new(
      serial: serial,
      timeout: 5,
      shell_class: shell_class,
      sleeper: ->(seconds) { sleeps << seconds },
      clock: -> { 0.0 },
      port_probe: ->(_path) { false }
    ).reset("/dev/cu.usbmodem101")

    expect(result).to eq("/dev/cu.usbmodem101")
    expect(command_shell).to have_received(:send_command).with("reboot")
    expect(serial).to have_received(:open).exactly(3).times
    expect(sleeps).to eq([0.1])
  end

  it "times out when R2P2 does not become ready" do
    shell_class = class_double(Rpremote::Shell, new: command_shell)
    allow(serial).to receive(:open).and_yield(port)
    times = [0.0, 0.3]

    resetter = described_class.new(
      serial: serial,
      timeout: 0.2,
      shell_class: shell_class,
      sleeper: ->(_seconds) {},
      clock: -> { times.shift || 0.3 },
      port_probe: ->(_path) { true }
    )

    expect { resetter.reset("/dev/cu.usbmodem101") }
      .to raise_error(described_class::TimeoutError, /USB serial port to disconnect/)
  end
end
