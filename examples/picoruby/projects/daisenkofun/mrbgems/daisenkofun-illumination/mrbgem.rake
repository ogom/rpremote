# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-illumination") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Daisen Kofun WS2812 illumination patterns"
  spec.require_name = "daisenkofun-illumination"

  spec.add_dependency "picoruby-ws2812-plus"

  namespace_file = "#{spec.dir}/mrblib/daisenkofun-illumination.rb"
  library_dir = "#{spec.dir}/mrblib/daisenkofun-illumination"
  config_file = "#{library_dir}/config.rb"
  color_file = "#{library_dir}/color.rb"
  layout_file = "#{library_dir}/led_layout.rb"
  display_file = "#{library_dir}/display.rb"
  device_file = "#{library_dir}/device.rb"
  biometric_player_file = "#{library_dir}/biometric_player.rb"
  player_file = "#{library_dir}/player.rb"
  base_file = "#{library_dir}/patterns/base.rb"
  pattern_files = spec.rbfiles.select { |path| path.start_with?("#{library_dir}/patterns/") }
                              .reject { |path| path == base_file }
                              .sort
  biometric_base_file = "#{library_dir}/biometrics/base.rb"
  biometric_files = spec.rbfiles.select { |path| path.start_with?("#{library_dir}/biometrics/") }
                                .reject { |path| path == biometric_base_file }
                                .sort
  setlist_file = "#{library_dir}/setlist.rb"
  ordered_files = [
    namespace_file,
    config_file,
    color_file,
    layout_file,
    display_file,
    device_file,
    base_file,
    *pattern_files,
    biometric_base_file,
    *biometric_files,
    setlist_file,
    player_file,
    biometric_player_file
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)

  if build.femtoruby?
    picogem_name = spec.name.sub(/\Apicoruby-?/, "")
    picogem_file = "#{spec.build_dir}/mrblib/#{picogem_name}.c"
    file picogem_file => spec.rbfiles
  end
end
