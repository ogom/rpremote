# frozen_string_literal: true

require "rbconfig"
require "fileutils"
require "rubygems/version"
require_relative "mrbgems"

module Rpremote
  class Builder
    class Error < Rpremote::Error; end

    def initialize(root: Dir.pwd, runner: nil, mrbgems_class: Mrbgems)
      @root = File.expand_path(root)
      @runner = runner || method(:run_command)
      @mrbgems_class = mrbgems_class
    end

    def build(output: $stdout, error: $stderr, **options)
      target = Target.new(**options.slice(:language, :language_version, :board, :cache_dir, :firmware))
      script = File.expand_path("../../tasks/firmware_build.rb", __dir__)
      raise Error, "rpremote installation has no firmware build script: #{script}" unless File.file?(script)

      Language.validate!(target.language)

      source_dir = source_for(target)
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

    attr_reader :root, :runner, :mrbgems_class

    def add_mrbgems_environment!(environment, options, source_dir, output)
      definition = mrbgems_definition(options[:mrbgems])
      return unless definition

      manager = mrbgems_class.new(path: definition, cwd: root)
      config_language = mrbgems_config_language(
        manager.vm, options.fetch(:language), options.fetch(:language_version)
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
      output.puts("using Mrbgems: #{manager.path}")
      output.puts("using Mrbgems.lock: #{manager.lock_path}")
    end

    def mrbgems_config_language(vm_name, language, version)
      return language unless vm_name

      modern = Gem::Version.new(version) >= Gem::Version.new("4.0.0")
      return modern ? "femtoruby" : "picoruby" if vm_name == :mrubyc

      modern ? "picoruby" : "microruby"
    end

    def mrbgems_definition(option)
      return if option == false

      candidate = File.expand_path(option || Mrbgems::DEFAULT_PATH, root)
      return candidate if File.file?(candidate)
      raise Error, "mrbgems definition does not exist: #{candidate}" if option

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
