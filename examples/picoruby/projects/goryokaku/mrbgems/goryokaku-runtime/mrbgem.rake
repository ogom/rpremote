# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-goryokaku-runtime") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Goryokaku runtime services"
  spec.require_name = "goryokaku-runtime"
  spec.add_dependency "picoruby-machine"

  root = "#{spec.dir}/mrblib"
  lib = "#{root}/goryokaku-runtime"
  ordered = ["#{root}/goryokaku-runtime.rb", "#{lib}/clock.rb", "#{lib}/console_logger.rb", "#{lib}/event_loop.rb"]
  spec.rbfiles = ordered + (spec.rbfiles - ordered)
end
