# frozen_string_literal: true

require "fileutils"
require "rpremote/deploy_command"
require "tmpdir"

RSpec.describe Rpremote::DeployCommand do
  attr_reader :directory

  let(:output) { StringIO.new }
  let(:error) { StringIO.new }
  let(:builder) { instance_double(Rpremote::Builder) }
  let(:flasher_instance) { instance_double(Rpremote::Flasher) }
  let(:flasher) { class_double(Rpremote::Flasher, new: flasher_instance) }
  let(:serial) { class_double(Rpremote::Serial) }
  let(:device) { class_double(Rpremote::Device) }
  let(:recursive_copy) { instance_double(Rpremote::RecursiveCopy) }
  let(:shell_instance) { instance_double(Rpremote::Shell, synchronize!: nil) }
  let(:shell) { class_double(Rpremote::Shell, new: shell_instance) }
  let(:runner_instance) { instance_double(Rpremote::Runner) }
  let(:runner) { class_double(Rpremote::Runner, new: runner_instance) }
  let(:port_io) { Object.new }
  let(:project) { File.join(directory, "oximeter") }
  let(:library) { File.join(project, "lib", "oximeter") }
  let(:source) { File.join(project, "main.rb") }
  let(:result) do
    Rpremote::Flasher::Result.new(
      mount: "/Volumes/RP2350",
      destination: "/Volumes/RP2350/custom.uf2",
      port: "/dev/cu.usbmodem101"
    )
  end

  around do |example|
    Dir.mktmpdir do |temporary_directory|
      @directory = temporary_directory
      FileUtils.mkdir_p(library)
      File.write(source, "puts 'ok'\n")
      File.write(File.join(library, "config.rb"), "module Oximeter; end\n")
      example.run
    end
  end

  it "builds, flashes, copies the project library, and runs its entry file in order" do
    connection_options = {
      language: "picoruby", language_version: "4.0.3", board: "pico2_w",
      cache_dir: "firmware", firmware: "firmware/custom.uf2", mrbgems: "Mrbgems.dev",
      mount: "/Volumes/RP2350", port: result.port, baud: 9_600, timeout: 4.0
    }
    expect(builder).to receive(:build).ordered.with(
      language: "picoruby", language_version: "4.0.3", board: "pico2_w",
      cache_dir: "firmware", firmware: "firmware/custom.uf2", mrbgems: "Mrbgems.dev",
      output: output, error: error
    ) { File.write(source, "puts 'deployed'\n") }
    expect(flasher).to receive(:new).ordered.with(timeout: 4.0).and_return(flasher_instance)
    expect(flasher_instance).to receive(:find_mounted).ordered.with("/Volumes/RP2350").and_return(nil)
    expect(Rpremote::BootselCommand).to receive(:enter).ordered.with(
      mount: "/Volumes/RP2350", port: "/dev/cu.config", baud: 9_600, timeout: 4.0,
      output: output, services: { flasher: flasher, serial: serial, device: device, shell: shell }
    ).and_return("/Volumes/RP2350")
    expect(flasher_instance).to receive(:flash).ordered.with(
      File.expand_path("firmware/custom.uf2"), mount: "/Volumes/RP2350", port: "/dev/cu.config"
    ).and_return(result)
    expect(serial).to receive(:open).ordered.with(result.port, baud: 9_600).and_yield(port_io)
    expect(shell).to receive(:new).ordered.with(port_io, timeout: 2.0).and_return(shell_instance)
    expect(shell_instance).to receive(:synchronize!).ordered
    expect(recursive_copy).to receive(:call).ordered.with(library, ":/lib/oximeter", connection_options)
    expect(serial).to receive(:open).ordered.with(result.port, baud: 9_600).and_yield(port_io)
    expect(runner).to receive(:new).ordered.with(port_io, timeout: 4.0).and_return(runner_instance)
    run_expectation = expect(runner_instance).to receive(:run).ordered
    run_expectation.with(
      "puts 'deployed'\n", output: output, cleanup: false, remote_path: Rpremote::Runner::DEPLOY_REMOTE_PATH
    ).and_return("deployed\n")

    described_class.run(
      [
        project, "--board", "pico2_w", "--firmware", "firmware/custom.uf2",
        "--mrbgems", "Mrbgems.dev", "--mount", "/Volumes/RP2350",
        "--port", "/dev/cu.config", "--baud", "9600", "--timeout", "4"
      ],
      defaults: {}, output: output, error: error,
      services: {
        builder: builder, flasher: flasher, serial: serial, device: device,
        recursive_copy: recursive_copy, shell: shell, runner: runner
      }
    )

    expect(output.string.lines.grep(/^deploy /)).to eq(
      [
        "deploy build: #{File.expand_path("firmware/custom.uf2")}\n",
        "deploy bootsel: requesting USB BOOTSEL mode through /dev/cu.config\n",
        "deploy flash: #{File.expand_path("firmware/custom.uf2")} to /Volumes/RP2350; this replaces persistent board firmware\n",
        "deploy connect: waiting for R2P2 Shell on #{result.port}\n",
        "deploy connect: ready on #{result.port}\n",
        "deploy push: #{library} -> :/lib/oximeter\n",
        "deploy run: #{source} on #{result.port}\n",
        "deploy run: completed; output bytes: 9\n"
      ]
    )
  end

  it "validates the project before building or flashing" do
    FileUtils.remove_entry(source)
    expect(builder).not_to receive(:build)
    expect(flasher).not_to receive(:new)

    expect do
      described_class.run(
        [project], defaults: {},
                   services: { builder: builder, flasher: flasher }
      )
    end.to raise_error(ArgumentError, /project entry file not found/)
  end

  it "skips the library copy when the project library directory does not exist" do
    FileUtils.remove_entry(File.join(project, "lib"))
    allow(builder).to receive(:build)
    allow(flasher).to receive(:new).and_return(flasher_instance)
    allow(flasher_instance).to receive(:find_mounted).and_return("/Volumes/RP2350")
    allow(flasher_instance).to receive(:flash).and_return(result)
    allow(serial).to receive(:open).and_yield(port_io)
    allow(runner).to receive(:new).and_return(runner_instance)
    allow(runner_instance).to receive(:run)
    expect(recursive_copy).not_to receive(:call)

    described_class.run(
      [project], defaults: { mount: "/Volumes/RP2350" }, output: output, error: error,
                 services: {
                   builder: builder, flasher: flasher, serial: serial, device: device,
                   recursive_copy: recursive_copy, shell: shell, runner: runner
                 }
    )

    expect(output.string).to include("deploy push: skipped; directory not found: #{library}")
    expect(output.string).to include("deploy run: #{source} on #{result.port}")
  end

  it "retries until the R2P2 Shell becomes ready after flashing" do
    FileUtils.remove_entry(File.join(project, "lib"))
    starting_shell = instance_double(Rpremote::Shell)
    ready_shell = instance_double(Rpremote::Shell)
    allow(builder).to receive(:build)
    allow(flasher).to receive(:new).and_return(flasher_instance)
    allow(flasher_instance).to receive(:find_mounted).and_return("/Volumes/RP2350")
    allow(flasher_instance).to receive(:flash).and_return(result)
    allow(serial).to receive(:open).and_yield(port_io)
    expect(shell).to receive(:new).with(port_io, timeout: 2.0)
                                  .and_return(starting_shell, ready_shell)
    expect(starting_shell).to receive(:synchronize!)
      .and_raise(Rpremote::Shell::TimeoutError, "not ready")
    expect(ready_shell).to receive(:synchronize!)
    expect(runner).to receive(:new).with(port_io, timeout: 20.0).and_return(runner_instance)
    expect(runner_instance).to receive(:run).with(
      File.binread(source), output: output, cleanup: false, remote_path: Rpremote::Runner::DEPLOY_REMOTE_PATH
    )
    delays = []

    described_class.run(
      [project], defaults: { mount: "/Volumes/RP2350" }, output: output, error: error,
                 services: {
                   builder: builder, flasher: flasher, serial: serial, device: device,
                   recursive_copy: recursive_copy, shell: shell, runner: runner,
                   sleeper: ->(seconds) { delays << seconds }
                 }
    )

    expect(delays).to eq([described_class::RETRY_INTERVAL])
    expect(output.string).to include("deploy connect: ready on #{result.port}")
    expect(output.string).to include("deploy run: #{source} on #{result.port}")
  end

  it "does not report completion when R2P2 reports a Ruby exception" do
    FileUtils.remove_entry(File.join(project, "lib"))
    allow(builder).to receive(:build)
    allow(flasher).to receive(:new).and_return(flasher_instance)
    allow(flasher_instance).to receive(:find_mounted).and_return("/Volumes/RP2350")
    allow(flasher_instance).to receive(:flash).and_return(result)
    allow(serial).to receive(:open).and_yield(port_io)
    allow(runner).to receive(:new).and_return(runner_instance)
    allow(runner_instance).to receive(:run)
      .and_raise(Rpremote::Shell::CommandError, "Ruby exception reported by R2P2")

    expect do
      described_class.run(
        [project], defaults: { mount: "/Volumes/RP2350" }, output: output, error: error,
                   services: {
                     builder: builder, flasher: flasher, serial: serial, device: device,
                     recursive_copy: recursive_copy, shell: shell, runner: runner
                   }
      )
    end.to raise_error(Rpremote::Shell::CommandError, "Ruby exception reported by R2P2")

    expect(output.string).to include("deploy run: #{source} on #{result.port}")
    expect(output.string).not_to include("deploy run: completed")
  end

  it "does not copy or run when the R2P2 Shell is not ready before the timeout" do
    allow(builder).to receive(:build)
    allow(flasher).to receive(:new).and_return(flasher_instance)
    allow(flasher_instance).to receive(:find_mounted).and_return("/Volumes/RP2350")
    allow(flasher_instance).to receive(:flash).and_return(result)
    allow(serial).to receive(:open)
      .with(result.port, baud: 115_200)
      .and_raise(Rpremote::Serial::ConfigurationError, "cannot open serial port")
    expect(recursive_copy).not_to receive(:call)
    expect(runner).not_to receive(:new)

    expect do
      times = [0.0, 21.0]
      described_class.run(
        [project], defaults: { mount: "/Volumes/RP2350" }, output: output, error: error,
                   services: {
                     builder: builder, flasher: flasher, serial: serial, device: device,
                     recursive_copy: recursive_copy, shell: shell, runner: runner,
                     sleeper: ->(_seconds) {}, clock: -> { times.shift || 21.0 }
                   }
      )
    end.to raise_error(described_class::Error, "timed out waiting for R2P2 Shell after flash")
  end

  it "does not flash or copy files when the build fails" do
    allow(builder).to receive(:build).and_raise(Rpremote::Builder::Error, "build failed")
    expect(flasher).not_to receive(:new)
    expect(recursive_copy).not_to receive(:call)

    expect do
      described_class.run(
        [project], defaults: {}, output: output, error: error,
                   services: { builder: builder, flasher: flasher, recursive_copy: recursive_copy }
      )
    end.to raise_error(Rpremote::Builder::Error, "build failed")
  end

  it "uses an already mounted BOOTSEL volume without requesting a serial reset" do
    allow(builder).to receive(:build)
    allow(flasher).to receive(:new).and_return(flasher_instance)
    allow(flasher_instance).to receive(:find_mounted).and_return("/Volumes/RP2350")
    allow(flasher_instance).to receive(:flash).and_return(result)
    allow(recursive_copy).to receive(:call)
    allow(serial).to receive(:open).and_yield(port_io)
    allow(runner).to receive(:new).and_return(runner_instance)
    allow(runner_instance).to receive(:run)
    expect(Rpremote::BootselCommand).not_to receive(:enter)

    described_class.run(
      [project], defaults: { mount: "/Volumes/RP2350" }, output: output, error: error,
                 services: {
                   builder: builder, flasher: flasher, serial: serial, device: device,
                   recursive_copy: recursive_copy, shell: shell, runner: runner
                 }
    )

    expect(output.string).to include(
      "deploy bootsel: already mounted at /Volumes/RP2350; skipping serial reset"
    )
  end
end
