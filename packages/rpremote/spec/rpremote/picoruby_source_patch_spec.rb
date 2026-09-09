# frozen_string_literal: true

require "tmpdir"

RSpec.describe Rpremote::PicoRubySourcePatch do
  it "leaves a source tree unchanged when the bundled patch is already applied" do
    Dir.mktmpdir do |source|
      job = File.join(source, described_class::JOB_PATH)
      FileUtils.mkdir_p(File.dirname(job))
      File.write(job, "patched")
      patcher = described_class.new(version: "4.0.3")
      expect(patcher).to receive(:system).once.and_return(true)

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
      expect(patcher).to receive(:system).once.and_return(true)

      expect(patcher.apply(source)).to be_nil
    end
  end

  it "keeps the PWM clock running during scheduler sleep on PicoRuby 4.0.3" do
    Dir.mktmpdir do |source|
      pwm = File.join(source, described_class::PWM_PATH)
      FileUtils.mkdir_p(File.dirname(pwm))
      File.write(pwm, <<~C)
        #include "pico/stdlib.h"
        #include "hardware/pwm.h"

        #include "../../include/pwm.h"

        #define APB_CLK_FREQ 125000000
        #define CLK_DIV      100.0

        void
        PWM_init(uint32_t pin)
        {
          gpio_set_function(pin, GPIO_FUNC_PWM);
          uint slice_num = pwm_gpio_to_slice_num(pin);
          pwm_set_clkdiv(slice_num, CLK_DIV);
        }
      C

      patcher = described_class.new(version: "4.0.3")
      expect(patcher.apply(source)).to be_nil
      expect(File.read(pwm)).to include("CLOCKS_SLEEP_EN0_CLK_SYS_PWM_BITS")

      patched = File.read(pwm)
      expect(patcher.apply(source)).to be_nil
      expect(File.read(pwm)).to eq(patched)
    end
  end
end
