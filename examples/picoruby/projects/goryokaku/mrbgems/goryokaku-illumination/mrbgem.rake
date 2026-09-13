# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-goryokaku-illumination") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Goryokaku WS2812 illumination effects"
  spec.require_name = "goryokaku-illumination"

  spec.add_dependency "picoruby-ws2812-plus"

  namespace_file = "#{spec.dir}/mrblib/goryokaku-illumination.rb"
  library_dir = "#{spec.dir}/mrblib/goryokaku-illumination"
  config_file = "#{library_dir}/config.rb"
  color_file = "#{library_dir}/color.rb"
  layout_file = "#{library_dir}/led_layout.rb"
  display_file = "#{library_dir}/display.rb"
  device_file = "#{library_dir}/device.rb"
  base_file = "#{library_dir}/patterns/base.rb"
  pattern_files = spec.rbfiles.select { |path| path.start_with?("#{library_dir}/patterns/") }
                              .reject { |path| path == base_file }
                              .sort
  setlist_file = "#{library_dir}/setlist.rb"
  player_file = "#{library_dir}/player.rb"
  interactive_player_file = "#{library_dir}/interactive_player.rb"
  tambourine_player_file = "#{library_dir}/tambourine_player.rb"
  ordered_files = [
    namespace_file,
    config_file,
    color_file,
    layout_file,
    display_file,
    device_file,
    base_file,
    *pattern_files,
    setlist_file,
    player_file,
    tambourine_player_file,
    interactive_player_file
  ]
  spec.rbfiles = ordered_files + (spec.rbfiles - ordered_files)

  if build.femtoruby?
    picogem_name = spec.name.sub(/\Apicoruby-?/, "")
    picogem_file = "#{spec.build_dir}/mrblib/#{picogem_name}.c"
    file picogem_file => spec.rbfiles
  end
end
