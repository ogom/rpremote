MRuby::Gem::Specification.new("picoruby-ws2812_spi") do |spec|
  spec.license = "MIT"
  spec.author = "ogom"
  spec.summary = "SPI-driven WS2812 LED driver for PicoRuby"
  spec.require_name = "ws2812_spi"
  spec.add_dependency "picoruby-spi"
end
