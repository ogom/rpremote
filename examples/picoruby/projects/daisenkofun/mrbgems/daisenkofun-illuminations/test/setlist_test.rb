# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunSetlistTest < Picotest::Test
  def test_mode_sizes_are_fixed
    assert_equal 7, Daisenkofun::Setlist::SHORT.length
    assert_equal 19, Daisenkofun::Setlist::LONG.length
    assert_equal 30, Daisenkofun::Setlist::ALL.length
    assert_equal 32, Daisenkofun::Setlist::PATTERNS.length
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

  def test_every_mode_entry_is_valid
    available_keys = Daisenkofun::Setlist::PATTERNS.map { |entry| entry[Daisenkofun::Setlist::KEY] }
    invalid = []
    [Daisenkofun::Setlist::SHORT, Daisenkofun::Setlist::LONG, Daisenkofun::Setlist::ALL].each do |entries|
      entries.each do |entry|
        key = entry[Daisenkofun::Setlist::KEY]
        wait_ms = entry[Daisenkofun::Setlist::WAIT_MS]
        loops = entry[Daisenkofun::Setlist::LOOPS]
        invalid << entry unless entry.length == 3 && available_keys.include?(key) && wait_ms >= 0 && loops > 0
      end
    end
    assert_equal [], invalid
  end

  def test_only_resolves_defaults_and_rejects_unknown_keys
    expected = Daisenkofun::Setlist.entry_for(:sunrise)
    assert_equal [expected], Daisenkofun::Setlist.resolve(:only, :sunrise)
    assert_equal Daisenkofun::Illuminations::Sunrise, Daisenkofun::Setlist.pattern_class(:sunrise)
    assert_equal nil, Daisenkofun::Setlist.pattern_class(:unknown)
    assert_raise(ArgumentError) { Daisenkofun::Setlist.resolve(:only, :unknown) }
    assert_raise(ArgumentError) { Daisenkofun::Setlist.resolve(:unknown) }
  end
end
