# frozen_string_literal: true

require "picotest"
require "ws2812-plus"

module Kernel
  def sleep_ms(_milliseconds)
  end unless method_defined?(:sleep_ms)
end

require "daisenkofun-illumination"
require "daisenkofun-illumination/config"
require "daisenkofun-illumination/color"
require "daisenkofun-illumination/led_layout"
require "daisenkofun-illumination/display"
require "daisenkofun-illumination/device"
require "daisenkofun-illumination/patterns/base"

pattern_dir = File.expand_path("../mrblib/daisenkofun-illumination/patterns", __dir__)
Dir.glob("#{pattern_dir}/*.rb").sort.each do |path|
  require path unless File.basename(path) == "base.rb"
end

biometric_dir = File.expand_path("../mrblib/daisenkofun-illumination/biometrics", __dir__)
require "daisenkofun-illumination/biometrics/base"
Dir.glob("#{biometric_dir}/*.rb").sort.each do |path|
  require path unless File.basename(path) == "base.rb"
end

require "daisenkofun-illumination/setlist"
require "daisenkofun-illumination/player"
require "daisenkofun-illumination/biometric_player"

class AddressCheckingDisplay < Daisenkofun::Illumination::Display
  attr_reader :invalid_indices

  def initialize(strip)
    super
    @invalid_indices = []
  end

  def set(index, color, level = 1.0)
    if index < 0 || index >= Daisenkofun::Illumination::LedLayout::LED_COUNT
      @invalid_indices << index
      return
    end

    super
  end
end

module PatternCapture
  def self.call(key)
    strip = WS2812.new(
      pin: Daisenkofun::Illumination::Config::LED_PIN,
      num: Daisenkofun::Illumination::LedLayout::LED_COUNT,
      order: Daisenkofun::Illumination::Config::LED_ORDER
    )
    strip.brightness = Daisenkofun::Illumination::Config::BRIGHTNESS_PERCENT
    klass = Daisenkofun::Illumination::Setlist.pattern_class(key)
    display = AddressCheckingDisplay.new(strip)
    klass.new(display, 0, 1).call
    strip.invalid_indices.concat(display.invalid_indices)
    strip
  end
end
