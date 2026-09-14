# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Goryokaku mrbgem loading contract" do
  let(:gem_names) { %w[application runtime interaction musical illumination] }

  it "uses one public require name per project mrbgem" do
    gem_names.each do |name|
      rakefile = File.join(GORYOKAKU_MRBGEMS, "goryokaku-#{name}", "mrbgem.rake")
      expect(File.read(rakefile)).to include(%(spec.require_name = "goryokaku-#{name}"))
    end
  end

  it "declares application and hardware dependencies in mrbgem metadata" do
    application = File.read(File.join(GORYOKAKU_MRBGEMS, "goryokaku-application", "mrbgem.rake"))
    interaction = File.read(File.join(GORYOKAKU_MRBGEMS, "goryokaku-interaction", "mrbgem.rake"))

    %w[runtime interaction illumination musical].each do |name|
      expect(application).to include(%(spec.add_dependency "picoruby-goryokaku-#{name}"))
    end
    %w[gpio i2c mpu6050].each do |name|
      expect(interaction).to include(%(spec.add_dependency "picoruby-#{name}"))
    end
  end

  it "does not require internal mrbgem files from production source" do
    files = Dir[File.join(GORYOKAKU_MRBGEMS, "*", "mrblib", "**", "*.rb")]
    internal_requires = files.flat_map do |file|
      File.readlines(file).grep(%r{^require "goryokaku-[^"]+/}).map { |line| [file, line.strip] }
    end

    expect(internal_requires).to be_empty
  end
end
