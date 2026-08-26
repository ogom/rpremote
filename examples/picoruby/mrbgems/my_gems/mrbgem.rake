MRuby::Gem::Specification.new("picoruby-my_gems") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "Local mrbgem example for rpremote"
  spec.require_name = "my_gems"

  spec.add_dependency "picoruby-gpio"
end
