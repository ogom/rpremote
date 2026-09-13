# frozen_string_literal: true

require_relative "test_helper"

class RecordingGoryokakuPlayerLogger
  attr_reader :lines

  def initialize
    @lines = []
  end

  def puts(message)
    @lines << message
  end
end

class RecordingGoryokakuSoundtrack
  attr_reader :events, :waits

  def initialize; @events = []; @waits = []; end
  def start(repeat: false); @events << [:start, repeat]; end
  def join; @events << [:join]; end
  def stop; @events << [:stop]; end
  def wait_ms(milliseconds); @waits << milliseconds; end
end

class GoryokakuIlluminationPlayerTest < Picotest::Test
  def test_resolves_named_setlists
    entry = Goryokaku::Illumination::Setlist.resolve(:tests)[0]
    assert_equal :warm_white, Goryokaku::Illumination::Setlist.key(entry)
    assert_equal :warm_white, Goryokaku::Illumination::Setlist.key(Goryokaku::Illumination::Setlist.resolve(:story)[0])
    assert_equal 21, Goryokaku::Illumination::Setlist.resolve(:showcase).length
    assert Goryokaku::Illumination::Setlist.valid_key?(:fireworks)
    assert_equal false, Goryokaku::Illumination::Setlist.valid_key?(:unknown)
  end

  def test_maps_every_key_to_a_pattern_class
    Goryokaku::Illumination::Setlist::PATTERNS.each do |pattern|
      key = pattern[Goryokaku::Illumination::Setlist::KEY]
      assert Goryokaku::Illumination::Setlist.pattern_class(key)
    end
  end

  def test_plays_a_pattern_through_device_and_turns_leds_off
    strip = WS2812.new(pin: 22, num: 380)
    logger = RecordingGoryokakuPlayerLogger.new
    player = Goryokaku::Illumination::Player.new(strip: strip, logger: logger)

    player.play_pattern(:warm_white)

    assert_equal 380, strip.pixels.count { |pixel| pixel == 0 }
    assert strip.closed
    assert_equal "GORYOKAKU mode=illumination event=pattern index=1/1 key=warm_white wait_ms=35 loops=1", logger.lines[0]
    assert_equal "GORYOKAKU mode=illumination event=led_off", logger.lines[1]
  end

  def test_rejects_unknown_patterns
    assert_raise(ArgumentError) { Goryokaku::Illumination::Player.new.play_pattern(:unknown) }
  end

  def test_plays_and_cleans_up_the_soundtrack_with_a_pattern
    strip = WS2812.new(pin: 22, num: 380)
    soundtrack = RecordingGoryokakuSoundtrack.new
    player = Goryokaku::Illumination::Player.new(strip: strip, soundtrack: soundtrack)

    player.play_pattern(:warm_white)

    assert_equal [[:start, false], [:join], [:stop]], soundtrack.events
    assert soundtrack.waits.length > 0
  end
end
