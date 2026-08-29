MRuby::Gem::Specification.new("picoruby-hcsr04_temp") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "HCSR04Temp ultrasonic distance sensor driver for PicoRuby"
  spec.require_name = "hcsr04_temp"
  spec.add_dependency "picoruby-gpio"
  spec.add_dependency "picoruby-machine"
end
