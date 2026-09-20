# frozen_string_literal: true

require "rbconfig"
require "fileutils"
require "rubygems/version"
require_relative "mrbgems"
require_relative "picoruby_source_patch"

module Rpremote
  class Builder
    class Error < Rpremote::Error; end

    def initialize(root: Dir.pwd, runner: nil, mrbgems_class: Mrbgems, source_patcher: nil)
      @root = File.expand_path(root)
      @runner = runner || method(:run_command)
      @mrbgems_class = mrbgems_class
      @source_patcher = source_patcher || method(:patch_source)
    end

    def build(output: $stdout, error: $stderr, **options)
      target = Target.new(**options.slice(:language, :language_version, :board, :cache_dir, :firmware))
      script = File.expand_path("../../tasks/firmware_build.rb", __dir__)
      raise Error, "rpremote installation has no firmware build script: #{script}" unless File.file?(script)

      Language.validate!(target.language)

      source_dir = source_for(target)
      source_patcher.call(source_dir, target.language_version)
      environment = {
        "RPREMOTE_LANGUAGE" => target.language,
        "RPREMOTE_LANGUAGE_VERSION" => target.language_version,
        "RPREMOTE_BOARD" => target.board,
        "RPREMOTE_ROOT" => root,
        "PICORUBY_DIR" => source_dir
      }
      build_options = options.merge(
        language: target.language,
        language_version: target.language_version,
        board: target.board
      )
      add_mrbgems_environment!(environment, build_options, source_dir, output)
      environment["RPREMOTE_FIRMWARE"] = target.firmware_path(root: root)
      success = runner.call(
        environment,
        RbConfig.ruby,
        script,
        chdir: root,
        out: output,
        err: error
      )
      raise Error, "custom firmware build failed" unless success
    end

    def clean(output: $stdout)
      directory = File.join(root, "build")
      unless File.directory?(directory)
        output.puts("no build files: #{directory}")
        return
      end

      FileUtils.rm_rf(directory)
      output.puts("removed build files: #{directory}")
    end

    private

    attr_reader :root, :runner, :mrbgems_class, :source_patcher

    def patch_source(source, version)
      PicoRubySourcePatch.new(version: version).apply(source)
    end

    def add_mrbgems_environment!(environment, options, source_dir, output)
      lock_file = mrbgems_lock(options[:mrbgems_lock])
      return unless lock_file

      manager = mrbgems_class.new(lock_path: lock_file, cwd: root)
      config_language = mrbgems_config_language(
        manager.locked_vm, options.fetch(:language), options.fetch(:language_version)
      )
      config_name = "r2p2-#{config_language}-#{options.fetch(:board)}"
      base_config = File.join(source_dir, "build_config", "#{config_name}.rb")
      raise Error, "PicoRuby build config not found: #{base_config}" unless File.file?(base_config)

      overlay = manager.generate_overlay(
        base_config: base_config,
        target: config_name,
        directory: File.join(root, "build", "mrbgems")
      )
      environment["RPREMOTE_CONFIG_NAME"] = config_name
      environment["RPREMOTE_MRUBY_CONFIG"] = overlay.path
      environment["RPREMOTE_MRBGEMS_FINGERPRINT"] = overlay.fingerprint
      output.puts("using Mrbgems.lock: #{manager.lock_path}")
    end

    def mrbgems_config_language(vm_name, language, version)
      return language unless vm_name

      modern = version == "latest" || Gem::Version.new(version) >= Gem::Version.new("4.0.0")
      return modern ? "femtoruby" : "picoruby" if vm_name == :mrubyc

      modern ? "picoruby" : "microruby"
    end

    def mrbgems_lock(option)
      return if option == false

      candidate = File.expand_path(option || Mrbgems::DEFAULT_LOCK_PATH, root)
      return candidate if File.file?(candidate)
      raise Error, "mrbgems lock file does not exist: #{candidate}" if option

      definition = File.join(root, Mrbgems::DEFAULT_PATH)
      if File.file?(definition)
        raise Error,
              "Mrbgems.lock does not exist: #{candidate}; " \
              "run `rpremote mrbgems lock` before building"
      end

      nil
    end

    def source_for(target)
      source = target.source_dir(root: root)
      return source if File.directory?(source)

      raise Error,
            "#{target.language} #{target.language_version} source not found: #{source}\n" \
            "Run `rpremote setup --language #{target.language} " \
            "--language-version #{target.language_version} --cache #{target.cache_dir}` first."
    end

    def run_command(...)
      system(...)
    end
  end
end
