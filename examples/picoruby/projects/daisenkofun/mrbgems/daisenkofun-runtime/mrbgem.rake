# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-runtime") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Daisen Kofun runtime services"
  spec.require_name = "daisenkofun-runtime"
  spec.add_dependency "picoruby-machine"

  namespace_file = "#{spec.dir}/mrblib/daisenkofun-runtime.rb"
  library_dir = "#{spec.dir}/mrblib/daisenkofun-runtime"
  ordered_files = [
    namespace_file,
    "#{library_dir}/clock.rb",
    "#{library_dir}/console_logger.rb",
    "#{library_dir}/event_loop.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
