MRuby::Gem::Specification.new("picoruby-bmi270") do |spec|
  spec.license = "MIT AND BSD-3-Clause"
  spec.author = "ogom"
  spec.summary = "BMI270 six-axis IMU driver for PicoRuby"
  spec.require_name = "bmi270"
  spec.add_dependency "picoruby-i2c"
end
