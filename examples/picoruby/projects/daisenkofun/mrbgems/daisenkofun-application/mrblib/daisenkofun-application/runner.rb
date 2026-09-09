# frozen_string_literal: true

module Daisenkofun
  module Application
    class Runner
      def initialize(config:, validator: nil, logger: nil, clock: nil, dfu: nil)
        @config = config
        @validator = validator || Validator.new
        @logger = logger
        @clock = clock
        @dfu = dfu || DFU
      end

      def call
        @validator.validate(@config)
        logger = @logger || Daisenkofun::Runtime::ConsoleLogger.new
        clock = @clock || Daisenkofun::Runtime::Clock.new
        composition = nil
        failure = nil
        result = nil

        logger.puts("DAISENKOFUN mode=#{@config.mode} event=start")
        begin
          composition = Composition.new(config: @config, clock: clock, logger: logger).build
          @dfu.confirm
          result = run_mode(composition, clock, logger)
          VerificationReporter.new(logger: logger).report(@config, composition)
        rescue => error
          failure = error
        ensure
          failure = stop_components(composition, logger, failure)
          log_done(logger, failure)
        end

        raise failure if failure

        result
      end

      private

      def run_mode(composition, clock, logger)
        return run_illumination(composition.player) if @config.illumination?

        Daisenkofun::Runtime::EventLoop.new(
          publisher: composition.publisher,
          components: composition.components,
          clock: clock,
          logger: logger,
          mode: @config.mode
        ).call
      end

      def run_illumination(player)
        if @config.pattern_key
          player.play_pattern(@config.pattern_key, repeat: @config.repeat)
        else
          player.play_setlist(@config.setlist_name, repeat: @config.repeat)
        end
      end

      def stop_components(composition, logger, failure)
        return failure unless composition

        components = composition.cleanup_components
        index = 0
        while index < components.length
          begin
            components[index].stop if components[index]
          rescue => cleanup_error
            logger.puts("DAISENKOFUN mode=#{@config.mode} event=cleanup_error error=#{cleanup_error.class} message=#{cleanup_error.message}")
            failure ||= cleanup_error
          end
          index += 1
        end
        failure
      end

      def log_done(logger, failure)
        status = failure ? :error : :ok
        message = "DAISENKOFUN mode=#{@config.mode} event=done status=#{status}"
        message += " error=#{failure.class} message=#{failure.message}" if failure
        logger.puts(message)
      end
    end
  end
end
