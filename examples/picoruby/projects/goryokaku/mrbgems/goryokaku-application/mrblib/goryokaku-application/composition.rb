# frozen_string_literal: true

module Goryokaku
  module Application
    class Composition
      class Result
        attr_reader :player, :event_loop
        def initialize(player: nil, event_loop: nil)
          @player = player
          @event_loop = event_loop
        end
      end

      def initialize(config:, logger:, clock:)
        @config = config
        @logger = logger
        @clock = clock
      end

      def build
        output = build_output
        return Result.new(player: build_illumination_player(output)) if @config.illumination?

        dispatcher = Goryokaku::Interaction::Dispatcher.new
        device = Goryokaku::Interaction::Device.new(
          touch_pin: @config.combined? ? @config.touch_pin : nil,
          i2c_unit: @config.i2c_unit, i2c_frequency: @config.i2c_frequency,
          i2c_sda_pin: @config.i2c_sda_pin, i2c_scl_pin: @config.i2c_scl_pin
        )
        detector = Goryokaku::Interaction::Detector.new(
          vertical_threshold: @config.vertical_threshold,
          horizontal_threshold: @config.horizontal_threshold
        )
        publisher = Goryokaku::Interaction::Runner.new(
          device: device, detector: detector, dispatcher: dispatcher,
          logger: @logger, heartbeat_interval_ms: @config.heartbeat_interval_ms,
          mode_selection: @config.combined?, application_mode: @config.mode
        )
        gesture_detector = Goryokaku::Musical::TambourineDetector.new(
          application_mode: @config.mode, axis_signs: @config.musical_axis_signs,
          orientation_stable_ms: @config.orientation_stable_ms,
          shake_threshold: @config.shake_threshold, shake_window_ms: @config.shake_window_ms,
          shake_reversals: @config.shake_reversals, shake_retrigger_ms: @config.shake_retrigger_ms,
          strike_threshold: @config.strike_threshold, strike_release_threshold: @config.strike_release_threshold,
          strike_retrigger_ms: @config.strike_retrigger_ms
        )
        gestures = Goryokaku::Musical::GesturePublisher.new(detector: gesture_detector, dispatcher: dispatcher)
        dispatcher.subscribe(gestures)
        components = [gestures]
        if @config.combined?
          illumination = Goryokaku::Illumination::InteractivePlayer.new(
            pin: @config.led_pin, num: @config.led_count,
            setlist_name: @config.setlist_name, logger: @logger,
            soundtrack: build_soundtrack(output)
          )
          dispatcher.subscribe(illumination)
          components << illumination
        elsif @config.musical?
          illumination = Goryokaku::Illumination::TambourinePlayer.new(
            pin: @config.led_pin, num: @config.led_count
          )
          dispatcher.subscribe(illumination)
          components << illumination
        end
        musical = Goryokaku::Musical::Subscriber.new(
          output: output, volume: @config.buzzer_volume,
          mode: @config.musical? ? :tambourine : :illumination
        )
        dispatcher.subscribe(musical)
        components << musical
        event_loop = Goryokaku::Runtime::EventLoop.new(
          publisher: publisher, components: components,
          clock: @clock, interval_ms: @config.poll_interval_ms
        )
        Result.new(event_loop: event_loop)
      end

      private

      def build_illumination_player(output)
        Goryokaku::Illumination::Player.new(
          pin: @config.led_pin, num: @config.led_count, logger: @logger,
          soundtrack: build_soundtrack(output)
        )
      end

      def build_output
        if @config.buzzer_volume > 0
          Goryokaku::Musical::Outputs::Pwm.new(pin: @config.buzzer_pin)
        else
          Goryokaku::Musical::Outputs::Null.new
        end
      end

      def build_soundtrack(output)
        return nil unless @config.buzzer_volume > 0

        Goryokaku::Musical::IlluminationSoundtrack.new(
          output: output, volume: @config.buzzer_volume
        )
      end
    end
  end
end
