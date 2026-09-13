# frozen_string_literal: true

require "picotest"

module Goryokaku
  module Illumination
    module LedLayout
      LED_COUNT = 380
    end
    module Setlist
      def self.resolve(name)
        return [:warm_white] if [:tests, :highlights, :story, :showcase].include?(name)
        raise ArgumentError, "unknown setlist"
      end
      def self.valid_key?(key); key == :warm_white; end
    end
  end
end

require "goryokaku-application/config"
require "goryokaku-application/validator"
require "goryokaku-application/runner"

class FakeGoryokakuLogger
  attr_reader :lines
  def initialize; @lines = []; end
  def puts(message); @lines << message; end
end

class FakeGoryokakuClock
end

class FakeGoryokakuPlayer
  attr_reader :events
  def initialize; @events = []; end
  def play_setlist(name, repeat: false); @events << [:setlist, name, repeat]; end
  def play_pattern(key, repeat: false); @events << [:pattern, key, repeat]; end
  def stop; @events << [:stop]; end
end

class FakeGoryokakuEventLoop
  attr_reader :iterations
  def call(iterations: nil); @iterations = iterations; end
end

class FakeGoryokakuComposition
  class Result
    attr_reader :player, :event_loop
    def initialize(player, event_loop); @player = player; @event_loop = event_loop; end
  end
  def initialize(player: nil, event_loop: nil)
    @result = Result.new(player, event_loop)
  end
  def build; @result; end
end

class FakeGoryokakuDfu
  attr_reader :confirmed
  def confirm; @confirmed = true; end
end
