# frozen_string_literal: true

RSpec.describe Rpremote::Runner do
  let(:io) { Object.new }
  let(:modem) { instance_double(Rpremote::PicoModem) }
  let(:modem_class) { class_double(Rpremote::PicoModem, new: modem) }
  let(:shell) { instance_double(Rpremote::Shell) }
  let(:shell_class) { class_double(Rpremote::Shell, new: shell) }
  let(:remote_path) { "/home/.rpremote-run-test.rb" }

  it "uploads, executes, and removes a temporary Ruby file" do
    events = []
    allow(modem).to receive(:upload)
    allow(shell).to receive(:synchronize!) { events << :synchronize }
    allow(shell).to receive(:execute).with("./.rpremote-run-test.rb", idle_timeout: true) do
      events << :run
      "result\n"
    end
    allow(shell).to receive(:execute).with("rm #{remote_path}") do
      events << :cleanup
      ""
    end

    output = described_class.new(
      io,
      timeout: 2.0,
      modem_class: modem_class,
      shell_class: shell_class,
      path_factory: -> { remote_path }
    ).run("puts :result\n")

    expect(output).to eq("result\n")
    expect(modem_class).to have_received(:new).with(io, timeout: 2.0)
    expect(modem).to have_received(:upload).with(remote_path, "puts :result\n")
    expect(events).to eq(%i[synchronize synchronize run cleanup])
  end

  it "reports each run stage when diagnostics are enabled" do
    diagnostics = StringIO.new
    allow(modem).to receive(:upload)
    allow(shell).to receive(:synchronize!)
    allow(shell).to receive(:execute).with("./.rpremote-run-test.rb", idle_timeout: true).and_return("result\n")
    allow(shell).to receive(:execute).with("rm #{remote_path}").and_return("")

    described_class.new(
      io,
      modem_class: modem_class,
      shell_class: shell_class,
      path_factory: -> { remote_path }
    ).run("puts :result\n", diagnostics: diagnostics)

    expect(diagnostics.string).to include(
      "event=SYNC_BEFORE_UPLOAD_START",
      "event=UPLOAD_START,bytes=13,path=#{remote_path}",
      "event=EXECUTE_START,command=./.rpremote-run-test.rb",
      "event=EXECUTE_DONE,bytes=7",
      "event=CLEANUP_DONE"
    )
  end

  it "reuses one remote path so failed cleanup cannot fill the device" do
    default_path = described_class::RUN_REMOTE_PATH
    allow(modem).to receive(:upload)
    allow(shell_class).to receive(:new).with(io, timeout: Rpremote::Shell::DEFAULT_TIMEOUT).and_return(shell)
    allow(shell).to receive(:synchronize!)
    allow(shell).to receive(:execute).with("./#{File.basename(default_path)}", idle_timeout: true).and_return("")
    allow(shell).to receive(:execute).with("rm #{default_path}").and_return("")

    described_class.new(io, modem_class: modem_class, shell_class: shell_class).run("puts :result\n")

    expect(modem).to have_received(:upload).with(default_path, "puts :result\n")
  end

  it "still removes the temporary file when execution fails" do
    allow(modem).to receive(:upload)
    allow(shell).to receive(:synchronize!)
    allow(shell).to receive(:execute).with("./.rpremote-run-test.rb", idle_timeout: true)
                                     .and_raise(Rpremote::Shell::TimeoutError, "timeout")
    allow(shell).to receive(:execute).with("rm #{remote_path}").and_return("")

    runner = described_class.new(
      io,
      modem_class: modem_class,
      shell_class: shell_class,
      path_factory: -> { remote_path }
    )

    expect { runner.run("loop {}") }.to raise_error(Rpremote::Shell::TimeoutError)
    expect(shell).to have_received(:execute).with("rm #{remote_path}")
  end

  it "keeps a deployment script and its Shell job alive when cleanup is disabled" do
    allow(modem).to receive(:upload)
    allow(shell).to receive(:synchronize!)
    allow(shell).to receive(:execute).with("./.rpremote-deploy.rb", idle_timeout: true).and_return("")

    described_class.new(
      io, modem_class: modem_class, shell_class: shell_class
    ).run("puts :deployed\n", cleanup: false, remote_path: described_class::DEPLOY_REMOTE_PATH)

    expect(modem).to have_received(:upload).with(described_class::DEPLOY_REMOTE_PATH, "puts :deployed\n")
    expect(shell).not_to have_received(:execute).with("rm #{described_class::DEPLOY_REMOTE_PATH}")
  end

  it "does not send a cleanup command before Shell synchronization" do
    allow(modem).to receive(:upload)
    allow(shell).to receive(:synchronize!).and_raise(Rpremote::Shell::TimeoutError, "timeout")
    allow(shell).to receive(:execute)

    runner = described_class.new(
      io,
      modem_class: modem_class,
      shell_class: shell_class,
      path_factory: -> { remote_path }
    )

    expect { runner.run("puts :never") }.to raise_error(Rpremote::Shell::TimeoutError)
    expect(modem).not_to have_received(:upload)
    expect(shell).not_to have_received(:execute)
  end
end
