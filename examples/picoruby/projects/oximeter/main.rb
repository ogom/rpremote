# frozen_string_literal: true

require "/lib/oximeter/board_clock"
require "/lib/oximeter/config"
require "/lib/oximeter/console_logger"
require "/lib/oximeter/dispatcher"
require "/lib/oximeter/measurement/processor"
require "/lib/oximeter/sensor_factory"
require "/lib/oximeter/status_led/factory"
require "/lib/oximeter/status_led/presenter"

clock = Oximeter::BoardClock.new
logger = Oximeter::ConsoleLogger.new
dispatcher = Oximeter::Dispatcher.new
sensor_factory = Oximeter::SensorFactory.new
status_led_factory = Oximeter::StatusLed::Factory.new
duration_ms = Oximeter::Config::RUN_DURATION_MS
poll_interval_ms = Oximeter::Config::POLL_INTERVAL_MS

sensor = nil
renderer = nil
processor = nil

begin
  renderer = status_led_factory.call
  renderer.clear
  presenter = Oximeter::StatusLed::Presenter.new(renderer)
  dispatcher.subscribe(presenter)

  begin
    sensor = sensor_factory.call
  rescue => error
    renderer.error
    logger.puts("OXIMETER_ERROR,#{error.class},#{error.message}")
    clock.wait_ms(Oximeter::Config::ERROR_DISPLAY_MS)
    raise
  end

  processor = Oximeter::Measurement::Processor.new(
    dispatcher: dispatcher,
    logger: logger
  )
  started_at = clock.millis
  logger.puts("OXIMETER_START,address=0x57,duration_ms=#{duration_ms}")
  logger.puts("Place a fingertip steadily over the MAX30102.")

  while clock.millis - started_at < duration_ms
    available = sensor.available_samples
    while available > 0
      sample = sensor.read
      processor.process_sample(
        red: sample[:red],
        ir: sample[:ir],
        timestamp_ms: clock.millis
      )
      available -= 1
    end
    presenter.tick(clock.millis)
    clock.wait_ms(poll_interval_ms)
  end
ensure
  if sensor
    begin
      sensor.shutdown
    rescue => error
      logger.puts("OXIMETER_WARN,shutdown,#{error.class},#{error.message}")
    end
  end
  renderer.clear if renderer
end

logger.puts(sprintf(
  "OXIMETER_DONE,bpm=%.1f,spo2=%.1f",
  processor.latest_bpm, processor.latest_spo2
))
