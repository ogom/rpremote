# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunFailingIllumination < Daisenkofun::Illumination
  private

  def call_pattern(_strip, _key, _wait_ms, _loops)
    raise RuntimeError, "pattern failed"
  end
end

class DaisenkofunIlluminationFakeLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunSetlistTest < Picotest::Test
  def test_setlist_sizes_are_fixed
    assert_equal 1, Daisenkofun::Setlist::TESTS.length
    assert_equal 7, Daisenkofun::Setlist::HIGHLIGHTS.length
    assert_equal 19, Daisenkofun::Setlist::STORY.length
    assert_equal 30, Daisenkofun::Setlist::SHOWCASE.length
    assert_equal 32, Daisenkofun::Setlist::PATTERNS.length
  end

  def test_tests_preserves_the_smoke_test_sequence
    assert_equal [
      [:structure_guide, 1, 1]
    ], Daisenkofun::Setlist.resolve(:tests)
  end

  def test_highlights_preserves_the_original_seven_pattern_sequence
    assert_equal [
      [:structure_guide, 10, 1],
      [:divine_light, 10, 1],
      [:launch_fireworks, 10, 1],
      [:sunrise, 10, 1],
      [:dappled_light, 10, 1],
      [:triple_moat_mirror, 10, 1],
      [:water_ripples, 10, 3]
    ], Daisenkofun::Setlist.resolve(:highlights)
  end

  def test_available_keys_are_unique_and_have_pattern_classes
    patterns = Daisenkofun::Setlist::PATTERNS
    keys = patterns.map { |entry| entry[Daisenkofun::Setlist::KEY] }
    assert_equal keys.length, keys.uniq.length

    registered_classes = patterns.map { |pattern| pattern[Daisenkofun::Setlist::PATTERN_CLASS] }
    pattern_classes = Daisenkofun::Illuminations.constants.select do |name|
      name != :Base && Daisenkofun::Illuminations.const_get(name).is_a?(Class)
    end.map { |name| Daisenkofun::Illuminations.const_get(name) }
    assert_equal registered_classes.map(&:to_s).sort, pattern_classes.map(&:to_s).sort

    non_base_classes = registered_classes.select do |klass|
      !(klass < Daisenkofun::Illuminations::Base)
    end
    assert_equal [], non_base_classes
  end

  def test_every_setlist_entry_is_valid
    available_keys = Daisenkofun::Setlist::PATTERNS.map { |entry| entry[Daisenkofun::Setlist::KEY] }
    invalid = []
    setlists = [
      Daisenkofun::Setlist::TESTS,
      Daisenkofun::Setlist::HIGHLIGHTS,
      Daisenkofun::Setlist::STORY,
      Daisenkofun::Setlist::SHOWCASE
    ]
    setlists.each do |entries|
      entries.each do |entry|
        key = entry[Daisenkofun::Setlist::KEY]
        wait_ms = entry[Daisenkofun::Setlist::WAIT_MS]
        loops = entry[Daisenkofun::Setlist::LOOPS]
        invalid << entry unless entry.length == 3 && available_keys.include?(key) && wait_ms >= 0 && loops > 0
      end
    end
    assert_equal [], invalid
  end

  def test_resolve_and_pattern_lookup_reject_unknown_names
    expected = Daisenkofun::Setlist.entry_for(:sunrise)
    assert_equal [:sunrise, 125, 1], expected
    assert_equal Daisenkofun::Illuminations::Sunrise, Daisenkofun::Setlist.pattern_class(:sunrise)
    assert_equal nil, Daisenkofun::Setlist.pattern_class(:unknown)
    assert_raise(ArgumentError) { Daisenkofun::Setlist.resolve(:unknown) }
  end

  def test_illumination_rejects_unknown_setlist_and_pattern_names
    illumination = Daisenkofun::Illumination.new

    assert_raise(ArgumentError) { illumination.play_setlist(:unknown) }
    assert_raise(ArgumentError) { illumination.play_pattern(:unknown) }
  end

  def test_illumination_clears_and_closes_leds_after_an_error
    logger = DaisenkofunIlluminationFakeLogger.new
    illumination = DaisenkofunFailingIllumination.new(logger: logger)

    assert_raise(RuntimeError) { illumination.play_pattern(:structure_guide) }
    strip = WS2812.last_instance
    assert strip.closed
    assert_equal Array.new(Daisenkofun::LedLayout::LED_COUNT, 0), strip.pixels
    assert_equal "DAISENKOFUN mode=illumination event=led_off", logger.messages[-1]
  end
end
