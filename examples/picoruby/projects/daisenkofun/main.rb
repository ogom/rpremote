# frozen_string_literal: true

require "daisenkofun-illuminations"

run_mode = :short
only_key = :structure_guide

puts "daisenkofun: start"

begin
  Daisenkofun::Illumination.new.call(run_mode, only_key)
  puts "daisenkofun: OK"
rescue => error
  puts "daisenkofun: ERROR #{error.message}"
end
