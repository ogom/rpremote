# frozen_string_literal: true

require "fileutils"
require "stringio"
require "tmpdir"

RSpec.describe Rpremote::DfuCompiler do
  it "uses the compiler in the selected PicoRuby source and reports its RITE version" do
    Dir.mktmpdir do |directory|
      source_dir = File.join(directory, "firmware", "picoruby-3.4.5")
      compiler = File.join(source_dir, "build/host/bin/picorbc")
      source = File.join(directory, "app.rb")
      destination = File.join(directory, "output", "app.mrb")
      FileUtils.mkdir_p(File.dirname(compiler))
      FileUtils.touch(compiler)
      FileUtils.chmod("+x", compiler)
      File.write(source, "puts :ok\n")
      output = StringIO.new
      runner = lambda do |command, _flag, output_path, input|
        expect(command).to eq(compiler)
        expect(input).to eq(File.expand_path(source))
        File.binwrite(output_path, "RITE0300")
        true
      end
      target = Rpremote::Target.new(language_version: "3.4.5", cache_dir: File.join(directory, "firmware"))

      result = described_class.compile(source, target: target, destination: destination, output: output, runner: runner)

      expect(result).to eq(File.expand_path(destination))
      expect(output.string).to include("compiled RITE0300 app")
    end
  end
end
