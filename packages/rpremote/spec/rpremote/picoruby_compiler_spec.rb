# frozen_string_literal: true

require "tmpdir"

RSpec.describe "Resolving the PicoRuby host compiler" do
  let(:described_class) { Rpremote::PicoRubyCompiler }

  it "links the PicoRuby 4.0.4 compiler to the path expected by R2P2 CMake" do
    Dir.mktmpdir do |root|
      compiler = File.join(root, "build/mrbc/default/bin/mrbc")
      FileUtils.mkdir_p(File.dirname(compiler))
      FileUtils.touch(compiler)
      FileUtils.chmod("+x", compiler)

      legacy_path = described_class.ensure_legacy_path!(root)

      expect(legacy_path).to eq(File.join(root, "bin/mrbc"))
      expect(File.realpath(legacy_path)).to eq(File.realpath(compiler))
    end
  end

  it "keeps an existing compiler path" do
    Dir.mktmpdir do |root|
      legacy_path = File.join(root, "bin/mrbc")
      FileUtils.mkdir_p(File.dirname(legacy_path))
      FileUtils.touch(legacy_path)
      FileUtils.chmod("+x", legacy_path)

      expect(described_class.ensure_legacy_path!(root)).to eq(legacy_path)
      expect(File.symlink?(legacy_path)).to be(false)
    end
  end

  it "reports when no host compiler was built" do
    Dir.mktmpdir do |root|
      expect { described_class.ensure_legacy_path!(root) }
        .to raise_error(described_class::Error, /mrbc was not built/)
    end
  end
end
