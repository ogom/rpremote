# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Daisen Kofun mrbgem loading contract" do
  let(:repository_root) { File.expand_path("../../../../../..", __dir__) }
  let(:gem_names) { %w[application runtime oximeter musical illumination] }

  it "embeds every project mrbgem without automatically prepending a require" do
    manifest = File.read(File.join(repository_root, "Mrbgems"))

    gem_names.each do |name|
      path = "examples/picoruby/projects/daisenkofun/mrbgems/daisenkofun-#{name}"
      expect(manifest).to include(%(gem path: "#{path}", auto_require: false))
    end
  end

  it "uses one public require name per mrbgem" do
    gem_names.each do |name|
      rakefile = File.join(DAISENKOFUN_MRBGEMS, "daisenkofun-#{name}", "mrbgem.rake")
      expect(File.read(rakefile)).to include(%(spec.require_name = "daisenkofun-#{name}"))
    end
  end

  it "does not require internal mrbgem files from production source" do
    files = Dir[File.join(DAISENKOFUN_MRBGEMS, "*", "mrblib", "**", "*.rb")]
    internal_requires = files.flat_map do |file|
      File.readlines(file).grep(%r{^require "daisenkofun-[^"]+/}).map { |line| [file, line.strip] }
    end

    expect(internal_requires).to be_empty
  end
end
