# frozen_string_literal: true

require "tmpdir"

RSpec.describe Rpremote::LanguageSource do
  it "downloads and extracts a versioned PicoRuby source archive" do
    Dir.mktmpdir do |root|
      extracted = nil
      source = described_class.new(
        language: "picoruby",
        version: "4.0.3",
        cache_dir: root,
        fetcher: lambda do |url|
          expect(url).to end_with("/tags/4.0.3.zip")
          "zip-data"
        end,
        extractor: lambda do |archive, destination|
          extracted = [archive, destination]
          FileUtils.mkdir_p(File.join(destination, "picoruby-4.0.3"))
        end,
        preparer: ->(_source) {}
      )

      expect(source.setup).to eq(File.join(root, "picoruby-4.0.3"))
      expect(File.binread(File.join(root, "picoruby-4.0.3.zip"))).to eq("zip-data")
      expect(extracted).to eq([File.join(root, "picoruby-4.0.3.zip"), root])
    end
  end

  it "rejects unsupported languages" do
    expect { described_class.new(language: "ruby") }.to raise_error(ArgumentError, /unsupported language/)
  end
end
