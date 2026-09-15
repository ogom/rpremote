# frozen_string_literal: true

OXIMETER_ROOT = File.expand_path("..", __dir__)
OXIMETER_LIB = File.join(OXIMETER_ROOT, "lib")

$LOAD_PATH.unshift(File.join(OXIMETER_ROOT, "test", "mock"))

module OximeterSpecRequire
  def require(name)
    return super(File.join(OXIMETER_LIB, name.delete_prefix("/lib/"))) if name.start_with?("/lib/oximeter/")

    super
  end

  private :require
end

Kernel.prepend(OximeterSpecRequire)

require "/lib/oximeter/board_clock"
require "/lib/oximeter/config"
require "/lib/oximeter/console_logger"
require "/lib/oximeter/dispatcher"
require "/lib/oximeter/measurement/processor"
require "/lib/oximeter/sensor_factory"
require "/lib/oximeter/status_led/factory"
require "/lib/oximeter/status_led/presenter"

module OximeterSpec
  class Collector
    attr_reader :events

    def initialize
      @events = []
    end

    def call(event, payload)
      @events << [event, payload]
    end
  end

  class Pixels
    attr_reader :values, :show_count, :clear_count

    def initialize(count = Oximeter::Config::LED_COUNT)
      @values = Array.new(count) { [0, 0, 0] }
      @show_count = 0
      @clear_count = 0
    end

    def fill(red, green, blue)
      @values.map! { [red, green, blue] }
      self
    end

    def set_rgb(index, red, green, blue)
      @values[index] = [red, green, blue]
      self
    end

    def show
      @show_count += 1
      self
    end

    def clear
      @values.map! { [0, 0, 0] }
      @clear_count += 1
      self
    end
  end

  class Renderer
    attr_reader :frames

    def initialize
      @frames = []
    end

    def render(mode, timestamp_ms, **values)
      @frames << [mode, timestamp_ms, values]
    end
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.order = :random
end
