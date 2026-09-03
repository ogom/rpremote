# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-oximeter") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Daisen Kofun MAX30102 oximeter application"
  spec.require_name = "daisenkofun-oximeter"

  spec.add_dependency "picoruby-machine"
  spec.add_dependency "picoruby-max30102"
  spec.add_dependency "picoruby-ws2812_spi"
end
