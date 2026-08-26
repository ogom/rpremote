# frozen_string_literal: true

require "stringio"

class TerminalScriptedIO
  attr_reader :written, :flush_count, :raw_count

  def initialize(*chunks, tty: false)
    @chunks = chunks
    @tty = tty
    @written = +"".b
    @flush_count = 0
    @raw_count = 0
  end

  def read_nonblock(_length)
    @chunks.shift || raise(EOFError)
  end

  def write(data)
    written << data
    data.bytesize
  end

  def flush
    @flush_count += 1
  end

  def tty?
    @tty
  end

  def raw
    @raw_count += 1
    yield
  end

  def to_io
    self
  end
end

RSpec.describe Rpremote::Terminal do
  it "relays serial output and keyboard input until Ctrl-]" do
    serial = TerminalScriptedIO.new("device output\n")
    input = TerminalScriptedIO.new("puts 1\r", "more\x1dignored".b)
    output = StringIO.new
    schedule = [[serial], [input], [input]]
    selector = lambda do |_readers|
      ready = schedule.shift
      ready && [ready, [], []]
    end

    described_class.new(serial, input: input, output: output, selector: selector).run

    expect(output.string).to eq("device output\r\n")
    expect(serial.written).to eq("puts 1\rmore")
  end

  it "normalizes bare LF while preserving CRLF across serial read chunks" do
    serial = TerminalScriptedIO.new("first\nsecond\r", "\nthird\n")
    input = TerminalScriptedIO.new("\x1d".b)
    output = StringIO.new
    schedule = [[serial], [serial], [input]]
    selector = lambda do |_readers|
      ready = schedule.shift
      ready && [ready, [], []]
    end

    described_class.new(serial, input: input, output: output, selector: selector).run

    expect(output.string).to eq("first\r\nsecond\r\nthird\r\n")
  end

  it "restores a TTY raw mode and sends the REPL exit sequence" do
    serial = TerminalScriptedIO.new
    input = TerminalScriptedIO.new("\x1d".b, tty: true)
    selector = ->(_readers) { [[input], [], []] }

    described_class.new(serial, input: input, output: StringIO.new, selector: selector)
                   .run(exit_sequence: "\x03\x04".b)

    expect(input.raw_count).to eq(1)
    expect(serial.written).to eq("\x03\x04".b)
    expect(serial.flush_count).to eq(1)
  end
end
