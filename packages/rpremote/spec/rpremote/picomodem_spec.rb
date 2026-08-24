# frozen_string_literal: true

class PicoModemScriptedIO
  attr_reader :written

  def initialize(readable = +"".b)
    @readable = readable
    @written = +"".b
  end

  def read_nonblock(length)
    raise IO::EAGAINWaitReadable if @readable.empty?

    @readable.slice!(0, length)
  end

  def write(data)
    @written << data
    data.bytesize
  end

  def flush; end
end

RSpec.describe Rpremote::PicoModem do
  def frame(command, payload = +"".b)
    body = [command].pack("C") + payload
    [described_class::STX, body.bytesize].pack("Cn") + body +
      [Rpremote::Checksum.crc16(body)].pack("n")
  end

  def parse_frames(bytes)
    frames = []
    offset = 1 # The initial byte enters PicoModem mode.
    while offset < bytes.bytesize
      expect(bytes.getbyte(offset)).to eq(described_class::STX)
      length = bytes.byteslice(offset + 1, 2).unpack1("n")
      body = bytes.byteslice(offset + 3, length)
      frames << [body.getbyte(0), body.byteslice(1..) || +"".b]
      offset += 3 + length + 2
    end
    frames
  end

  it "builds and receives a frame compatible with R2P2" do
    bytes = frame(described_class::FILE_READ, "/home/test.rb")
    command, payload = described_class.new(PicoModemScriptedIO.new(bytes)).receive_frame

    expect(command).to eq(described_class::FILE_READ)
    expect(payload).to eq("/home/test.rb")
  end

  it "uploads data in 480-byte chunks and verifies CRC32" do
    data = (0..255).to_a.pack("C*") * 2
    responses = [described_class::ACK].pack("C") +
                frame(described_class::FILE_ACK, [described_class::READY].pack("C")) +
                frame(described_class::CHUNK_ACK, [described_class::OK].pack("C")) +
                frame(described_class::CHUNK_ACK, [described_class::OK].pack("C")) +
                frame(
                  described_class::DONE_ACK,
                  [described_class::OK, Rpremote::Checksum.crc32(data)].pack("CN")
                )
    io = PicoModemScriptedIO.new(responses)

    expect(described_class.new(io).upload("/home/test.bin", data)).to eq(512)
    frames = parse_frames(io.written)
    expect(frames.map(&:first)).to eq(
      [described_class::FILE_WRITE, described_class::CHUNK, described_class::CHUNK]
    )
    expect(frames[1][1].bytesize).to eq(480)
    expect(frames[2][1].bytesize).to eq(32)
  end

  it "uploads an empty file without a data chunk" do
    responses = [described_class::ACK].pack("C") +
                frame(described_class::FILE_ACK, [described_class::READY].pack("C")) +
                frame(described_class::DONE_ACK, [described_class::OK, 0].pack("CN"))
    io = PicoModemScriptedIO.new(responses)

    expect(described_class.new(io).upload("/home/empty", +"".b)).to eq(0)
    expect(parse_frames(io.written).map(&:first)).to eq([described_class::FILE_WRITE])
  end

  it "sends a CRC-checked DFU app in PicoModem chunks" do
    data = "d" * 481
    responses = [described_class::ACK].pack("C") +
                frame(described_class::DFU_ACK, [described_class::READY].pack("C")) +
                frame(described_class::CHUNK_ACK, [described_class::OK].pack("C")) +
                frame(described_class::CHUNK_ACK, [described_class::OK].pack("C")) +
                frame(described_class::DONE_ACK, [described_class::OK].pack("C"))
    io = PicoModemScriptedIO.new(responses)

    expect(described_class.new(io).dfu(data, type: "RUBY")).to eq(481)

    frames = parse_frames(io.written)
    expect(frames.map(&:first)).to eq(
      [described_class::DFU_START, described_class::CHUNK, described_class::CHUNK]
    )
    magic, version, type, size, crc32, signature_size = frames.first.last.unpack("a4Ca4NNn")
    expect([magic, version, type, size, crc32, signature_size]).to eq(
      ["DFU\0", 1, "RUBY", 481, Rpremote::Checksum.crc32(data), 0]
    )
    expect(frames[1][1].bytesize).to eq(480)
    expect(frames[2][1].bytesize).to eq(1)
  end

  it "downloads multiple chunks and acknowledges each one" do
    data = "a" * 481
    responses = [described_class::ACK].pack("C") +
                frame(described_class::FILE_DATA, [data.bytesize].pack("N") + data.byteslice(0, 480)) +
                frame(described_class::FILE_DATA, data.byteslice(480, 1)) +
                frame(
                  described_class::DONE_ACK,
                  [described_class::OK, Rpremote::Checksum.crc32(data)].pack("CN")
                )
    io = PicoModemScriptedIO.new(responses)

    expect(described_class.new(io).download("/home/test.rb")).to eq(data)
    expect(parse_frames(io.written).map(&:first)).to eq(
      [described_class::FILE_READ, described_class::CHUNK_ACK, described_class::CHUNK_ACK]
    )
  end

  it "rejects a frame with a corrupt CRC16" do
    corrupt = frame(described_class::FILE_READ, "/home/test.rb")
    corrupt.setbyte(-1, corrupt.getbyte(-1) ^ 0xFF)

    expect { described_class.new(PicoModemScriptedIO.new(corrupt)).receive_frame }
      .to raise_error(described_class::ChecksumError, /CRC16 mismatch/)
  end

  it "aborts a transfer when the file CRC32 does not match" do
    data = "bad crc"
    responses = [described_class::ACK].pack("C") +
                frame(described_class::FILE_DATA, [data.bytesize].pack("N") + data) +
                frame(described_class::DONE_ACK, [described_class::OK, 123].pack("CN"))
    io = PicoModemScriptedIO.new(responses)

    expect { described_class.new(io).download("/home/test.rb") }
      .to raise_error(described_class::ChecksumError, /CRC32 mismatch/)
    expect(parse_frames(io.written).last.first).to eq(described_class::ABORT)
  end

  it "rejects unsafe remote paths before entering PicoModem mode" do
    io = PicoModemScriptedIO.new

    expect { described_class.new(io).download("/home/../etc/passwd") }
      .to raise_error(ArgumentError, /must not contain/)
    expect(io.written).to be_empty
  end

  it "times out while waiting for a frame" do
    reader, writer = IO.pipe

    expect { described_class.new(reader, timeout: 0.001).receive_frame }
      .to raise_error(described_class::TimeoutError, /timed out/)
  ensure
    reader&.close
    writer&.close
  end

  it "reports a disconnected serial stream" do
    reader, writer = IO.pipe
    writer.close

    expect { described_class.new(reader).receive_frame }
      .to raise_error(IOError, /connection closed/)
  ensure
    reader&.close
    writer&.close unless writer&.closed?
  end

  it "rejects an empty frame body" do
    io = PicoModemScriptedIO.new([described_class::STX, 0].pack("Cn"))

    expect { described_class.new(io).receive_frame }
      .to raise_error(described_class::ProtocolError, /empty frame/)
  end
end
