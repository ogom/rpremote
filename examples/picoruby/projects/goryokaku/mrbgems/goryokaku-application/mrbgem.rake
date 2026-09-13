# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-goryokaku-application") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Goryokaku interactive illumination application"
  spec.require_name = "goryokaku-application"

  spec.add_dependency "picoruby-goryokaku-runtime"
  spec.add_dependency "picoruby-goryokaku-interaction"
  spec.add_dependency "picoruby-goryokaku-illumination"
  spec.add_dependency "picoruby-goryokaku-musical"

  namespace_file = "#{spec.dir}/mrblib/goryokaku-application.rb"
  library_dir = "#{spec.dir}/mrblib/goryokaku-application"
  ordered_files = [
    namespace_file,
    "#{library_dir}/config.rb",
    "#{library_dir}/validator.rb",
    "#{library_dir}/composition.rb",
    "#{library_dir}/runner.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
