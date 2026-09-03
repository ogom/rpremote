# frozen_string_literal: true

require "daisenkofun-runtime"
require "daisenkofun-illuminations"
require "daisenkofun-musical"
require "daisenkofun-oximeter"

# Operating-mode settings. nil selects the mode-specific default.
mode = :illumination # :illumination, :oximeter, or :combined
setlist_name = :tests # :tests, :highlights, :story, or :showcase
pattern_key = nil
duration_ms = nil

modes = [:illumination, :oximeter, :combined]
unless modes.include?(mode)
  raise ArgumentError, "mode must be :illumination, :oximeter, or :combined"
end

if mode == :illumination
  if setlist_name && pattern_key
    raise ArgumentError, "setlist_name and pattern_key are mutually exclusive"
  end
  if duration_ms
    raise ArgumentError, "duration_ms is only valid for mode :oximeter or :combined"
  end

  setlist_name = :highlights unless setlist_name || pattern_key
  Daisenkofun::Setlist.resolve(setlist_name) if setlist_name
  if pattern_key && !Daisenkofun::Setlist.valid_key?(pattern_key)
    raise ArgumentError, "pattern_key must name a registered pattern"
  end
else
  if setlist_name || pattern_key
    raise ArgumentError, "setlist_name and pattern_key are only valid for mode :illumination"
  end

  duration_ms ||= Daisenkofun::Oximeter::Config::RUN_DURATION_MS
  unless duration_ms.is_a?(Integer) && duration_ms > 0
    raise ArgumentError, "duration_ms must be a positive Integer"
  end
end

logger = Daisenkofun::ConsoleLogger.new
clock = Daisenkofun::Oximeter::BoardClock.new
illumination = nil
oximeter_runner = nil
beat_illumination = nil
musical = nil
result = nil
failure = nil

logger.puts("DAISENKOFUN mode=#{mode} event=start")

begin
  if mode == :illumination
    illumination = Daisenkofun::Illumination.new(logger: logger)
    result = if pattern_key
               illumination.play_pattern(pattern_key)
             else
               illumination.play_setlist(setlist_name)
             end
  else
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new
    renderer = Daisenkofun::Oximeter::StatusLed::Factory.new.call
    oximeter_runner = Daisenkofun::Oximeter::Runner.new(
      status_renderer: renderer,
      dispatcher: dispatcher,
      clock: clock,
      logger: logger,
      duration_ms: duration_ms
    )
    components = []

    if mode == :combined
      beat_illumination = Daisenkofun::BeatIllumination.new(logger: logger)
      musical = Daisenkofun::Musical::BeatSubscriber.new(
        output: Daisenkofun::Musical::NullOutput.new,
        logger: logger
      )
      dispatcher.subscribe(beat_illumination)
      dispatcher.subscribe(musical)
      components = [beat_illumination, musical]
    end

    result = Daisenkofun::EventLoop.new(
      publisher: oximeter_runner,
      components: components,
      clock: clock,
      logger: logger,
      mode: mode
    ).run
  end
rescue => error
  failure = error
ensure
  cleanup_components = [oximeter_runner, musical, beat_illumination, illumination]
  index = 0
  while index < cleanup_components.length
    component = cleanup_components[index]
    if component
      begin
        component.stop
      rescue => cleanup_error
        logger.puts(
          "DAISENKOFUN mode=#{mode} event=cleanup_error " \
          "error=#{cleanup_error.class} message=#{cleanup_error.message}"
        )
        failure ||= cleanup_error
      end
    end
    index += 1
  end

  status = failure ? :error : :ok
  message = "DAISENKOFUN mode=#{mode} event=done status=#{status}"
  message += " error=#{failure.class} message=#{failure.message}" if failure
  logger.puts(message)
end

raise failure if failure

result
