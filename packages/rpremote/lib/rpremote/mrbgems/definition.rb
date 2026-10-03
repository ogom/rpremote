# frozen_string_literal: true

module Rpremote
  class Mrbgems
    class Definition
      GEM_OPTIONS = { commit: nil, require: nil, auto_require: true, group: nil }.freeze

      attr_reader :dependencies, :groups, :vm_name

      def initialize(filename)
        @directory = File.dirname(filename)
        @dependencies = []
        @groups = []
        @group_stack = []
      end

      def vm(name)
        value = name.to_sym
        raise DefinitionError, "unsupported mrbgems VM: #{name.inspect}" unless VMS.include?(value)
        raise DefinitionError, "mrbgems VM specified more than once" if vm_name

        @vm_name = value
      end

      def gem(github: nil, path: nil, branch: "main", **options)
        settings = gem_settings(options)
        sources = [github, path].compact
        raise DefinitionError, "gem requires exactly one of github or path" unless sources.length == 1

        groups = dependency_groups(settings[:group])
        dependency = if github
                       github_dependency(
                         github, branch, settings[:commit], settings[:require], settings[:auto_require], groups
                       )
                     else
                       path_dependency(
                         path, branch, settings[:commit], settings[:require], settings[:auto_require], groups
                       )
                     end
        key = [dependency.type, dependency.source]
        raise DefinitionError, "duplicate mrbgem: #{dependency.source}" if dependencies.any? do |item|
          [item.type, item.source] == key
        end

        dependencies << dependency
      end

      def group(*names, &block)
        raise DefinitionError, "mrbgem group requires at least one name" if names.empty?
        raise DefinitionError, "mrbgem group requires a block" unless block

        normalized = Mrbgems.normalize_groups(names)
        @groups |= normalized
        @group_stack << normalized
        instance_eval(&block)
      ensure
        @group_stack.pop if normalized
      end

      private

      attr_reader :directory

      def gem_settings(options)
        unknown = options.keys - GEM_OPTIONS.keys
        raise DefinitionError, "unknown mrbgem option: #{unknown.join(", ")}" unless unknown.empty?

        settings = GEM_OPTIONS.merge(options)
        require_name = settings[:require]
        unless require_name.nil? || (require_name.is_a?(String) && !require_name.empty? &&
          !require_name.match?(/[\x00-\x1f\x7f]/))
          raise DefinitionError, "invalid mrbgem require name: #{require_name.inspect}"
        end
        unless [true, false].include?(settings[:auto_require])
          raise DefinitionError, "mrbgem auto_require must be true or false: #{settings[:auto_require].inspect}"
        end

        settings
      end

      def current_groups
        @group_stack.flatten.uniq.freeze
      end

      def dependency_groups(group)
        return current_groups if group.nil?

        names = Array(group)
        raise DefinitionError, "mrbgem group requires at least one name" if names.empty?

        normalized = Mrbgems.normalize_groups(names)
        @groups |= normalized
        (current_groups + normalized).uniq.freeze
      end

      def github_dependency(source, branch, commit, require_name, auto_require, groups)
        raise DefinitionError, "invalid GitHub mrbgem: #{source.inspect}" unless GITHUB_PATTERN.match?(source.to_s)
        raise DefinitionError, "GitHub mrbgem branch must not be empty" if branch.to_s.empty?
        raise DefinitionError, "invalid Git commit: #{commit.inspect}" if commit && !COMMIT_PATTERN.match?(commit.to_s)

        Dependency.new(type: :github, source: source, branch: branch,
                       commit: commit&.downcase, path: nil, require_name: require_name,
                       auto_require: auto_require, groups: groups)
      end

      def path_dependency(source, branch, commit, require_name, auto_require, groups)
        raise DefinitionError, "local mrbgem path must not be empty" if source.to_s.empty?
        raise DefinitionError, "local mrbgem does not accept branch or commit" if branch != "main" || commit

        Dependency.new(type: :path, source: source, branch: nil, commit: nil,
                       path: File.expand_path(source, directory), require_name: require_name,
                       auto_require: auto_require, groups: groups)
      end
    end
  end
end
