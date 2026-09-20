# frozen_string_literal: true

require "tmpdir"

RSpec.describe "Applying rpremote compatibility patches to PicoRuby" do
  let(:described_class) { Rpremote::PicoRubySourcePatch }

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

  it "keeps the PWM clock running only while a PWM slice is active on PicoRuby 4.0.4" do
    Dir.mktmpdir do |source|
      pwm = File.join(source, described_class::PWM_PATH)
      FileUtils.mkdir_p(File.dirname(pwm))
      File.write(pwm, <<~C)
        #include "pico/stdlib.h"
        #include "hardware/clocks.h"
        #include "hardware/pwm.h"

        #include "../../include/pwm.h"

        void
        PWM_init(uint32_t pin)
        {
          gpio_set_function(pin, GPIO_FUNC_PWM);
        }

        void
        PWM_set_frequency_and_duty(uint32_t pin, picorb_float_t frequency, picorb_float_t duty_cycle)
        {
          uint slice_num = pwm_gpio_to_slice_num(pin);
          uint channel = pwm_gpio_to_channel(pin);
          float sys_clk = (float)clock_get_hz(clk_sys);
          float div = sys_clk / ((float)frequency * 65536.0f);
          uint16_t wrap = (uint16_t)(sys_clk / (div * (float)frequency));
          pwm_set_clkdiv(slice_num, div);
          pwm_set_wrap(slice_num, wrap);
          uint16_t duty = (uint16_t)((float)wrap * (float)duty_cycle / 100.0f);
          pwm_set_chan_level(slice_num, channel, duty);
        }

        void
        PWM_set_enabled(uint32_t pin, bool enabled)
        {
          uint slice_num = pwm_gpio_to_slice_num(pin);
          pwm_set_enabled(slice_num, enabled);
        }
      C

      patcher = described_class.new(version: "4.0.4")
      expect(patcher.apply(source)).to be_nil

      patched = File.read(pwm)
      expect(patched).to include("CLOCKS_SLEEP_EN0_CLK_SYS_PWM_BITS")
      expect(patched).to include("!enabled && pwm_hw->en == 0")
      expect(patched.index("hw_set_bits")).to be < patched.index("pwm_set_enabled")
      expect(patched.index("pwm_set_enabled")).to be < patched.index("hw_clear_bits")

      expect(patcher.apply(source)).to be_nil
      expect(File.read(pwm)).to eq(patched)
    end
  end
end
