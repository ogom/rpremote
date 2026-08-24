# frozen_string_literal: true

require "fileutils"

module Rpremote
  class DfuCompiler
    class Error < Rpremote::Error; end

    def self.compile(source, target:, destination: nil, output: $stdout, runner: nil)
      raise Error, "DFU bytecode compilation currently supports only picoruby" unless target.language == "picoruby"
      raise ArgumentError, "DFU source must have a .rb extension" unless File.extname(source).downcase == ".rb"

      source = File.expand_path(source)
      raise ArgumentError, "DFU source file not found: #{source}" unless File.file?(source)

      compiler = find_compiler(target.source_dir)
      destination ||= source.sub(/\.rb\z/i, ".mrb")
      destination = File.expand_path(destination)
      FileUtils.mkdir_p(File.dirname(destination))
      success = (runner || method(:run)).call(compiler, "-o", destination, source)
      raise Error, "PicoRuby compiler failed: #{compiler}" unless success

      rite_version = rite_version(File.binread(destination, 8))
      output.puts("compiled #{rite_version} app: #{source} -> #{destination}")
      destination
    end

    def self.find_compiler(source_dir)
      %w[picorbc mrbc].each do |name|
        path = File.join(source_dir, "build/host/bin", name)
        return path if File.executable?(path)
      end
      raise Error, "PicoRuby compiler is not built in #{source_dir}; build the selected PicoRuby source first"
    end
    private_class_method :find_compiler

    def self.run(*command)
      system(*command)
    end
    private_class_method :run

    def self.rite_version(data)
      version = data.b.byteslice(0, 8)
      return version if version&.match?(/\ARITE\d{4}\z/)

      raise Error, "PicoRuby compiler did not produce a RITE bytecode file"
    end
    private_class_method :rite_version
  end
end
