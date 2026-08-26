# frozen_string_literal: true

require "stringio"

class ShellScriptedIO
  attr_reader :written

  def initialize(*responses, readable: true)
    @responses = responses
    @readable = readable
    @written = +"".b
  end

  def write(data)
    written << data
    data.bytesize
  end

  def flush; end

  def read_nonblock(_length)
    @responses.shift || raise(IO::WaitReadable)
  end

  def wait_readable(_timeout)
    @readable && !@responses.empty?
  end

  def to_io
    self
  end
end

RSpec.describe Rpremote::Shell do
  def shell_response(command, output)
    described_class::ECHO_START + command + described_class::ERASE_LINE +
      "\e[0J\e[1F\e[1B\e[20C\e[?25h\n".b + output.b +
      described_class::PROMPT_START + "\e[0J\e[1F\e[1B\e[3C".b + described_class::PROMPT_END
  end

  it "returns program output without line-editor control sequences" do
    command = "./.rpremote-run.rb"
    stale_prompt = described_class::PROMPT_START + described_class::PROMPT_END
    io = ShellScriptedIO.new(stale_prompt + shell_response(command, "hello\n"))

    output = described_class.new(io).execute(command)

    expect(output).to eq("hello\n")
    expect(io.written).to eq("#{command}\r")
  end

  it "returns binary output unchanged" do
    command = "./binary.rb"
    io = ShellScriptedIO.new(shell_response(command, "\x00\xff\n".b))

    expect(described_class.new(io).execute(command)).to eq("\x00\xff\n".b)
  end

  it "relays complete output lines before the prompt returns" do
    command = "./stream.rb"
    command_boundary = described_class::ECHO_START + command + described_class::ERASE_LINE + "\n".b
    io = ShellScriptedIO.new(command_boundary, "first\n", "second\n", described_class::PROMPT_START + described_class::PROMPT_END)
    output = StringIO.new

    result = described_class.new(io).execute(command, output: output)

    expect(result).to eq("first\nsecond\n")
    expect(output.string).to eq("first\nsecond\n")
  end

  it "treats the execution timeout as an idle timeout when requested" do
    command = "./progress.rb"
    command_boundary = described_class::ECHO_START + command + described_class::ERASE_LINE + "\n".b
    io = ShellScriptedIO.new(
      command_boundary,
      "first\n",
      "second\n",
      described_class::PROMPT_START + described_class::PROMPT_END
    )
    now = 0.0
    allow(io).to receive(:wait_readable) do |_remaining|
      now += 0.0008
      true
    end

    result = described_class.new(io, timeout: 0.001, clock: -> { now })
                            .execute(command, idle_timeout: true)

    expect(result).to eq("first\nsecond\n")
  end

  it "raises a command error when R2P2 reports a Ruby exception" do
    command = "./broken.rb"
    exception_output = "undefined local variable or method 'missing' (NameError)\n"
    response = shell_response(command, exception_output + described_class::RUBY_EXCEPTION_STATUS)
    io = ShellScriptedIO.new(response)
    output = StringIO.new

    expect { described_class.new(io).execute(command, output: output) }
      .to raise_error(described_class::CommandError, "Ruby exception reported by R2P2")
    expect(output.string).to eq(exception_output)
    expect(output.string).not_to include(described_class::RUBY_EXCEPTION_STATUS)
  end

  it "does not infer an exception from ordinary program text" do
    command = "./message.rb"
    message = "undefined local variable or method 'missing' (NameError)\n"
    io = ShellScriptedIO.new(shell_response(command, message))

    expect(described_class.new(io).execute(command)).to eq(message)
  end

  it "answers terminal cursor queries while waiting for the Shell" do
    command = "./query.rb"
    response = shell_response(command, "ok\n").gsub("\e[1G", "\e[1G\e[6n")
    io = ShellScriptedIO.new(response)

    expect(described_class.new(io).execute(command)).to eq("ok\n")
    expect(io.written).to eq("#{command}\r#{described_class::CURSOR_POSITION_RESPONSE * 2}")
  end

  it "interrupts the shell when execution times out" do
    io = ShellScriptedIO.new(readable: false)

    expect { described_class.new(io, timeout: 0.001).execute("./slow.rb") }
      .to raise_error(described_class::TimeoutError)
    expect(io.written).to eq("./slow.rb\r\x03")
  end

  it "rejects commands containing a newline" do
    io = ShellScriptedIO.new

    expect { described_class.new(io).execute("echo safe\nrm file") }
      .to raise_error(ArgumentError, /control character/)
    expect(io.written).to be_empty
  end

  describe ".quote_argument" do
    it "quotes spaces and shell metacharacters as one argument" do
      expect(described_class.quote_argument("/home/a b;file.rb")).to eq("'/home/a b;file.rb'")
    end

    it "uses double quotes when the argument contains a single quote" do
      expect(described_class.quote_argument("/home/it's.rb")).to eq(%q("/home/it's.rb"))
    end

    it "rejects arguments that cannot be represented by the R2P2 parser" do
      expect { described_class.quote_argument(%q(/home/a'"b)) }.to raise_error(ArgumentError, /both quote/)
      expect { described_class.quote_argument("/home/a\n") }.to raise_error(ArgumentError, /control/)
    end
  end
end
