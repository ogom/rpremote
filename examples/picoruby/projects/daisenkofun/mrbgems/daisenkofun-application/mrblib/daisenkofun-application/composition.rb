# frozen_string_literal: true

module Daisenkofun
  module Application
    class Composition
      class Result
        attr_reader :player, :publisher, :components, :cleanup_components, :musical_output, :musical_planner

        def initialize(player: nil, publisher: nil, components: [], cleanup_components: [], musical_output: nil, musical_planner: nil)
          @player = player
          @publisher = publisher
          @components = components
          @cleanup_components = cleanup_components
          @musical_output = musical_output
          @musical_planner = musical_planner
        end
      end

      def initialize(config:, clock:, logger:)
        @config = config
        @clock = clock
        @logger = logger
      end

      def build
        return build_illumination if @config.illumination?

        build_measurement
      end

      private

      def build_illumination
        device = Daisenkofun::Illumination::Device.new(pin: @config.ws2812_pin)
        player = Daisenkofun::Illumination::Player.new(device: device, logger: @logger)
        Result.new(player: player, cleanup_components: [player])
      end

      def build_measurement
        dispatcher = Daisenkofun::Oximeter::Dispatcher.new
        renderer = Daisenkofun::Oximeter::StatusLed::Factory.new(sck_pin: @config.spi_sck_pin, copi_pin: @config.spi_copi_pin).call
        sensor_factory = Daisenkofun::Oximeter::SensorFactory.new(sda_pin: @config.i2c_sda_pin, scl_pin: @config.i2c_scl_pin)
        publisher = Daisenkofun::Oximeter::Runner.new(
          status_renderer: renderer,
          dispatcher: dispatcher,
          clock: @clock,
          logger: @logger,
          sensor_factory: sensor_factory,
          duration_ms: @config.duration_ms
        )
        return Result.new(publisher: publisher, cleanup_components: [publisher]) unless @config.combined?

        build_combined(dispatcher, publisher)
      end

      def build_combined(dispatcher, publisher)
        musical_result = MusicalFactory.new(clock: @clock, logger: @logger).build(@config)
        device = Daisenkofun::Illumination::Device.new(pin: @config.ws2812_pin)
        illumination = Daisenkofun::Illumination::BiometricPlayer.new(device: device, pattern: musical_result.pattern, logger: @logger)
        musical = Daisenkofun::Musical::Subscriber.new(output: musical_result.output, logger: @logger, immediate_beat: true)
        dispatcher.subscribe(musical)
        dispatcher.subscribe(illumination)

        Result.new(
          publisher: publisher,
          components: [musical, illumination],
          cleanup_components: [publisher, musical, illumination],
          musical_output: musical_result.output,
          musical_planner: musical_result.planner
        )
      end
    end
  end
end
