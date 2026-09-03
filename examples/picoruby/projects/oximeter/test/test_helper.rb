# frozen_string_literal: true

require "picotest"

$oximeter_test_lib = File.expand_path("../lib", __dir__)

module Kernel
  alias oximeter_original_require require

  def require(name)
    if name.start_with?("/lib/oximeter/")
      relative = name.delete_prefix("/lib/")
      return oximeter_original_require(File.join($oximeter_test_lib, relative))
    end

    oximeter_original_require(name)
  end
end

require "/lib/oximeter/board_clock"
require "/lib/oximeter/console_logger"
require "/lib/oximeter/measurement/processor"
require "/lib/oximeter/sensor_factory"
require "/lib/oximeter/status_led/factory"
require "/lib/oximeter/status_led/presenter"
