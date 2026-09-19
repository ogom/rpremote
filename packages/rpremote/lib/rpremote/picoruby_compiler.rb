# frozen_string_literal: true

require "fileutils"

module Rpremote
  class PicoRubyCompiler
    class Error < StandardError; end

    CANDIDATES = %w[
      build/mrbc/default/bin/mrbc
      build/host/bin/mrbc
    ].freeze

    def self.ensure_legacy_path!(root)
      root = File.expand_path(root)
      legacy_path = File.join(root, "bin/mrbc")
      return legacy_path if File.executable?(legacy_path)

      compiler = CANDIDATES.map { |path| File.join(root, path) }.find { |path| File.executable?(path) }
      raise Error, "PicoRuby mrbc was not built under #{root}" unless compiler

      FileUtils.mkdir_p(File.dirname(legacy_path))
      relative = File.join("..", compiler.delete_prefix("#{root}/"))
      FileUtils.ln_sf(relative, legacy_path)
      legacy_path
    end
  end
end
