# frozen_string_literal: true

module Daisenkofun
  module Illumination
    module Setlist
      KEY = 0
      WAIT_MS = 1
      LOOPS = 2
      PATTERN_CLASS = 1
      DEFAULT_WAIT_MS = 2
      DEFAULT_LOOPS = 3
      TESTS_FRAME_MS = 1
      HIGHLIGHTS_FRAME_MS = 10
      STORY_FRAME_MS = 5
      SHOWCASE_FRAME_MS = 2

      # [key, wait_ms, loops]
      TESTS = [[:structure_guide, TESTS_FRAME_MS, 1]]

      HIGHLIGHTS = [
        [:structure_guide, HIGHLIGHTS_FRAME_MS, 1],
        [:divine_light, HIGHLIGHTS_FRAME_MS, 1],
        [:launch_fireworks, HIGHLIGHTS_FRAME_MS, 1],
        [:sunrise, HIGHLIGHTS_FRAME_MS, 1],
        [:dappled_light, HIGHLIGHTS_FRAME_MS, 1],
        [:triple_moat_mirror, HIGHLIGHTS_FRAME_MS, 1],
        [:water_ripples, HIGHLIGHTS_FRAME_MS, 3]
      ]

      STORY = [
        [:structure_guide, STORY_FRAME_MS, 1],
        [:sunrise, STORY_FRAME_MS, 1],
        [:dappled_light, STORY_FRAME_MS, 1],
        [:cherry_blossom, STORY_FRAME_MS, 1],
        [:triple_moat_mirror, STORY_FRAME_MS, 1],
        [:water_ripples, STORY_FRAME_MS, 3],
        [:sakai_sunset, STORY_FRAME_MS, 1],
        [:moonlight, STORY_FRAME_MS, 1],
        [:starry_kofun, STORY_FRAME_MS, 1],
        [:peekaboo, STORY_FRAME_MS, 1],
        [:heartbeat, STORY_FRAME_MS, 1],
        [:jewel_box, STORY_FRAME_MS, 1],
        [:aurora, STORY_FRAME_MS, 1],
        [:symmetric_forepart_chase, STORY_FRAME_MS, 1],
        [:two_banks_clockwise, STORY_FRAME_MS, 1],
        [:rainbow_comet, STORY_FRAME_MS, 1],
        [:divine_light, STORY_FRAME_MS, 1],
        [:attached_kofun_lights, STORY_FRAME_MS, 1],
        [:launch_fireworks, STORY_FRAME_MS, 1]
      ]
      SHOWCASE = [
        [:moonlight, SHOWCASE_FRAME_MS, 1],
        [:starry_kofun, SHOWCASE_FRAME_MS, 1],
        [:attached_kofun_lights, SHOWCASE_FRAME_MS, 1],
        [:goodnight_pastel, SHOWCASE_FRAME_MS, 1],
        [:dappled_light, SHOWCASE_FRAME_MS, 1],
        [:green_shimmer, SHOWCASE_FRAME_MS, 1],
        [:fireflies, SHOWCASE_FRAME_MS, 1],
        [:sea, SHOWCASE_FRAME_MS, 1],
        [:triple_moat_mirror, SHOWCASE_FRAME_MS, 1],
        [:sunrise, SHOWCASE_FRAME_MS, 1],
        [:sakai_sunset, SHOWCASE_FRAME_MS, 1],
        [:golden_breath, SHOWCASE_FRAME_MS, 1],
        [:aurora, SHOWCASE_FRAME_MS, 1],
        [:divine_light, SHOWCASE_FRAME_MS, 1],
        [:cherry_blossom, SHOWCASE_FRAME_MS, 1],
        [:rose_garden, SHOWCASE_FRAME_MS, 1],
        [:pastel_ribbon, SHOWCASE_FRAME_MS, 1],
        [:princess_sparkle, SHOWCASE_FRAME_MS, 1],
        [:unicorn_dream, SHOWCASE_FRAME_MS, 1],
        [:peekaboo, SHOWCASE_FRAME_MS, 1],
        [:heartbeat, SHOWCASE_FRAME_MS, 1],
        [:jewel_box, SHOWCASE_FRAME_MS, 1],
        [:symmetric_forepart_chase, SHOWCASE_FRAME_MS, 1],
        [:rainbow_comet, SHOWCASE_FRAME_MS, 1],
        [:two_banks_clockwise, SHOWCASE_FRAME_MS, 1],
        [:color_bound, SHOWCASE_FRAME_MS, 1],
        [:carnival_chase, SHOWCASE_FRAME_MS, 1],
        [:torch_procession, SHOWCASE_FRAME_MS, 1],
        [:fireworks, SHOWCASE_FRAME_MS, 1],
        [:launch_fireworks, SHOWCASE_FRAME_MS, 1]
      ]

      # [key, class, default_wait_ms, default_loops]
      PATTERNS = [
        [:attached_kofun_lights, Patterns::AttachedKofunLights, 125, 3],
        [:aurora, Patterns::Aurora, 95, 2],
        [:carnival_chase, Patterns::CarnivalChase, 75, 2],
        [:cherry_blossom, Patterns::CherryBlossom, 95, 1],
        [:color_bound, Patterns::ColorBound, 75, 1],
        [:dappled_light, Patterns::DappledLight, 95, 1],
        [:divine_light, Patterns::DivineLight, 95, 1],
        [:fireflies, Patterns::Fireflies, 95, 1],
        [:fireworks, Patterns::Fireworks, 125, 1],
        [:golden_breath, Patterns::GoldenBreath, 155, 3],
        [:goodnight_pastel, Patterns::GoodnightPastel, 155, 2],
        [:green_shimmer, Patterns::GreenShimmer, 95, 2],
        [:heartbeat, Patterns::Heartbeat, 125, 3],
        [:jewel_box, Patterns::JewelBox, 95, 2],
        [:launch_fireworks, Patterns::LaunchFireworks, 125, 1],
        [:moonlight, Patterns::Moonlight, 125, 2],
        [:pastel_ribbon, Patterns::PastelRibbon, 75, 2],
        [:peekaboo, Patterns::Peekaboo, 125, 2],
        [:princess_sparkle, Patterns::PrincessSparkle, 95, 1],
        [:rainbow_comet, Patterns::RainbowComet, 75, 1],
        [:rose_garden, Patterns::RoseGarden, 95, 2],
        [:sakai_sunset, Patterns::SakaiSunset, 125, 1],
        [:sea, Patterns::Sea, 95, 2],
        [:starry_kofun, Patterns::StarryKofun, 95, 1],
        [:structure_guide, Patterns::StructureGuide, 95, 1],
        [:sunrise, Patterns::Sunrise, 125, 1],
        [:symmetric_forepart_chase, Patterns::SymmetricForepartChase, 75, 2],
        [:torch_procession, Patterns::TorchProcession, 75, 1],
        [:triple_moat_mirror, Patterns::TripleMoatMirror, 125, 1],
        [:two_banks_clockwise, Patterns::TwoBanksClockwise, 75, 2],
        [:unicorn_dream, Patterns::UnicornDream, 95, 2],
        [:water_ripples, Patterns::WaterRipples, 95, 2]
      ]

      def self.resolve(setlist_name)
        case setlist_name
        when :tests
          TESTS
        when :highlights
          HIGHLIGHTS
        when :story
          STORY
        when :showcase
          SHOWCASE
        else
          raise ArgumentError, "setlist_name must be :tests, :highlights, :story, or :showcase"
        end
      end

      def self.entry_for(key)
        pattern = pattern_for(key)
        return nil unless pattern

        [pattern[KEY], pattern[DEFAULT_WAIT_MS], pattern[DEFAULT_LOOPS]]
      end

      def self.key(entry)
        entry[KEY]
      end

      def self.wait_ms(entry)
        entry[WAIT_MS]
      end

      def self.loops(entry)
        entry[LOOPS]
      end

      def self.pattern_for(key)
        index = 0
        while index < PATTERNS.length
          pattern = PATTERNS[index]
          return pattern if pattern[KEY] == key

          index += 1
        end
        nil
      end

      def self.valid_key?(key)
        !entry_for(key).nil?
      end

      def self.pattern_class(key)
        pattern = pattern_for(key)
        pattern && pattern[PATTERN_CLASS]
      end
    end
  end
end
