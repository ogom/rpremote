# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"

module Rpremote
  class Mrbgems
    DEFAULT_PATH = "Mrbgems"
    DEFAULT_LOCK_PATH = "Mrbgems.lock"
    LOCK_VERSION = 2
    GITHUB_PATTERN = %r{\A[\w.-]+/[\w.-]+\z}
    COMMIT_PATTERN = /\A[0-9a-f]{40,64}\z/i
    GROUP_PATTERN = /\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/
    VMS = %i[mruby mrubyc].freeze

    Dependency = Data.define(:type, :source, :branch, :commit, :path, :require_name, :auto_require, :groups)
    Overlay = Data.define(:path, :fingerprint)

    class Error < Rpremote::Error; end
    class DefinitionError < Error; end
    class LockError < Error; end

    attr_reader :path, :lock_path

    def initialize(path: DEFAULT_PATH, lock_path: nil, cwd: Dir.pwd, resolver: nil)
      @path = File.expand_path(path, cwd)
      @lock_path = if lock_path
                     File.expand_path(lock_path, cwd)
                   else
                     File.expand_path(DEFAULT_LOCK_PATH, File.dirname(@path))
                   end
      @resolver = resolver || method(:resolve_github)
    end

    def self.parse_groups(value)
      groups = value.to_s.split(",", -1).map(&:strip)
      raise DefinitionError, "invalid mrbgem group: #{value.inspect}" if groups.empty?

      normalize_groups(groups)
    end

    def self.normalize_groups(values)
      Array(values).map do |name|
        value = name.to_s
        raise DefinitionError, "invalid mrbgem group: #{name.inspect}" unless GROUP_PATTERN.match?(value)

        value.to_sym
      end.uniq.freeze
    end

    def exist?
      File.file?(path)
    end

    def dependencies
      @dependencies ||= load_definition
    end

    def selected_dependencies(with: [], without: [])
      selected_groups = self.class.normalize_groups(with)
      excluded_groups = self.class.normalize_groups(without)
      dependencies
      available = @definition.groups
      validate_selected_groups!(selected_groups + excluded_groups, available)
      dependencies.select do |dependency|
        dependency.groups.empty? ||
          (dependency.groups.intersect?(selected_groups) && !dependency.groups.intersect?(excluded_groups))
      end
    end

    def vm
      dependencies
      @definition.vm_name
    end

    def check
      dependencies.each { |dependency| validate_local!(dependency) if dependency.type == :path }
      dependencies
    end

    def lock(update: false, with: [], without: [])
      selected_groups = self.class.normalize_groups(with)
      excluded_groups = self.class.normalize_groups(without)
      previous = update ? nil : read_previous_lock
      selected = selected_dependencies(with: selected_groups, without: excluded_groups)
      selected.each { |dependency| validate_local!(dependency) if dependency.type == :path }
      entries = selected.map do |dependency|
        lock_entry(dependency, previous)
      end
      contents = {
        "version" => LOCK_VERSION,
        "vm" => vm&.to_s,
        "with" => selected_groups.map(&:to_s),
        "without" => excluded_groups.map(&:to_s),
        "gems" => entries
      }.compact
      validate_lock!(contents)
      write_json(lock_path, contents)
      contents
    end

    def generate_overlay(base_config:, target:, directory:)
      lock_data = read_lock
      entries = lock_data.fetch("gems")
      validate_locked_paths!(entries)
      fingerprint = build_fingerprint(base_config, lock_data)
      output_dir = File.join(File.expand_path(directory), fingerprint)
      output_path = File.join(output_dir, "build_config.rb")
      FileUtils.mkdir_p(output_dir)
      write_file(output_path, overlay_source(base_config, target, entries))
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
        entry = { "type" => "path", "source" => locked_path(dependency.path),
                  "sha256" => digest_directory(dependency.path),
                  "require_name" => dependency.require_name || local_require_name(dependency.path) }.compact
      end
      unless dependency.auto_require
        entry.delete("require_name")
        entry["auto_require"] = false
      end
      entry["groups"] = dependency.groups.map(&:to_s) unless dependency.groups.empty?
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

    def read_previous_lock
      contents = JSON.parse(File.read(lock_path))
      raise LockError, "invalid mrbgems lock file: #{lock_path}" unless contents.is_a?(Hash)

      version = contents["version"]
      supported = [1, LOCK_VERSION].include?(version) && contents["gems"].is_a?(Array)
      raise LockError, "unsupported mrbgems lock format: #{lock_path}" unless supported

      if version == LOCK_VERSION
        validate_lock!(contents)
      elsif contents["gems"].any? { |entry| !entry.is_a?(Hash) }
        raise LockError, "invalid mrbgems lock file: #{lock_path}"
      end
      contents
    rescue Errno::ENOENT
      nil
    rescue JSON::ParserError => e
      raise LockError, "invalid mrbgems lock file #{lock_path}: #{e.message}"
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

    def local_require_name(directory)
      source = File.read(File.join(directory, "mrbgem.rake"))
      match = source.match(/^\s*spec\.require_name\s*=\s*["']([^"']+)["']\s*$/)
      match && match[1]
    end

    def build_fingerprint(base_config, lock_data)
      Digest::SHA256.hexdigest(
        [File.binread(base_config), JSON.generate(lock_data)].join("\0")
      ).slice(0, 12)
    end

    def overlay_source(base_config, target, locked_entries)
      lines = [
        "# frozen_string_literal: true",
        "",
        "# Generated by rpremote. Do not edit.",
        "load #{File.expand_path(base_config).inspect}",
        "conf = MRuby.targets.fetch(#{target.inspect})"
      ]
      locked_entries.each do |locked|
        lines << if locked.fetch("type") == "github"
                   "conf.gem github: #{locked.fetch("source").inspect}, " \
                     "branch: #{locked.fetch("branch").inspect}, checksum_hash: #{locked.fetch("commit").inspect}"
                 else
                   "conf.gem #{resolved_locked_path(locked).inspect}"
                 end
      end
      "#{lines.join("\n")}\n"
    end

    def locked_path(directory)
      Pathname.new(directory).relative_path_from(Pathname.new(File.dirname(lock_path))).to_s
    end

    def validate_selected_groups!(selected, available)
      unknown = selected - available
      raise DefinitionError, "unknown mrbgem group: #{unknown.join(", ")}" unless unknown.empty?
    end
  end
end

require_relative "mrbgems/file_writer"
require_relative "mrbgems/lockfile"
require_relative "mrbgems/definition"
