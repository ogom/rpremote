MRuby::Gem::Specification.new("picoruby-max30102") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "MAX30102 pulse oximeter and heart-rate sensor driver for PicoRuby"
  spec.require_name = "max30102"
  spec.add_dependency "picoruby-i2c"
end
