MRuby::Gem::Specification.new("picoruby-mpu6050") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "MPU6050 six-axis motion sensor driver for PicoRuby"
  spec.require_name = "mpu6050"

  spec.add_dependency "picoruby-i2c"
end
