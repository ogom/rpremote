# frozen_string_literal: true

require_relative "lib/rpremote/version"

Gem::Specification.new do |spec|
  spec.name = "rpremote"
  spec.version = Rpremote::VERSION
  spec.authors = ["ogom"]
  spec.email = ["ogom@users.noreply.github.com"]

  spec.summary = "Build and control custom PicoRuby firmware on Raspberry Pi Pico"
  spec.description = "Embed public or local mrbgems in reproducible R2P2 firmware, flash it, and control the device."
  spec.homepage = "https://github.com/ogom/rpremote"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/packages/rpremote"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir.glob("{exe,lib,sig,tasks}/**/*", File::FNM_DOTMATCH).select { |file| File.file?(file) } +
      %w[CHANGELOG.md LICENSE README.md README.ja.md RELEASING.md THIRD_PARTY_NOTICES.md]
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
