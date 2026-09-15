# frozen_string_literal: true

require "rpremote"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.order = :defined

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
