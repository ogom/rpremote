# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"

module Rpremote
  class Mrbgems
    DEFAULT_PATH = "Mrbgems"
    DEFAULT_LOCK_PATH = "Mrbgems.lock"
    LOCK_VERSION = 1
    GITHUB_PATTERN = %r{\A[\w.-]+/[\w.-]+\z}
    COMMIT_PATTERN = /\A[0-9a-f]{40,64}\z/i
    VMS = %i[mruby mrubyc].freeze

    Dependency = Data.define(:type, :source, :branch, :commit, :path, :require_name, :auto_require)
    Overlay = Data.define(:path, :fingerprint)

    class Error < Rpremote::Error; end
    class DefinitionError < Error; end
    class LockError < Error; end

    attr_reader :path, :lock_path

    def initialize(path: DEFAULT_PATH, lock_path: nil, cwd: Dir.pwd, resolver: nil)
      @path = File.expand_path(path, cwd)
      @lock_path = File.expand_path(lock_path || DEFAULT_LOCK_PATH, File.dirname(@path))
      @resolver = resolver || method(:resolve_github)
    end

    def exist?
      File.file?(path)
    end

    def dependencies
      @dependencies ||= load_definition
    end

    def vm
      dependencies
      @definition.vm_name
    end

    def check
      dependencies.each { |dependency| validate_local!(dependency) if dependency.type == :path }
      dependencies
    end

    def lock(update: false)
      check
      previous = update ? nil : read_lock(required: false)
      entries = dependencies.map { |dependency| lock_entry(dependency, previous) }
      contents = { "version" => LOCK_VERSION, "vm" => vm&.to_s, "gems" => entries }.compact
      write_json(lock_path, contents)
      contents
    end

    def read_lock(required: true)
      contents = JSON.parse(File.read(lock_path))
      validate_lock!(contents)
      contents
    rescue Errno::ENOENT
      raise LockError, "mrbgems lock file does not exist: #{lock_path}" if required

      nil
    rescue JSON::ParserError => e
      raise LockError, "invalid mrbgems lock file #{lock_path}: #{e.message}"
    end

    def require_names
      lock_data = read_lock(required: false)
      return [] unless lock_data

      lock_data.fetch("gems").filter_map do |gem|
        gem["require_name"] if gem.fetch("auto_require", true)
      end.uniq
    end

    def prepend_requires(source)
      names = require_names
      return source if names.empty?

      names.map { |name| "require #{name.inspect}\n" }.join.b + source.b
    end

    def generate_overlay(base_config:, target:, directory:, update: false)
      lock_data = lock(update: update)
      fingerprint = build_fingerprint(base_config, lock_data)
      output_dir = File.join(File.expand_path(directory), fingerprint)
      output_path = File.join(output_dir, "build_config.rb")
      FileUtils.mkdir_p(output_dir)
      write_file(output_path, overlay_source(base_config, target, lock_data.fetch("gems")))
      Overlay.new(path: output_path, fingerprint: fingerprint)
    end

    private

    attr_reader :resolver

    def load_definition
      dsl = Definition.new(path)
      dsl.instance_eval(File.read(path), path, 1)
      @definition = dsl
      dsl.dependencies.freeze
    rescue Errno::ENOENT
      raise DefinitionError, "mrbgems definition does not exist: #{path}"
    rescue SyntaxError => e
      raise DefinitionError, "invalid mrbgems definition #{path}: #{e.message}"
    rescue DefinitionError
      raise
    rescue StandardError => e
      raise DefinitionError, "cannot load mrbgems definition #{path}: #{e.message}"
    end

    def validate_local!(dependency)
      return if File.file?(File.join(dependency.path, "mrbgem.rake"))

      raise DefinitionError, "local mrbgem has no mrbgem.rake: #{dependency.path}"
    end

    def lock_entry(dependency, previous)
      if dependency.type == :github
        commit = dependency.commit || previous_commit(previous, dependency) || resolver.call(
          dependency.source, dependency.branch
        )
        entry = { "type" => "github", "source" => dependency.source,
                  "branch" => dependency.branch, "commit" => validate_commit!(commit),
                  "require_name" => dependency.require_name }.compact
      else
        entry = { "type" => "path", "source" => dependency.source,
                  "sha256" => digest_directory(dependency.path),
                  "require_name" => dependency.require_name || local_require_name(dependency.path) }.compact
      end
      unless dependency.auto_require
        entry.delete("require_name")
        entry["auto_require"] = false
      end
      entry
    end

    def previous_commit(lock_data, dependency)
      return unless lock_data

      entry = lock_data.fetch("gems").find do |gem|
        gem["type"] == "github" && gem["source"] == dependency.source &&
          gem["branch"] == dependency.branch
      end
      entry&.fetch("commit", nil)
    end

    def validate_commit!(commit)
      value = commit.to_s.downcase
      raise LockError, "invalid Git commit: #{commit.inspect}" unless COMMIT_PATTERN.match?(value)

      value
    end

    def resolve_github(source, branch)
      url = "https://github.com/#{source}.git"
      stdout, stderr, status = Open3.capture3(
        "git", "ls-remote", "--exit-code", url, "refs/heads/#{branch}"
      )
      unless status.success?
        detail = stderr.strip
        detail = "branch not found" if detail.empty?
        raise LockError, "cannot resolve #{source} #{branch}: #{detail}"
      end

      validate_commit!(stdout.split.first)
    rescue Errno::ENOENT
      raise LockError, "git is required to resolve GitHub mrbgems"
    end

    def digest_directory(directory)
      digest = Digest::SHA256.new
      files = Dir.glob(File.join(directory, "**", "*"), File::FNM_DOTMATCH)
                 .select { |file| File.file?(file) }
                 .reject { |file| ignored_local_file?(file, directory) }
                 .sort
      files.each do |file|
        relative = file.delete_prefix("#{directory}/")
        digest.update(relative).update("\0").update(File.binread(file)).update("\0")
      end
      digest.hexdigest
    end

    def ignored_local_file?(file, directory)
      relative = file.delete_prefix("#{directory}/")
      relative.split(File::SEPARATOR).intersect?(%w[.git build tmp])
    end

    def validate_lock!(contents)
      unless contents.is_a?(Hash) && contents["version"] == LOCK_VERSION && contents["gems"].is_a?(Array)
        raise LockError, "unsupported mrbgems lock format: #{lock_path}"
      end
      unless contents["vm"].nil? || VMS.map(&:to_s).include?(contents["vm"])
        raise LockError, "invalid mrbgems VM in lock file: #{contents["vm"].inspect}"
      end

      contents["gems"].each do |entry|
        type = entry["type"]
        valid = type == "github" ? valid_github_lock?(entry) : valid_path_lock?(entry)
        raise LockError, "invalid mrbgems lock entry: #{entry.inspect}" unless valid
      end
    end

    def valid_github_lock?(entry)
      GITHUB_PATTERN.match?(entry["source"].to_s) && !entry["branch"].to_s.empty? &&
        COMMIT_PATTERN.match?(entry["commit"].to_s) && valid_require_name?(entry["require_name"]) &&
        valid_auto_require?(entry)
    end

    def valid_path_lock?(entry)
      entry["type"] == "path" && !entry["source"].to_s.empty? &&
        /\A[0-9a-f]{64}\z/.match?(entry["sha256"].to_s) && valid_require_name?(entry["require_name"]) &&
        valid_auto_require?(entry)
    end

    def valid_require_name?(name)
      name.nil? || (name.is_a?(String) && !name.empty? && !name.match?(/[\x00-\x1f\x7f]/))
    end

    def valid_auto_require?(entry)
      !entry.key?("auto_require") || entry["auto_require"] == true || entry["auto_require"] == false
    end

    def local_require_name(directory)
      source = File.read(File.join(directory, "mrbgem.rake"))
      match = source.match(/^\s*spec\.require_name\s*=\s*["']([^"']+)["']\s*$/)
      match && match[1]
    end

    def build_fingerprint(base_config, lock_data)
      Digest::SHA256.hexdigest(
        [File.binread(path), File.binread(base_config), JSON.generate(lock_data)].join("\0")
      ).slice(0, 12)
    end

    def overlay_source(base_config, target, locked_entries)
      lines = [
        "# Generated by rpremote. Do not edit.",
        "load #{File.expand_path(base_config).inspect}",
        "conf = MRuby.targets.fetch(#{target.inspect})"
      ]
      dependencies.zip(locked_entries).each do |dependency, locked|
        lines << if dependency.type == :github
                   "conf.gem github: #{dependency.source.inspect}, " \
                     "branch: #{dependency.branch.inspect}, checksum_hash: #{locked.fetch("commit").inspect}"
                 else
                   "conf.gem #{dependency.path.inspect}"
                 end
      end
      "#{lines.join("\n")}\n"
    end

    def write_json(filename, contents)
      write_file(filename, "#{JSON.pretty_generate(contents)}\n")
    end

    def write_file(filename, contents)
      return if File.file?(filename) && File.binread(filename) == contents

      FileUtils.mkdir_p(File.dirname(filename))
      temporary = "#{filename}.tmp-#{Process.pid}"
      File.binwrite(temporary, contents)
      File.rename(temporary, filename)
    ensure
      FileUtils.rm_f(temporary) if temporary
    end

    class Definition
      attr_reader :dependencies, :vm_name

      def initialize(filename)
        @directory = File.dirname(filename)
        @dependencies = []
      end

      def vm(name)
        value = name.to_sym
        raise DefinitionError, "unsupported mrbgems VM: #{name.inspect}" unless VMS.include?(value)
        raise DefinitionError, "mrbgems VM specified more than once" if vm_name

        @vm_name = value
      end

      def gem(github: nil, path: nil, branch: "main", commit: nil, require: nil, auto_require: true)
        sources = [github, path].compact
        raise DefinitionError, "gem requires exactly one of github or path" unless sources.length == 1
        unless require.nil? || (require.is_a?(String) && !require.empty? && !require.match?(/[\x00-\x1f\x7f]/))
          raise DefinitionError, "invalid mrbgem require name: #{require.inspect}"
        end

        valid_auto_require = [true, false].include?(auto_require)
        raise DefinitionError, "mrbgem auto_require must be true or false: #{auto_require.inspect}" unless valid_auto_require

        dependency = if github
                       github_dependency(github, branch, commit, require, auto_require)
                     else
                       path_dependency(path, branch, commit, require, auto_require)
                     end
        key = [dependency.type, dependency.source]
        raise DefinitionError, "duplicate mrbgem: #{dependency.source}" if dependencies.any? do |item|
          [item.type, item.source] == key
        end

        dependencies << dependency
      end

      private

      attr_reader :directory

      def github_dependency(source, branch, commit, require_name, auto_require)
        raise DefinitionError, "invalid GitHub mrbgem: #{source.inspect}" unless GITHUB_PATTERN.match?(source.to_s)
        raise DefinitionError, "GitHub mrbgem branch must not be empty" if branch.to_s.empty?
        raise DefinitionError, "invalid Git commit: #{commit.inspect}" if commit && !COMMIT_PATTERN.match?(commit.to_s)

        Dependency.new(type: :github, source: source, branch: branch,
                       commit: commit&.downcase, path: nil, require_name: require_name,
                       auto_require: auto_require)
      end

      def path_dependency(source, branch, commit, require_name, auto_require)
        raise DefinitionError, "local mrbgem path must not be empty" if source.to_s.empty?
        raise DefinitionError, "local mrbgem does not accept branch or commit" if branch != "main" || commit

        Dependency.new(type: :path, source: source, branch: nil, commit: nil,
                       path: File.expand_path(source, directory), require_name: require_name,
                       auto_require: auto_require)
      end
    end
  end
end
