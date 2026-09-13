# frozen_string_literal: true

require "picotest"
require "ws2812-plus"

module Kernel
  def sleep_ms(_milliseconds)
  end unless method_defined?(:sleep_ms)
end

require "goryokaku-illumination"
require "goryokaku-illumination/config"
require "goryokaku-illumination/color"
require "goryokaku-illumination/led_layout"
require "goryokaku-illumination/display"
require "goryokaku-illumination/device"
require "goryokaku-illumination/patterns/base"
pattern_dir = File.expand_path("../mrblib/goryokaku-illumination/patterns", __dir__)
Dir.glob("#{pattern_dir}/*.rb").sort.each do |path|
  require path unless File.basename(path) == "base.rb"
end
require "goryokaku-illumination/setlist"
require "goryokaku-illumination/player"
require "goryokaku-illumination/tambourine_player"
require "goryokaku-illumination/interactive_player"

class AddressCheckingDisplay < Goryokaku::Illumination::Display
  attr_reader :invalid_indices

  def initialize(strip)
    super
    @invalid_indices = []
  end

  def set(index, color, level = 1.0)
    if index < 0 || index >= Goryokaku::Illumination::LedLayout::LED_COUNT
      @invalid_indices << index
      return
    end
    super
  end
end

module PatternCapture
  def self.call(key)
    strip = WS2812.new(
      pin: Goryokaku::Illumination::Config::LED_PIN,
      num: Goryokaku::Illumination::LedLayout::LED_COUNT,
      order: Goryokaku::Illumination::Config::LED_ORDER
    )
    display = AddressCheckingDisplay.new(strip)
    klass = Goryokaku::Illumination::Setlist.pattern_class(key)
    klass.new(display, 0, 1).call
    strip.invalid_indices.concat(display.invalid_indices)
    strip
  end
end
