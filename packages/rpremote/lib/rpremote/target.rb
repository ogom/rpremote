# frozen_string_literal: true

module Rpremote
  class Target
    DEFAULT_LANGUAGE = "picoruby"
    DEFAULT_LANGUAGE_VERSION = "4.0.3"
    DEFAULT_BOARD = "pico2"
    DEFAULT_CACHE_DIR = "firmware"
    IDENTIFIER_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9._-]*\z/

    attr_reader :language, :language_version, :board, :cache_dir

    def initialize(
      language: DEFAULT_LANGUAGE,
      language_version: DEFAULT_LANGUAGE_VERSION,
      board: DEFAULT_BOARD,
      cache_dir: DEFAULT_CACHE_DIR,
      firmware: nil
    )
      @language = validate_identifier(:language, language)
      @language_version = validate_identifier(:language_version, language_version)
      @board = validate_identifier(:board, board)
      @cache_dir = String(cache_dir).gsub("{version}", @language_version)
      @firmware = firmware
      raise ArgumentError, "cache must not be empty" if @cache_dir.empty?
    end

    def source_dir(root: Dir.pwd)
      File.expand_path(File.join(cache_dir, "#{language}-#{language_version}"), root)
    end

    def firmware_path(root: nil)
      path = @firmware || File.join(cache_dir, "#{language}-#{language_version}-#{board}.uf2")
      root ? File.expand_path(path, root) : path
    end

    private

    def validate_identifier(name, value)
      value = String(value)
      return value if IDENTIFIER_PATTERN.match?(value)

      raise ArgumentError, "invalid #{name}: #{value.inspect}"
    end
  end
end
