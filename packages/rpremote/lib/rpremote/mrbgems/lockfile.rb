# frozen_string_literal: true

module Rpremote
  class Mrbgems
    module Lockfile
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

      def locked_vm
        read_lock.fetch("vm", nil)&.to_sym
      end

      private

      def validate_lock!(contents)
        validate_lock_header!(contents)
        validate_lock_entries!(contents)
      end

      def validate_lock_header!(contents)
        unless contents.is_a?(Hash) && contents["version"] == LOCK_VERSION
          raise LockError,
                "unsupported mrbgems lock format: #{lock_path}; " \
                "run `rpremote mrbgems lock` to regenerate it"
        end
        excluded = contents.fetch("without", [])
        unless contents["gems"].is_a?(Array) && contents["with"].is_a?(Array) && excluded.is_a?(Array) &&
               valid_groups?(contents["with"]) && valid_groups?(excluded)
          raise LockError, "invalid mrbgems lock file: #{lock_path}"
        end
        return if contents["vm"].nil? || VMS.map(&:to_s).include?(contents["vm"])

        raise LockError, "invalid mrbgems VM in lock file: #{contents["vm"].inspect}"
      end

      def validate_lock_entries!(contents)
        contents["gems"].each do |entry|
          type = entry["type"] if entry.is_a?(Hash)
          valid = entry.is_a?(Hash) && (type == "github" ? valid_github_lock?(entry) : valid_path_lock?(entry))
          valid &&= valid_groups?(entry["groups"])
          valid &&= entry_groups_selected?(entry, contents["with"], contents.fetch("without", []))
          raise LockError, "invalid mrbgems lock entry: #{entry.inspect}" unless valid
        end
        keys = contents["gems"].map { |entry| [entry["type"], entry["source"]] }
        raise LockError, "duplicate mrbgems lock entries: #{lock_path}" unless keys.uniq.length == keys.length
      end

      def valid_github_lock?(entry)
        entry["source"].is_a?(String) && GITHUB_PATTERN.match?(entry["source"]) &&
          entry["branch"].is_a?(String) && !entry["branch"].empty? &&
          !entry["branch"].match?(/[\x00-\x1f\x7f]/) && entry["commit"].is_a?(String) &&
          COMMIT_PATTERN.match?(entry["commit"]) &&
          valid_require_name?(entry["require_name"]) &&
          valid_auto_require?(entry)
      end

      def valid_path_lock?(entry)
        entry["type"] == "path" && entry["source"].is_a?(String) && !entry["source"].empty? &&
          !entry["source"].start_with?(File::SEPARATOR) && !entry["source"].match?(/[\x00-\x1f\x7f]/) &&
          entry["sha256"].is_a?(String) && /\A[0-9a-f]{64}\z/.match?(entry["sha256"]) &&
          valid_require_name?(entry["require_name"]) &&
          valid_auto_require?(entry)
      end

      def valid_require_name?(name)
        name.nil? || (name.is_a?(String) && !name.empty? && !name.match?(/[\x00-\x1f\x7f]/))
      end

      def valid_auto_require?(entry)
        !entry.key?("auto_require") || entry["auto_require"] == true || entry["auto_require"] == false
      end

      def valid_groups?(groups)
        groups.nil? || (groups.is_a?(Array) && groups.uniq.length == groups.length &&
          groups.all? { |name| name.is_a?(String) && GROUP_PATTERN.match?(name) })
      end

      def entry_groups_selected?(entry, selected, excluded)
        groups = Array(entry["groups"])
        groups.empty? || (groups.intersect?(selected) && !groups.intersect?(excluded))
      end

      def validate_locked_paths!(entries)
        entries.select { |entry| entry["type"] == "path" }.each do |entry|
          directory = resolved_locked_path(entry)
          raise LockError, "locked local mrbgem does not exist: #{directory}" unless mrbgem_directory?(directory)
          next if digest_directory(directory) == entry.fetch("sha256")

          raise LockError,
                "locked local mrbgem has changed: #{directory}; " \
                "run `rpremote mrbgems lock` to update #{lock_path}"
        end
      end

      def mrbgem_directory?(directory)
        File.file?(File.join(directory, "mrbgem.rake"))
      end

      def resolved_locked_path(entry)
        File.expand_path(entry.fetch("source"), File.dirname(lock_path))
      end
    end

    include Lockfile
  end
end
