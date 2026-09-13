# frozen_string_literal: true

require_relative "test_helper"

class RecordingInteractiveSetlistPlayer
  attr_reader :events
  def initialize; @events = []; end
  def play_setlist(name, repeat: false); @events << [:setlist, name, repeat]; end
end

class GoryokakuIlluminationInteractivePlayerTest < Picotest::Test
  def test_selection_uses_ravelin_colors_and_confirmation_applies_mode
    setlist_player = RecordingInteractiveSetlistPlayer.new
    player = Goryokaku::Illumination::InteractivePlayer.new(player: setlist_player, setlist_name: :story)
    player.start
    strip = WS2812.last_instance

    player.on_event([:orientation_changed, :z_up])
    assert strip.pixels.any? { |pixel| pixel != 0 }

    player.on_event([:orientation_changed, :y_up])
    player.on_event([:mode_selected, :tambourine])
    assert_equal 0x00007F, strip.pixels[170]

    player.on_event([:mode_selected, :illumination])
    assert_equal 0x7F0000, strip.pixels[170]

    player.on_event([:mode_selected, :tambourine])
    player.on_event([:orientation_changed, :z_up])
    assert_equal 0x00007F, strip.pixels[170]

    player.on_event([:mode_changed, :tambourine])
    assert_equal 380, strip.pixels.count { |pixel| pixel == 0 }

    player.on_event([:mode_changed, :illumination])
    assert_equal [[:setlist, :story, false]], setlist_player.events
    assert strip.pixels.any? { |pixel| pixel != 0 }
  end
end
