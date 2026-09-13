# frozen_string_literal: true

DAISENKOFUN_ROOT = File.expand_path("..", __dir__)
DAISENKOFUN_MRBGEMS = File.join(DAISENKOFUN_ROOT, "mrbgems")

%w[
  daisenkofun-runtime
  daisenkofun-illumination
  daisenkofun-musical
  daisenkofun-oximeter
  daisenkofun-application
].each do |gem_name|
  $LOAD_PATH.unshift(File.join(DAISENKOFUN_MRBGEMS, gem_name, "mrblib"))
end
$LOAD_PATH.unshift(File.join(DAISENKOFUN_MRBGEMS, "daisenkofun-illumination", "test", "mock"))

require "ws2812-plus"

module Kernel
  def sleep_ms(_milliseconds); end unless method_defined?(:sleep_ms)
end

require "daisenkofun-runtime"
require "daisenkofun-runtime/event_loop"

require "daisenkofun-illumination"
require "daisenkofun-illumination/config"
require "daisenkofun-illumination/color"
require "daisenkofun-illumination/led_layout"
require "daisenkofun-illumination/display"
require "daisenkofun-illumination/device"
require "daisenkofun-illumination/patterns/base"
Dir[File.join(DAISENKOFUN_MRBGEMS, "daisenkofun-illumination", "mrblib", "daisenkofun-illumination", "patterns", "*.rb")].each do |path|
  require path unless File.basename(path) == "base.rb"
end
require "daisenkofun-illumination/biometrics/base"
require "daisenkofun-illumination/biometrics/beat_pulse"
require "daisenkofun-illumination/biometrics/moat_canon"
require "daisenkofun-illumination/setlist"
require "daisenkofun-illumination/player"
require "daisenkofun-illumination/biometric_player"

require "daisenkofun-musical"
require "daisenkofun-musical/translators/pulse"
require "daisenkofun-musical/translators/timbre"
require "daisenkofun-musical/planners/kofun_canon"
require "daisenkofun-musical/planners/heartbeat_signature"
require "daisenkofun-musical/performance_verification"
require "daisenkofun-musical/outputs/base"
require "daisenkofun-musical/outputs/null"
require "daisenkofun-musical/outputs/pwm"
require "daisenkofun-musical/outputs/kofun_canon"
require "daisenkofun-musical/subscriber"

require "daisenkofun-oximeter"
require "daisenkofun-oximeter/config"
require "daisenkofun-oximeter/dispatcher"
require "daisenkofun-oximeter/measurement/events"
require "daisenkofun-oximeter/measurement/rolling_sample_window"
require "daisenkofun-oximeter/measurement/finger_detector"
require "daisenkofun-oximeter/measurement/beat_detector"
require "daisenkofun-oximeter/measurement/pulse_shape_extractor"
require "daisenkofun-oximeter/measurement/spo2_estimator"
require "daisenkofun-oximeter/measurement/session"
require "daisenkofun-oximeter/measurement/processor"
require "daisenkofun-oximeter/status_led/states"
require "daisenkofun-oximeter/status_led/renderer"
require "daisenkofun-oximeter/status_led/null_renderer"
require "daisenkofun-oximeter/status_led/presenter"

require "daisenkofun-application"
require "daisenkofun-application/config"
require "daisenkofun-application/validator"
require "daisenkofun-application/musical_factory"
require "daisenkofun-application/composition"
require "daisenkofun-application/verification_reporter"
require "daisenkofun-application/runner"

module DaisenkofunSpec
  class Clock
    attr_accessor :now
    attr_reader :waits

    def initialize(now = 0)
      @now = now
      @waits = []
    end

    def millis
      @now
    end

    def wait_ms(milliseconds)
      @waits << milliseconds
      @now += milliseconds
    end
  end

  class Logger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def puts(message)
      @messages << message
    end
  end

  class PWM
    attr_reader :notes, :last_duty

    def initialize(clock)
      @clock = clock
      @notes = []
    end

    def frequency(value)
      @frequency = value
    end

    def duty(value)
      @last_duty = value
      @notes << [@clock.millis, @frequency, value] if value.positive?
    end
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.order = :random
end
