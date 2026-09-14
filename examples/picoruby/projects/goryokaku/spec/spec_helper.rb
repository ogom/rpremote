# frozen_string_literal: true

GORYOKAKU_ROOT = File.expand_path("..", __dir__)
GORYOKAKU_MRBGEMS = File.join(GORYOKAKU_ROOT, "mrbgems")

%w[
  goryokaku-runtime
  goryokaku-illumination
  goryokaku-musical
  goryokaku-interaction
  goryokaku-application
].each do |gem_name|
  $LOAD_PATH.unshift(File.join(GORYOKAKU_MRBGEMS, gem_name, "mrblib"))
end
$LOAD_PATH.unshift(File.join(GORYOKAKU_MRBGEMS, "goryokaku-illumination", "test", "mock"))
$LOAD_PATH.unshift(File.join(GORYOKAKU_MRBGEMS, "goryokaku-musical", "test", "mock"))

require "ws2812-plus"
require "pwm"

module Kernel
  def sleep_ms(_milliseconds); end unless method_defined?(:sleep_ms)
end

require "goryokaku-runtime"
require "goryokaku-runtime/event_loop"

require "goryokaku-illumination"
require "goryokaku-illumination/config"
require "goryokaku-illumination/color"
require "goryokaku-illumination/led_layout"
require "goryokaku-illumination/display"
require "goryokaku-illumination/device"
require "goryokaku-illumination/patterns/base"
Dir[File.join(GORYOKAKU_MRBGEMS, "goryokaku-illumination", "mrblib", "goryokaku-illumination", "patterns", "*.rb")].each do |path|
  require path unless File.basename(path) == "base.rb"
end
require "goryokaku-illumination/setlist"
require "goryokaku-illumination/player"
require "goryokaku-illumination/tambourine_player"
require "goryokaku-illumination/interactive_player"

require "goryokaku-musical"
require "goryokaku-musical/cues"
require "goryokaku-musical/outputs/base"
require "goryokaku-musical/outputs/null"
require "goryokaku-musical/outputs/pwm"
require "goryokaku-musical/tambourine_detector"
require "goryokaku-musical/gesture_publisher"
require "goryokaku-musical/subscriber"
require "goryokaku-musical/buzzer"
require "goryokaku-musical/illumination_soundtrack"

require "goryokaku-interaction"
require "goryokaku-interaction/dispatcher"
require "goryokaku-interaction/detector"
require "goryokaku-interaction/device"
require "goryokaku-interaction/runner"

require "goryokaku-application"
require "goryokaku-application/config"
require "goryokaku-application/validator"
require "goryokaku-application/composition"
require "goryokaku-application/runner"

module GoryokakuSpec
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

  class Output
    attr_reader :events

    def initialize
      @events = []
    end

    def start
      @events << [:start]
      self
    end

    def play(frequency, volume)
      @events << [:play, frequency, volume]
    end

    def stop
      @events << [:stop]
    end
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.order = :random
end
