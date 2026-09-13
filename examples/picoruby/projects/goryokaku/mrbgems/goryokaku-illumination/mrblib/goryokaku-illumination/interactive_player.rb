# frozen_string_literal: true

module Goryokaku
  module Illumination
    class InteractivePlayer
      def initialize(
        device: nil, player: nil, pin: Config::LED_PIN,
        num: LedLayout::LED_COUNT, setlist_name: :highlights, logger: nil, soundtrack: nil
      )
        @device = device || Device.new(pin: pin, num: num)
        @player = player || Player.new(device: @device, logger: logger, soundtrack: soundtrack)
        @tambourine_player = TambourinePlayer.new(device: @device)
        @setlist_name = setlist_name
        @effect = nil
        @frame = 0
        @firework_loop = 0
        @orientation = nil
        @mode = :illumination
        @selecting = false
      end

      def start; @device.open; self; end

      def on_event(event)
        type = event[0]
        if type == :orientation_changed
          @orientation = event[1]
          draw_orientation if @mode == :illumination && !@effect && !@selecting && orientation_displayable?
        elsif type == :mode_selected
          show_mode_selection(event[1])
        elsif type == :mode_changed
          change_mode(event[1])
        elsif type == :tambourine_shaken || type == :tambourine_struck || type == :tambourine_inactive
          @tambourine_player.on_event(event) if @mode == :tambourine
        end
      end

      def tick(timestamp_ms)
        return @tambourine_player.tick(timestamp_ms) if @mode == :tambourine
        return unless @effect
        @effect == :rainbow ? tick_rainbow : tick_fireworks
      end

      def warm_white_on
        display.fill_indices(LedLayout.all_order, Color::WARM_WHITE, Config::BRIGHTNESS)
        display.show
      end

      def sakura_on
        display.clear_buffer
        display.fill_zone(LedLayout::STAR, Color::SAKURA, Config::BRIGHTNESS)
        display.show
      end

      def cycle_rainbow(speed = 1)
        Patterns::Rainbow.new(display, scaled_wait(speed), 1).call
      end

      def firework_full_show(shots = 5, _brightness = Config::BRIGHTNESS)
        Patterns::Fireworks.new(display, Config::FRAME_INTERVAL_MS, shots).call
      end

      def off
        @device.close
      end

      alias stop off

      private

      def display
        @device.open unless @device.open?
        @device.display
      end

      def scaled_wait(speed)
        return Config::FRAME_INTERVAL_MS unless (speed.is_a?(Integer) || speed.is_a?(Float)) && speed > 0
        Config::FRAME_INTERVAL_MS / speed
      end

      def show_mode_selection(mode)
        @selecting = true
        color = mode == :illumination ? Color::RED : Color::BLUE
        display.fill_zone(LedLayout::RAVELIN, color, Config::BRIGHTNESS)
        display.show
      end

      def draw_orientation
        @orientation == :z_up ? warm_white_on : sakura_on
      end

      def orientation_displayable?
        @orientation && @orientation != :unknown
      end

      def change_mode(mode)
        @mode = mode
        @selecting = false
        @effect = nil
        if @mode == :tambourine
          @tambourine_player.clear
        else
          @player.play_setlist(@setlist_name, repeat: false)
          draw_orientation if orientation_displayable?
        end
      end

      def tick_rainbow
        segment = 0
        while segment < LedLayout::STAR_SEGMENT_RANGES.length
          display.fill_indices(LedLayout.star_segment(segment), Color.rainbow(segment + @frame), Config::BRIGHTNESS)
          segment += 1
        end
        display.show
        @frame += 1
        return unless @frame >= 35
        @effect = :fireworks
        @frame = 0
      end

      def tick_fireworks
        if @frame < 18
          display.scale_all(0.62)
          rays = LedLayout.star_rays
          ray = 0
          while ray < rays.length
            if @frame < rays[ray].length
              display.set(rays[ray][@frame], Color::FIREWORK[(ray + @firework_loop) % Color::FIREWORK.length], Config::BRIGHTNESS)
            end
            ray += 1
          end
        else
          step = @frame - 18
          display.fill_zone(LedLayout::OUTER, Color::FIREWORK[@firework_loop % Color::FIREWORK.length], Config::BRIGHTNESS * (12 - step) / 12.0)
        end
        display.show
        @frame += 1
        return unless @frame >= 31
        @firework_loop += 1
        @frame = 0
        return unless @firework_loop >= 5
        @effect = nil
        @device.clear
      end
    end
  end
end
