# frozen_string_literal: true

require "dfu"

puts "DFU rollback test: intentionally not confirmed"

# Do not call DFU.confirm here. This application is only for verifying that
# R2P2 returns to the previously confirmed slot after max_boot_attempts.
