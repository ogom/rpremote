# frozen_string_literal: true

require "dfu"

puts "DFU app: starting"

# Confirm only after the application has initialized successfully.
DFU.confirm

puts "DFU app: confirmed"
