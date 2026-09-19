MRuby::Gem::Specification.new("picoruby-bootsel") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Enter the RP2040 or RP2350 USB BOOTSEL mode from PicoRuby"
  spec.require_name = "bootsel"

  spec.add_dependency "picoruby-machine"
end
