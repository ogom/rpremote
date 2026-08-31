# frozen_string_literal: true

MRuby::Gem::Specification.new("picoruby-daisenkofun-illuminations") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Daisen Kofun WS2812 illumination patterns"
  spec.require_name = "daisenkofun-illuminations"

  spec.add_dependency "picoruby-ws2812-plus"

  base_file = "#{spec.dir}/mrblib/daisenkofun/illuminations/base.rb"
  spec.rbfiles = [base_file] + (spec.rbfiles - [base_file])

  if build.femtoruby?
    picogem_name = spec.name.sub(/\Apicoruby-?/, "")
    picogem_file = "#{spec.build_dir}/mrblib/#{picogem_name}.c"
    file picogem_file => spec.rbfiles
  end
end
