# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-musical") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Beat-event musical component for Daisen Kofun"
  spec.require_name = "daisenkofun-musical"
  spec.add_dependency "picoruby-pwm"

  namespace_file = "#{spec.dir}/mrblib/daisenkofun-musical.rb"
  library_dir = "#{spec.dir}/mrblib/daisenkofun-musical"
  ordered_files = [
    namespace_file,
    "#{library_dir}/translators/pulse.rb",
    "#{library_dir}/translators/timbre.rb",
    "#{library_dir}/planners/kofun_canon.rb",
    "#{library_dir}/planners/heartbeat_signature.rb",
    "#{library_dir}/performance_verification.rb",
    "#{library_dir}/outputs/base.rb",
    "#{library_dir}/outputs/null.rb",
    "#{library_dir}/outputs/pwm.rb",
    "#{library_dir}/outputs/kofun_canon.rb",
    "#{library_dir}/subscriber.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
