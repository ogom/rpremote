# frozen_string_literal: true

require "rpremote/help"

RSpec.describe "Reading current command syntax and operational effects" do
  it "uses the same syntax definition in root and command-specific help" do
    usage = Rpremote::Help::COMMAND_USAGE.fetch(:run)

    expect(Rpremote::Help::TEXT).to include(usage)
    expect(Rpremote::Help.command_text("run", [])).to include("Usage: #{usage}")
  end

  it "publishes every supported command syntax in root help" do
    usages = Rpremote::Help::COMMAND_USAGE.map do |name, usage|
      name == :mrbgems ? usage.sub("SUBCOMMAND", "check|list|lock|update") : usage
    end

    expect(usages).to all(satisfy { |usage| Rpremote::Help::TEXT.include?(usage) })
  end

  it "explains the complete deploy order and when firmware is built" do
    help = Rpremote::Help.command_text("deploy", [])

    expect(help).to include("flashes the existing selected UF2")
    expect(help).to include("With --build, builds the selected custom UF2")
    expect(help).to include("If PATH/lib/NAME exists, it copies it to :/lib/NAME")
    expect(help).to include("stages run in order and stop at the first failure")
  end

  it "warns that a flash replaces persistent board firmware" do
    expect(Rpremote::Help.command_text("flash", [])).to include("replaces persistent board firmware")
  end

  it "warns that resetting flash memory erases the entire external flash" do
    help = Rpremote::Help.command_text("bootsel", [])

    expect(help).to include("erases all external flash memory")
    expect(help).to include("run `rpremote flash` to install R2P2 again")
  end

  it "warns that removing DFU applications permanently clears both slots" do
    help = Rpremote::Help.command_text("dfu", ["remove"])

    expect(help).to include("Permanently removes")
    expect(help).to include("both DFU A/B slots")
    expect(help).to include("Run `rpremote reset` afterward")
  end

  it "marks remote file deletion as permanent" do
    expect(Rpremote::Help.command_text("fs", ["rm"])).to include("Deletes the remote path permanently")
  end
end
