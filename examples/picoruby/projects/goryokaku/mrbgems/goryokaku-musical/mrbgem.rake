# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-goryokaku-musical") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Goryokaku PWM buzzer music"
  spec.require_name = "goryokaku-musical"

  spec.add_dependency "picoruby-pwm"

  namespace_file = "#{spec.dir}/mrblib/goryokaku-musical.rb"
  library_dir = "#{spec.dir}/mrblib/goryokaku-musical"
  ordered_files = [
    namespace_file,
    "#{library_dir}/cues.rb",
    "#{library_dir}/outputs/base.rb",
    "#{library_dir}/outputs/null.rb",
    "#{library_dir}/outputs/pwm.rb",
    "#{library_dir}/tambourine_detector.rb",
    "#{library_dir}/gesture_publisher.rb",
    "#{library_dir}/subscriber.rb",
    "#{library_dir}/buzzer.rb",
    "#{library_dir}/illumination_soundtrack.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
