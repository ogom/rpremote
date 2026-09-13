# frozen_string_literal: true
MRuby::Gem::Specification.new("picoruby-goryokaku-interaction") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Goryokaku touch and motion events"
  spec.require_name = "goryokaku-interaction"
  spec.add_dependency "picoruby-gpio"
  spec.add_dependency "picoruby-i2c"
  spec.add_dependency "picoruby-mpu6050"

  root = "#{spec.dir}/mrblib"
  lib = "#{root}/goryokaku-interaction"
  ordered = ["#{root}/goryokaku-interaction.rb", "#{lib}/dispatcher.rb", "#{lib}/detector.rb", "#{lib}/device.rb", "#{lib}/runner.rb"]
  spec.rbfiles = ordered + (spec.rbfiles - ordered)
end
