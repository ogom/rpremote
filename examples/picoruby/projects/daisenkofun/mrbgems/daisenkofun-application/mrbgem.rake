# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-application") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Daisen Kofun application composition"
  spec.require_name = "daisenkofun-application"

  spec.add_dependency "picoruby-daisenkofun-runtime"
  spec.add_dependency "picoruby-daisenkofun-illumination"
  spec.add_dependency "picoruby-daisenkofun-musical"
  spec.add_dependency "picoruby-daisenkofun-oximeter"

  namespace_file = "#{spec.dir}/mrblib/daisenkofun-application.rb"
  library_dir = "#{spec.dir}/mrblib/daisenkofun-application"
  ordered_files = [
    namespace_file,
    "#{library_dir}/config.rb",
    "#{library_dir}/validator.rb",
    "#{library_dir}/musical_factory.rb",
    "#{library_dir}/composition.rb",
    "#{library_dir}/verification_reporter.rb",
    "#{library_dir}/runner.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
