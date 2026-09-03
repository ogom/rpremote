# frozen_string_literal: true

require "picotest"
require "ws2812-plus"

module Kernel
  def sleep_ms(_milliseconds)
  end unless method_defined?(:sleep_ms)
end

require "daisenkofun/config"
require "daisenkofun/color"
require "daisenkofun/led_layout"
require "daisenkofun/display"
require "daisenkofun/illuminations/base"

pattern_dir = File.expand_path("../mrblib/daisenkofun/illuminations", __dir__)
Dir.glob("#{pattern_dir}/*.rb").sort.each do |path|
  require path unless File.basename(path) == "base.rb"
end

require "daisenkofun/setlist"
require "daisenkofun/illumination"
require "daisenkofun/beat_illumination"

class AddressCheckingDisplay < Daisenkofun::Display
  attr_reader :invalid_indices

  def initialize(strip)
    super
    @invalid_indices = []
  end

  def set(index, color, level = 1.0)
    if index < 0 || index >= Daisenkofun::LedLayout::LED_COUNT
      @invalid_indices << index
      return
    end

    super
  end
end

module PatternCapture
  def self.call(key)
    strip = WS2812.new(
      pin: Daisenkofun::Config::LED_PIN,
      num: Daisenkofun::LedLayout::LED_COUNT,
      order: Daisenkofun::Config::LED_ORDER
    )
    strip.brightness = Daisenkofun::Config::BRIGHTNESS_PERCENT
    klass = Daisenkofun::Setlist.pattern_class(key)
    display = AddressCheckingDisplay.new(strip)
    klass.new(display, 0, 1).call
    strip.invalid_indices.concat(display.invalid_indices)
    strip
  end
end
