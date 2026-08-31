# frozen_string_literal: true

module Daisenkofun
  module Setlist
    KEY = 0
    WAIT_MS = 1
    LOOPS = 2
    PATTERN_CLASS = 1
    DEFAULT_WAIT_MS = 2
    DEFAULT_LOOPS = 3
    SHORT_FRAME_MS = 10
    LONG_FRAME_MS = 5
    ALL_FRAME_MS = 2

    # [key, wait_ms, loops]
    # 構造紹介の直後に、神々しい光と八尺玉でインパクトを作ります。
    SHORT = [
      [:structure_guide, SHORT_FRAME_MS, 1],
      [:divine_light, SHORT_FRAME_MS, 1],
      [:launch_fireworks, SHORT_FRAME_MS, 1],
      [:sunrise, SHORT_FRAME_MS, 1],
      [:dappled_light, SHORT_FRAME_MS, 1],
      [:triple_moat_mirror, SHORT_FRAME_MS, 1],
      [:water_ripples, SHORT_FRAME_MS, 3]
    ]

    # 夜明けから自然、水辺、夕暮れ、夜、祝祭へ進む物語にします。
    LONG = [
      [:structure_guide, LONG_FRAME_MS, 1],
      [:sunrise, LONG_FRAME_MS, 1],
      [:dappled_light, LONG_FRAME_MS, 1],
      [:cherry_blossom, LONG_FRAME_MS, 1],
      [:triple_moat_mirror, LONG_FRAME_MS, 1],
      [:water_ripples, LONG_FRAME_MS, 3],
      [:sakai_sunset, LONG_FRAME_MS, 1],
      [:moonlight, LONG_FRAME_MS, 1],
      [:starry_kofun, LONG_FRAME_MS, 1],
      [:peekaboo, LONG_FRAME_MS, 1],
      [:heartbeat, LONG_FRAME_MS, 1],
      [:jewel_box, LONG_FRAME_MS, 1],
      [:aurora, LONG_FRAME_MS, 1],
      [:symmetric_forepart_chase, LONG_FRAME_MS, 1],
      [:two_banks_clockwise, LONG_FRAME_MS, 1],
      [:rainbow_comet, LONG_FRAME_MS, 1],
      [:divine_light, LONG_FRAME_MS, 1],
      [:attached_kofun_lights, LONG_FRAME_MS, 1],
      [:launch_fireworks, LONG_FRAME_MS, 1]
    ]
    ALL = [
      [:moonlight, ALL_FRAME_MS, 1],
      [:starry_kofun, ALL_FRAME_MS, 1],
      [:attached_kofun_lights, ALL_FRAME_MS, 1],
      [:goodnight_pastel, ALL_FRAME_MS, 1],
      [:dappled_light, ALL_FRAME_MS, 1],
      [:green_shimmer, ALL_FRAME_MS, 1],
      [:fireflies, ALL_FRAME_MS, 1],
      [:sea, ALL_FRAME_MS, 1],
      [:triple_moat_mirror, ALL_FRAME_MS, 1],
      [:sunrise, ALL_FRAME_MS, 1],
      [:sakai_sunset, ALL_FRAME_MS, 1],
      [:golden_breath, ALL_FRAME_MS, 1],
      [:aurora, ALL_FRAME_MS, 1],
      [:divine_light, ALL_FRAME_MS, 1],
      [:cherry_blossom, ALL_FRAME_MS, 1],
      [:rose_garden, ALL_FRAME_MS, 1],
      [:pastel_ribbon, ALL_FRAME_MS, 1],
      [:princess_sparkle, ALL_FRAME_MS, 1],
      [:unicorn_dream, ALL_FRAME_MS, 1],
      [:peekaboo, ALL_FRAME_MS, 1],
      [:heartbeat, ALL_FRAME_MS, 1],
      [:jewel_box, ALL_FRAME_MS, 1],
      [:symmetric_forepart_chase, ALL_FRAME_MS, 1],
      [:rainbow_comet, ALL_FRAME_MS, 1],
      [:two_banks_clockwise, ALL_FRAME_MS, 1],
      [:color_bound, ALL_FRAME_MS, 1],
      [:carnival_chase, ALL_FRAME_MS, 1],
      [:torch_procession, ALL_FRAME_MS, 1],
      [:fireworks, ALL_FRAME_MS, 1],
      [:launch_fireworks, ALL_FRAME_MS, 1]
    ]

    # [key, class, default_wait_ms, default_loops]
    PATTERNS = [
      [:attached_kofun_lights, Illuminations::AttachedKofunLights, 125, 3],
      [:aurora, Illuminations::Aurora, 95, 2],
      [:carnival_chase, Illuminations::CarnivalChase, 75, 2],
      [:cherry_blossom, Illuminations::CherryBlossom, 95, 1],
      [:color_bound, Illuminations::ColorBound, 75, 1],
      [:dappled_light, Illuminations::DappledLight, 95, 1],
      [:divine_light, Illuminations::DivineLight, 95, 1],
      [:fireflies, Illuminations::Fireflies, 95, 1],
      [:fireworks, Illuminations::Fireworks, 125, 1],
      [:golden_breath, Illuminations::GoldenBreath, 155, 3],
      [:goodnight_pastel, Illuminations::GoodnightPastel, 155, 2],
      [:green_shimmer, Illuminations::GreenShimmer, 95, 2],
      [:heartbeat, Illuminations::Heartbeat, 125, 3],
      [:jewel_box, Illuminations::JewelBox, 95, 2],
      [:launch_fireworks, Illuminations::LaunchFireworks, 125, 1],
      [:moonlight, Illuminations::Moonlight, 125, 2],
      [:pastel_ribbon, Illuminations::PastelRibbon, 75, 2],
      [:peekaboo, Illuminations::Peekaboo, 125, 2],
      [:princess_sparkle, Illuminations::PrincessSparkle, 95, 1],
      [:rainbow_comet, Illuminations::RainbowComet, 75, 1],
      [:rose_garden, Illuminations::RoseGarden, 95, 2],
      [:sakai_sunset, Illuminations::SakaiSunset, 125, 1],
      [:sea, Illuminations::Sea, 95, 2],
      [:starry_kofun, Illuminations::StarryKofun, 95, 1],
      [:structure_guide, Illuminations::StructureGuide, 95, 1],
      [:sunrise, Illuminations::Sunrise, 125, 1],
      [:symmetric_forepart_chase, Illuminations::SymmetricForepartChase, 75, 2],
      [:torch_procession, Illuminations::TorchProcession, 75, 1],
      [:triple_moat_mirror, Illuminations::TripleMoatMirror, 125, 1],
      [:two_banks_clockwise, Illuminations::TwoBanksClockwise, 75, 2],
      [:unicorn_dream, Illuminations::UnicornDream, 95, 2],
      [:water_ripples, Illuminations::WaterRipples, 95, 2]
    ]

    def self.resolve(run_mode, only_key = nil)
      case run_mode
      when :short
        SHORT
      when :long
        LONG
      when :all
        ALL
      when :only
        raise ArgumentError, "only_key is required" unless valid_key?(only_key)

        [entry_for(only_key)]
      else
        raise ArgumentError, "run_mode must be :short, :long, :all, or :only"
      end
    end

    def self.entry_for(key)
      pattern = pattern_for(key)
      return nil unless pattern

      [pattern[KEY], pattern[DEFAULT_WAIT_MS], pattern[DEFAULT_LOOPS]]
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
