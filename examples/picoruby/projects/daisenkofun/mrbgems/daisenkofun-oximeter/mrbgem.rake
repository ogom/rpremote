# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-oximeter") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Daisen Kofun MAX30102 oximeter application"
  spec.require_name = "daisenkofun-oximeter"

  spec.add_dependency "picoruby-machine"
  spec.add_dependency "picoruby-max30102"
  spec.add_dependency "picoruby-ws2812_spi"
  spec.add_dependency "picoruby-daisenkofun-runtime"

  namespace_file = "#{spec.dir}/mrblib/daisenkofun-oximeter.rb"
  library_dir = "#{spec.dir}/mrblib/daisenkofun-oximeter"
  ordered_files = [
    namespace_file,
    "#{library_dir}/config.rb",
    "#{library_dir}/dispatcher.rb",
    "#{library_dir}/measurement/events.rb",
    "#{library_dir}/measurement/rolling_sample_window.rb",
    "#{library_dir}/measurement/finger_detector.rb",
    "#{library_dir}/measurement/beat_detector.rb",
    "#{library_dir}/measurement/pulse_shape_extractor.rb",
    "#{library_dir}/measurement/spo2_estimator.rb",
    "#{library_dir}/measurement/session.rb",
    "#{library_dir}/measurement/processor.rb",
    "#{library_dir}/status_led/states.rb",
    "#{library_dir}/status_led/renderer.rb",
    "#{library_dir}/status_led/null_renderer.rb",
    "#{library_dir}/status_led/presenter.rb",
    "#{library_dir}/status_led/factory.rb",
    "#{library_dir}/sensor_factory.rb",
    "#{library_dir}/device.rb",
    "#{library_dir}/runner.rb"
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)
end
