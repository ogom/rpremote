# frozen_string_literal: true

require "picotest"
require "pwm"

module Kernel
  def sleep_ms(_milliseconds)
  end unless method_defined?(:sleep_ms)
end

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
