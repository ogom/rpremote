# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Setlist
      KEY = 0
      WAIT_MS = 1
      LOOPS = 2
      PATTERN_CLASS = 1
      DEFAULT_WAIT_MS = 2
      DEFAULT_LOOPS = 3
      TESTS_FRAME_MS = 1
      HIGHLIGHTS_FRAME_MS = 35
      STORY_FRAME_MS = 35
      SHOWCASE_FRAME_MS = 35

      TESTS = [[:warm_white, TESTS_FRAME_MS, 1]]
      HIGHLIGHTS = [
        [:warm_white, HIGHLIGHTS_FRAME_MS, 1],
        [:sakura_breathe, HIGHLIGHTS_FRAME_MS, 1],
        [:ravelin_pulse, HIGHLIGHTS_FRAME_MS, 1],
        [:outer_comet, HIGHLIGHTS_FRAME_MS, 1],
        [:rainbow, HIGHLIGHTS_FRAME_MS, 1],
        [:full_zones, HIGHLIGHTS_FRAME_MS, 1],
        [:fireworks, HIGHLIGHTS_FRAME_MS, 3]
      ]
      STORY = [
        [:warm_white, STORY_FRAME_MS, 1],
        [:star_twinkle, STORY_FRAME_MS, 1],
        [:ravelin_pulse, STORY_FRAME_MS, 1],
        [:outer_comet, STORY_FRAME_MS, 1],
        [:rainbow, STORY_FRAME_MS, 1],
        [:kouhaku, STORY_FRAME_MS, 1],
        [:shooting_star, STORY_FRAME_MS, 1],
        [:constellation, STORY_FRAME_MS, 1],
        [:sakura_fubuki, STORY_FRAME_MS, 1],
        [:sakura_stream, STORY_FRAME_MS, 1],
        [:sakura_gradient, STORY_FRAME_MS, 1],
        [:sakura_breathing, STORY_FRAME_MS, 1],
        [:hanami, STORY_FRAME_MS, 1],
        [:mankai, STORY_FRAME_MS, 1],
        [:fireworks, STORY_FRAME_MS, 3]
      ]
      SHOWCASE = [
        [:warm_white, SHOWCASE_FRAME_MS, 1],
        [:sakura_breathe, SHOWCASE_FRAME_MS, 1],
        [:star_twinkle, SHOWCASE_FRAME_MS, 1],
        [:ravelin_pulse, SHOWCASE_FRAME_MS, 1],
        [:outer_comet, SHOWCASE_FRAME_MS, 2],
        [:rainbow, SHOWCASE_FRAME_MS, 1],
        [:parallel_left, SHOWCASE_FRAME_MS, 1],
        [:parallel_right, SHOWCASE_FRAME_MS, 1],
        [:full_zones, SHOWCASE_FRAME_MS, 1],
        [:kouhaku, SHOWCASE_FRAME_MS, 1],
        [:twinkle, SHOWCASE_FRAME_MS, 1],
        [:shooting_star, SHOWCASE_FRAME_MS, 1],
        [:breathing, SHOWCASE_FRAME_MS, 1],
        [:constellation, SHOWCASE_FRAME_MS, 1],
        [:sakura_fubuki, SHOWCASE_FRAME_MS, 1],
        [:sakura_stream, SHOWCASE_FRAME_MS, 1],
        [:sakura_gradient, SHOWCASE_FRAME_MS, 1],
        [:sakura_breathing, SHOWCASE_FRAME_MS, 1],
        [:hanami, SHOWCASE_FRAME_MS, 1],
        [:mankai, SHOWCASE_FRAME_MS, 1],
        [:fireworks, SHOWCASE_FRAME_MS, 3]
      ]

      PATTERNS = [
        [:warm_white, Patterns::WarmWhite, 35, 1],
        [:sakura_breathe, Patterns::SakuraBreathe, 35, 1],
        [:star_twinkle, Patterns::StarTwinkle, 35, 1],
        [:ravelin_pulse, Patterns::RavelinPulse, 35, 1],
        [:outer_comet, Patterns::OuterComet, 35, 2],
        [:rainbow, Patterns::Rainbow, 35, 1],
        [:parallel_left, Patterns::ParallelLeft, 35, 1],
        [:parallel_right, Patterns::ParallelRight, 35, 1],
        [:full_zones, Patterns::FullZones, 35, 1],
        [:fireworks, Patterns::Fireworks, 35, 3],
        [:kouhaku, Patterns::Kouhaku, 500, 1],
        [:twinkle, Patterns::Twinkle, 100, 1],
        [:shooting_star, Patterns::ShootingStar, 50, 1],
        [:breathing, Patterns::Breathing, 30, 1],
        [:constellation, Patterns::Constellation, 500, 1],
        [:sakura_fubuki, Patterns::SakuraFubuki, 120, 1],
        [:sakura_stream, Patterns::SakuraStream, 80, 1],
        [:sakura_gradient, Patterns::SakuraGradient, 100, 1],
        [:sakura_breathing, Patterns::SakuraBreathing, 30, 1],
        [:hanami, Patterns::Hanami, 500, 1],
        [:mankai, Patterns::Mankai, 150, 1]
      ]

      def self.resolve(name)
        return TESTS if name == :tests
        return HIGHLIGHTS if name == :highlights
        return STORY if name == :story
        return SHOWCASE if name == :showcase
        raise ArgumentError, "setlist_name must be :tests, :highlights, :story, or :showcase"
      end

      def self.pattern_for(key)
        index = 0
        while index < PATTERNS.length
          return PATTERNS[index] if PATTERNS[index][KEY] == key
          index += 1
        end
        nil
      end

      def self.entry_for(key)
        pattern = pattern_for(key)
        pattern && [pattern[KEY], pattern[DEFAULT_WAIT_MS], pattern[DEFAULT_LOOPS]]
      end

      def self.key(entry); entry[KEY]; end
      def self.wait_ms(entry); entry[WAIT_MS]; end
      def self.loops(entry); entry[LOOPS]; end
      def self.valid_key?(key); !entry_for(key).nil?; end

      def self.pattern_class(key)
        pattern = pattern_for(key)
        pattern && pattern[PATTERN_CLASS]
      end
    end
  end
end
