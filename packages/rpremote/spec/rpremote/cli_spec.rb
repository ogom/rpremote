# frozen_string_literal: true

require "rpremote/cli"
require "stringio"
require "tmpdir"

RSpec.describe Rpremote::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  it "prints help when no command is given" do
    status = described_class.start([], stdout: stdout, stderr: stderr)

    expect(status).to eq(0)
    expect(stdout.string).to include("rpremote fs cp")
  end

  it "prints command-specific help without loading configuration or accessing a board" do
    config = class_double(Rpremote::Config, extract_option!: ["missing.json", true], load_command: {})
    commands = [
      %w[setup --help], %w[build --help], %w[build clean --help], %w[dfu app --help],
      %w[dfu compile --help], %w[dfu status --help], %w[mrbgems update --help], %w[flash --help],
      %w[config show --help], %w[ports --help], %w[run --help], %w[exec --help], %w[monitor --help],
      %w[repl --help], %w[reset --help], %w[fs cp --help], %w[fs cat --help], %w[fs ls --help],
      %w[fs rm --help], %w[fs mkdir --help]
    ]

    commands.each do |command|
      status = described_class.start(command, stdout: stdout, stderr: stderr, config: config)

      expect(status).to eq(0), command.join(" ")
      expect(stdout.string).to include("Usage:"), command.join(" ")
      stdout.truncate(0)
      stdout.rewind
    end

    expect(config).not_to have_received(:load_command)
  end

  it "uses the shared command syntax in root and command help" do
    described_class.start([], stdout: stdout, stderr: stderr)
    root_help = stdout.string
    stdout.truncate(0)
    stdout.rewind

    described_class.start(%w[run --help], stdout: stdout, stderr: stderr)

    usage = Rpremote::Help::COMMAND_USAGE.fetch(:run)
    expect(root_help).to include(usage)
    expect(stdout.string).to include(usage)
  end

  it "prints all detected ports" do
    device = class_double(Rpremote::Device, ports: ["/dev/cu.usbmodem1101"])

    status = described_class.start(["ports"], stdout: stdout, stderr: stderr, device: device)

    expect(status).to eq(0)
    expect(stdout.string).to eq("/dev/cu.usbmodem1101\n")
  end

  it "shows effective configuration with file and command-line overrides" do
    path = File.join(Dir.tmpdir, "rpremote-cli-config-show-#{Process.pid}.json")
    File.write(path, <<~JSON)
      {
        "language_version": "3.4.2",
        "board": "pico2_w",
        "cache": "artifacts/{version}",
        "mrbgems": false,
        "port": "/dev/cu.config",
        "baud": 9600,
        "timeout": 12
      }
    JSON

    status = described_class.start(
      ["config", "show", "--config", path, "--board", "pico2", "--timeout", "5"],
      stdout: stdout, stderr: stderr
    )

    expect(status).to eq(0)
    expect(stdout.string).to eq(<<~OUTPUT)
      language=picoruby
      language_version=3.4.2
      board=pico2
      cache=artifacts/3.4.2
      firmware=artifacts/3.4.2/picoruby-3.4.2-pico2.uf2
      mrbgems=false
      mount=auto
      port=/dev/cu.config
      baud=9600
      timeout=5.0
    OUTPUT
  ensure
    FileUtils.rm_f(path) if path
  end

  it "returns a nonzero status for an unknown command" do
    status = described_class.start(["unknown"], stdout: stdout, stderr: stderr)

    expect(status).to eq(1)
    expect(stderr.string).to include("unknown command")
  end

  it "returns an unknown-command error when a config file exists" do
    path = File.join(Dir.tmpdir, "rpremote-cli-config-#{Process.pid}.json")
    File.write(path, "{\"board\": \"pico2\"}\n")

    status = described_class.start(
      ["--config", path, "unknown"], stdout: stdout, stderr: stderr
    )

    expect(status).to eq(1)
    expect(stderr.string).to include("unknown command")
  ensure
    FileUtils.rm_f(path) if path
  end

  it "sets up the default PicoRuby source" do
    source_instance = instance_double(Rpremote::LanguageSource, setup: "/project/firmware/picoruby-4.0.3")
    language_source = class_double(Rpremote::LanguageSource, new: source_instance)
    stub_const("Rpremote::LanguageSource", language_source)
    config_result = Rpremote::Config::Result.new(path: "/project/config/setting.json", created: true)
    config = class_double(
      Rpremote::Config,
      extract_option!: ["config/setting.json", false],
      load_command: {},
      setup: config_result
    )

    status = described_class.start(
      ["setup", "--force"], stdout: stdout, stderr: stderr, config: config
    )

    expect(status).to eq(0)
    expect(config).to have_received(:setup).with(filename: "config/setting.json")
    expect(language_source).to have_received(:new).with(
      language: "picoruby", version: "4.0.3", cache_dir: "firmware"
    )
    expect(source_instance).to have_received(:setup).with(force: true)
    expect(stdout.string).to include("created config")
    expect(stdout.string).to include("installed picoruby 4.0.3")
  end

  it "sets up PicoRuby 3.4.2 when selected" do
    source_instance = instance_double(Rpremote::LanguageSource, setup: "/project/firmware/picoruby-3.4.2")
    language_source = class_double(Rpremote::LanguageSource, new: source_instance)
    stub_const("Rpremote::LanguageSource", language_source)
    config_result = Rpremote::Config::Result.new(path: "/project/config/setting.json", created: false)
    config = class_double(
      Rpremote::Config,
      extract_option!: ["config/setting.json", false],
      load_command: { cache: "firmware", language: "picoruby" },
      setup: config_result
    )

    status = described_class.start(
      ["setup", "--language-version", "3.4.2"],
      stdout: stdout,
      stderr: stderr,
      config: config
    )

    expect(status).to eq(0)
    expect(language_source).to have_received(:new).with(
      language: "picoruby", version: "3.4.2", cache_dir: "firmware"
    )
    expect(stdout.string).to include("installed picoruby 3.4.2")
  end

  it "builds custom firmware from the rpremote repository" do
    allow(Rpremote::BuildCommand).to receive(:run)

    status = described_class.start(
      ["build"],
      stdout: stdout,
      stderr: stderr
    )

    expect(status).to eq(0)
    expect(Rpremote::BuildCommand).to have_received(:run).with(
      [],
      defaults: {},
      output: stdout,
      error: stderr
    )
  end

  it "rejects the removed picoruby-dir build option" do
    status = described_class.start(
      %w[build --picoruby-dir /source/picoruby], stdout: stdout, stderr: stderr
    )

    expect(status).to eq(1)
    expect(stderr.string).to include("invalid option: --picoruby-dir")
  end

  it "cleans generated build files" do
    builder = instance_double(Rpremote::Builder, clean: nil)
    allow(Rpremote::Builder).to receive(:new).and_return(builder)

    status = described_class.start(%w[build clean], stdout: stdout, stderr: stderr)

    expect(status).to eq(0)
    expect(builder).to have_received(:clean).with(output: stdout)
  end

  it "checks a Mrbgems definition" do
    dependencies = [
      Rpremote::Mrbgems::Dependency.new(
        type: :github, source: "ksbmyk/picoruby-ws2812-plus",
        branch: "main", commit: nil, path: nil
      )
    ]
    manager = instance_double(
      Rpremote::Mrbgems, check: dependencies, path: "/project/Mrbgems"
    )
    mrbgems = class_double(Rpremote::Mrbgems, new: manager)

    stub_const("Rpremote::Mrbgems", mrbgems)
    status = described_class.start(%w[mrbgems check], stdout: stdout, stderr: stderr)

    expect(status).to eq(0)
    expect(stdout.string).to eq("checked 1 mrbgems: /project/Mrbgems\n")
  end

  it "updates Mrbgems.lock" do
    result = {
      "version" => 1,
      "gems" => [{ "type" => "github", "source" => "owner/gem",
                   "branch" => "main", "commit" => "a" * 40 }]
    }
    manager = instance_double(
      Rpremote::Mrbgems, lock: result, lock_path: "/project/Mrbgems.lock"
    )
    mrbgems = class_double(Rpremote::Mrbgems, new: manager)

    stub_const("Rpremote::Mrbgems", mrbgems)
    status = described_class.start(%w[mrbgems update], stdout: stdout, stderr: stderr)

    expect(status).to eq(0)
    expect(manager).to have_received(:lock).with(update: true)
    expect(stdout.string).to eq("locked 1 mrbgems: /project/Mrbgems.lock\n")
  end

  it "uses config defaults and lets command-line options override them" do
    source = File.expand_path("../fixtures/run.rb", __dir__)
    config = class_double(
      Rpremote::Config,
      load_command: { port: "/dev/cu.config", baud: 9600, timeout: 12.0 }
    )
    allow(config).to receive(:extract_option!) { |args| Rpremote::Config.extract_option!(args) }
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.config")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    runner_instance = instance_double(Rpremote::Runner, run: "ok\n")
    runner = class_double(Rpremote::Runner, new: runner_instance)
    stub_const("Rpremote::Runner", runner)

    status = described_class.start(
      ["run", source, "--config", "project.json", "--baud", "115200", "--timeout", "2"],
      stdout: stdout,
      stderr: stderr,
      config: config,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(config).to have_received(:load_command).with("run", filename: "project.json", required: true)
    expect(device).to have_received(:main_port).with("/dev/cu.config")
    expect(serial).to have_received(:open).with("/dev/cu.config", baud: 115_200)
    expect(runner).to have_received(:new).with(port, timeout: 2.0)
  end

  it "flashes the default custom firmware" do
    result = Rpremote::Flasher::Result.new(
      mount: "/Volumes/RP2350",
      destination: "/Volumes/RP2350/r2p2.uf2",
      port: "/dev/cu.usbmodem1101"
    )
    flasher_instance = instance_double(Rpremote::Flasher, flash: result)
    flasher = class_double(Rpremote::Flasher, new: flasher_instance)

    status = described_class.start(
      ["flash", "--mount", "/Volumes/RP2350"],
      stdout: stdout,
      stderr: stderr,
      flasher: flasher
    )

    expect(status).to eq(0)
    expect(flasher_instance).to have_received(:flash).with(
      File.expand_path("firmware/picoruby-4.0.3-pico2.uf2"),
      mount: "/Volumes/RP2350",
      port: nil
    )
    expect(stdout.string).to include("flashing #{File.expand_path("firmware/picoruby-4.0.3-pico2.uf2")} to /Volumes/RP2350; " \
                                     "this replaces persistent board firmware")
    expect(stdout.string).to include("flashed firmware picoruby-4.0.3-pico2.uf2")
  end

  it "requires --firmware instead of a positional UF2 file" do
    status = described_class.start(
      %w[flash firmware/custom.uf2], stdout: stdout, stderr: stderr
    )

    expect(status).to eq(1)
    expect(stderr.string).to include("flash does not accept arguments; use --firmware FILE")
  end

  it "stages a Ruby application with PicoModem DFU" do
    source = File.expand_path("../fixtures/run.rb", __dir__)
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    modem_instance = instance_double(Rpremote::PicoModem, dfu: 42)
    modem = class_double(Rpremote::PicoModem, new: modem_instance)
    stub_const("Rpremote::PicoModem", modem)

    status = described_class.start(
      ["dfu", "app", source, "--port", "/dev/cu.usbmodem101"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(modem).to have_received(:new).with(port, timeout: 20.0)
    expect(modem_instance).to have_received(:dfu).with(
      File.binread(source), type: "RUBY"
    )
    expect(stdout.string).to include("staging DFU ruby app (#{File.size(source)} bytes): #{source} -> inactive slot " \
                                     "on /dev/cu.usbmodem101; this changes the staged boot application")
    expect(stdout.string).to include("staged DFU ruby app")
    expect(stdout.string).to include("DFU.confirm")
  end

  it "explains when the DFU app file is missing" do
    status = described_class.start(
      ["dfu", "app", "missing.rb"], stdout: stdout, stderr: stderr
    )

    expect(status).to eq(1)
    expect(stderr.string).to include("DFU app file not found: missing.rb")
  end

  it "uploads and runs a Ruby file" do
    source = File.expand_path("../fixtures/run.rb", __dir__)
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    runner_instance = instance_double(Rpremote::Runner)
    allow(runner_instance).to receive(:run) do |_data, output:|
      output.write("three\n")
      "three\n"
    end
    runner = class_double(Rpremote::Runner, new: runner_instance)
    stub_const("Rpremote::Runner", runner)

    status = described_class.start(
      ["run", source, "--port", "/dev/cu.usbmodem101", "--timeout", "2"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(device).to have_received(:main_port).with("/dev/cu.usbmodem101")
    expect(serial).to have_received(:open).with("/dev/cu.usbmodem101", baud: 115_200)
    expect(runner).to have_received(:new).with(port, timeout: 2.0)
    expect(runner_instance).to have_received(:run).with("# frozen_string_literal: true\n\nputs 1 + 2\n", output: stdout)
    expect(stdout.string).to eq("three\n")
  end

  it "returns a nonzero status when a Ruby file raises on R2P2" do
    source = File.expand_path("../fixtures/run.rb", __dir__)
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    runner_instance = instance_double(Rpremote::Runner)
    allow(runner_instance).to receive(:run) do |_data, output:|
      output.write("missing (NameError)\n")
      raise Rpremote::Shell::CommandError, "Ruby exception reported by R2P2"
    end
    stub_const("Rpremote::Runner", class_double(Rpremote::Runner, new: runner_instance))

    status = described_class.start(
      ["run", source, "--port", "/dev/cu.usbmodem101"], stdout: stdout, stderr: stderr, device: device, serial: serial
    )

    expect(status).to eq(1)
    expect(stdout.string).to eq("missing (NameError)\n")
    expect(stderr.string).to eq("rpremote: Ruby exception reported by R2P2\n")
  end

  it "opens an interactive serial monitor" do
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    terminal_instance = instance_double(Rpremote::Terminal, run: nil)
    terminal = class_double(Rpremote::Terminal, new: terminal_instance)
    stub_const("Rpremote::Terminal", terminal)

    status = described_class.start(
      ["monitor", "--port", "/dev/cu.usbmodem101"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(terminal).to have_received(:new).with(port, output: stdout)
    expect(terminal_instance).to have_received(:run).with(exit_sequence: nil)
    expect(stderr.string).to include("Ctrl-] to exit")
  end

  it "enters PicoIRB and leaves it when the interactive session ends" do
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    shell_instance = instance_double(Rpremote::Shell, synchronize!: nil, send_command: nil)
    shell = class_double(Rpremote::Shell, new: shell_instance)
    stub_const("Rpremote::Shell", shell)
    terminal_instance = instance_double(Rpremote::Terminal, run: nil)
    terminal = class_double(Rpremote::Terminal, new: terminal_instance)
    stub_const("Rpremote::Terminal", terminal)

    status = described_class.start(
      ["repl", "--port", "/dev/cu.usbmodem101", "--timeout", "2"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(shell).to have_received(:new).with(port, timeout: 2.0)
    expect(shell_instance).to have_received(:synchronize!)
    expect(shell_instance).to have_received(:send_command).with("irb")
    expect(terminal_instance).to have_received(:run).with(exit_sequence: "\x03\x04".b)
  end

  it "executes Ruby code without a local source file" do
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    runner_instance = instance_double(Rpremote::Runner)
    allow(runner_instance).to receive(:run) do |_data, output:|
      output.write("three\n")
      "three\n"
    end
    runner = class_double(Rpremote::Runner, new: runner_instance)
    stub_const("Rpremote::Runner", runner)

    status = described_class.start(
      ["exec", "puts 1 + 2", "--port", "/dev/cu.usbmodem101"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(runner_instance).to have_received(:run).with("puts 1 + 2", output: stdout)
    expect(stdout.string).to eq("three\n")
  end

  it "returns a nonzero status when executed Ruby code raises on R2P2" do
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    runner_instance = instance_double(Rpremote::Runner)
    allow(runner_instance).to receive(:run) do |_data, output:|
      output.write("missing (NameError)\n")
      raise Rpremote::Shell::CommandError, "Ruby exception reported by R2P2"
    end
    stub_const("Rpremote::Runner", class_double(Rpremote::Runner, new: runner_instance))

    status = described_class.start(
      ["exec", "missing", "--port", "/dev/cu.usbmodem101"], stdout: stdout, stderr: stderr, device: device, serial: serial
    )

    expect(status).to eq(1)
    expect(stdout.string).to eq("missing (NameError)\n")
    expect(stderr.string).to eq("rpremote: Ruby exception reported by R2P2\n")
  end

  it "rejects an execution language that has no runtime backend" do
    status = described_class.start(
      ["exec", "print('ok')", "--language", "micropython"],
      stdout: stdout,
      stderr: stderr
    )

    expect(status).to eq(1)
    expect(stderr.string).to include("unsupported language: micropython")
  end

  %w[ls rm mkdir].each do |command|
    it "runs fs #{command} through the R2P2 Shell" do
      port = Object.new
      device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
      serial = class_double(Rpremote::Serial)
      allow(serial).to receive(:open).and_yield(port)
      result = command == "ls" ? "result\n" : ""
      shell_instance = instance_double(Rpremote::Shell, synchronize!: nil, execute: result)
      shell = class_double(Rpremote::Shell, new: shell_instance, quote_argument: "'/home/a b'")
      stub_const("Rpremote::Shell", shell)

      status = described_class.start(
        ["fs", command, ":/home/a b", "--port", "/dev/cu.usbmodem101"],
        stdout: stdout,
        stderr: stderr,
        device: device,
        serial: serial
      )

      expect(status).to eq(0)
      expect(shell).to have_received(:quote_argument).with("/home/a b")
      expect(shell_instance).to have_received(:execute).with("#{command} '/home/a b'")
      expected_output = command == "rm" ? "deleting remote path permanently: /home/a b\n" : result
      expect(stdout.string).to eq(expected_output)
    end
  end

  it "returns a failure status for an R2P2 filesystem error" do
    port = Object.new
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    allow(serial).to receive(:open).and_yield(port)
    shell_instance = instance_double(
      Rpremote::Shell,
      synchronize!: nil,
      execute: "rm: cannot remove '/home/missing': No such file\n"
    )
    shell = class_double(Rpremote::Shell, new: shell_instance, quote_argument: "'/home/missing'")
    shell.as_stubbed_const(transfer_nested_constants: true)

    status = described_class.start(
      ["fs", "rm", ":/home/missing"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(1)
    expect(stderr.string).to include("cannot remove")
  end

  it "reboots R2P2 through the Shell" do
    device = class_double(Rpremote::Device, main_port: "/dev/cu.usbmodem101")
    serial = class_double(Rpremote::Serial)
    resetter_instance = instance_double(Rpremote::Resetter, reset: "/dev/cu.usbmodem101")
    resetter = class_double(Rpremote::Resetter, new: resetter_instance)
    resetter.as_stubbed_const(transfer_nested_constants: true)

    status = described_class.start(
      ["reset", "--port", "/dev/cu.usbmodem101"],
      stdout: stdout,
      stderr: stderr,
      device: device,
      serial: serial
    )

    expect(status).to eq(0)
    expect(resetter).to have_received(:new).with(serial: serial, timeout: 20.0)
    expect(resetter_instance).to have_received(:reset).with("/dev/cu.usbmodem101", baud: 115_200)
    expect(stdout.string).to eq("reset R2P2: /dev/cu.usbmodem101\n")
  end
end
