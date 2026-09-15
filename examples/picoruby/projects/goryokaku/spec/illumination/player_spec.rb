# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Illumination::Player do
  it "runs one embedded pattern with its soundtrack and always clears and closes the strip" do
    strip = WS2812.new(pin: 14, num: 380)
    logger = GoryokakuSpec::Logger.new
    soundtrack = double(:soundtrack, start: nil, join: nil, stop: nil, wait_ms: nil)
    player = described_class.new(strip: strip, logger: logger, soundtrack: soundtrack)

    player.play_pattern(:warm_white)

    expect(soundtrack).to have_received(:start).with(repeat: false)
    expect(soundtrack).to have_received(:join)
    expect(soundtrack).to have_received(:stop)
    expect(strip.pixels).to all(eq(0))
    expect(strip.closed).to be(true)
    expect(logger.messages.last).to eq("GORYOKAKU mode=illumination event=led_off")
  end

  it "rejects unknown patterns before opening hardware" do
    expect { described_class.new.play_pattern(:unknown) }.to raise_error(ArgumentError, /registered pattern/)
  end
end

RSpec.describe Goryokaku::Illumination::InteractivePlayer do
  it "uses red and blue ravelin candidates, preserves selection across orientation, and runs the confirmed setlist" do
    setlist_player = double(:setlist_player, play_setlist: nil)
    player = described_class.new(player: setlist_player, setlist_name: :story).start
    strip = WS2812.last_instance

    player.on_event(%i[mode_selected tambourine])
    expect(strip.pixels[170]).to eq(0x00007F)
    player.on_event(%i[orientation_changed z_up])
    expect(strip.pixels[170]).to eq(0x00007F)
    player.on_event(%i[mode_selected illumination])
    expect(strip.pixels[170]).to eq(0x7F0000)
    player.on_event(%i[mode_changed illumination])

    expect(setlist_player).to have_received(:play_setlist).with(:story, repeat: false)
  ensure
    player&.stop
  end
end

RSpec.describe Goryokaku::Illumination::TambourinePlayer do
  def build_player
    strip = WS2812.new(pin: 14, num: 380)
    device = Goryokaku::Illumination::Device.new(strip: strip)
    [described_class.new(device: device).start, strip]
  end

  it "starts a directional shake at group five with a trailing group" do
    player, strip = build_player
    player.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    player.tick(0)
    expect(Goryokaku::Illumination::LedLayout.star_group(4)).to all(satisfy { |index| strip.pixels[index] != 0 })

    player.tick(20)
    expect(Goryokaku::Illumination::LedLayout.star_group(0)).to all(satisfy { |index| strip.pixels[index] != 0 })
  ensure
    player&.stop
  end

  it "expands a strike from star rays through the ravelin to the outer ring and then clears" do
    player, strip = build_player
    player.on_event([:tambourine_struck, 0, 1.0, 120])
    player.tick(0)
    expect(strip.pixels[0]).not_to eq(0)
    expect(strip.pixels[170]).not_to eq(0)
    expect(strip.pixels[190..]).to include(satisfy { |pixel| pixel != 0 })

    player.tick(60)
    expect(strip.pixels[190..]).to all(satisfy { |pixel| pixel != 0 })
    player.tick(120)
    expect(strip.pixels).to all(eq(0))
  ensure
    player&.stop
  end
end
