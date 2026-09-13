# frozen_string_literal: true

module Goryokaku
  module Application
    class Runner
      def initialize(config:, validator: nil, logger: nil, clock: nil, composition: nil, dfu: nil)
        @config = config
        @validator = validator || Validator.new(config)
        @logger = logger || Goryokaku::Runtime::ConsoleLogger.new
        @clock = clock || Goryokaku::Runtime::Clock.new
        @composition = composition
        @dfu = dfu || DFU
      end

      def call(iterations: nil)
        @validator.validate
        result = nil
        failure = nil
        built = nil
        @logger.puts("GORYOKAKU mode=#{@config.mode} event=start")
        begin
          built = (@composition || Composition.new(config: @config, logger: @logger, clock: @clock)).build
          @dfu.confirm if @dfu
          result = run(built, iterations)
        rescue => error
          failure = error
        ensure
          begin
            built.player.stop if built && built.player
          rescue => cleanup_error
            failure ||= cleanup_error
          end
          @logger.puts("GORYOKAKU mode=#{@config.mode} event=done status=#{failure ? 'error' : 'ok'}")
        end
        raise failure if failure
        result
      end

      private

      def run(built, iterations)
        if @config.illumination?
          if @config.pattern_key
            built.player.play_pattern(@config.pattern_key, repeat: @config.repeat)
          else
            built.player.play_setlist(@config.setlist_name, repeat: @config.repeat)
          end
        else
          built.event_loop.call(iterations: iterations)
        end
      end
    end
  end
end
