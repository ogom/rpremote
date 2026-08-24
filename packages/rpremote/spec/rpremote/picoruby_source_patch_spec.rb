# frozen_string_literal: true

require "tmpdir"

RSpec.describe Rpremote::PicoRubySourcePatch do
  it "leaves a source tree unchanged when the bundled patch is already applied" do
    Dir.mktmpdir do |source|
      job = File.join(source, described_class::JOB_PATH)
      FileUtils.mkdir_p(File.dirname(job))
      File.write(job, "patched")
      patcher = described_class.new(version: "4.0.3")
      patch = File.expand_path("../../patches/picoruby-4.0.3-ruby-exception-status.patch", __dir__)
      expect(patcher).to receive(:system).with(
        "git", "apply", "--reverse", "--check", patch, chdir: source, out: File::NULL, err: File::NULL
      ).and_return(true)

      expect(patcher.apply(source)).to be_nil
    end
  end

  it "checks and applies the bundled patch to an unpatched source tree" do
    Dir.mktmpdir do |source|
      job = File.join(source, described_class::JOB_PATH)
      FileUtils.mkdir_p(File.dirname(job))
      File.write(job, "unpatched")
      patcher = described_class.new(version: "4.0.3")
      allow(patcher).to receive(:system).and_return(false, true, true)

      expect(patcher.apply(source)).to be_nil
      expect(patcher).to have_received(:system).exactly(3).times
    end
  end

  it "does nothing when no patch is bundled for the PicoRuby version" do
    patcher = described_class.new(version: "9.9.9")
    expect(patcher).not_to receive(:system)

    expect(patcher.apply("/missing")).to be_nil
  end

  it "uses the compatible 3.4 patch for PicoRuby 3.4.2" do
    Dir.mktmpdir do |source|
      job = File.join(source, described_class::JOB_PATH)
      FileUtils.mkdir_p(File.dirname(job))
      File.write(job, "patched")
      patcher = described_class.new(version: "3.4.2")
      patch = File.expand_path("../../patches/picoruby-3.4.5-ruby-exception-status.patch", __dir__)
      expect(patcher).to receive(:system).with(
        "git", "apply", "--reverse", "--check", patch, chdir: source, out: File::NULL, err: File::NULL
      ).and_return(true)

      expect(patcher.apply(source)).to be_nil
    end
  end
end
