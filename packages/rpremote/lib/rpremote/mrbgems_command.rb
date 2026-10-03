# frozen_string_literal: true

require "optparse"
require_relative "mrbgems"

module Rpremote
  class MrbgemsCommand
    DEFAULT_PATH = Mrbgems::DEFAULT_PATH

    def self.run(args, output: $stdout, mrbgems: Mrbgems)
      command = args.shift
      options = { path: DEFAULT_PATH, lock_path: nil }
      with = nil
      without = nil
      OptionParser.new do |opts|
        opts.on("--file FILE") { |value| options[:path] = value }
        opts.on("--lockfile FILE") { |value| options[:lock_path] = value }
        opts.on("--with GROUPS") { |value| with = Mrbgems.parse_groups(value) }
        opts.on("--without GROUPS") { |value| without = Mrbgems.parse_groups(value) }
      end.parse!(args)
      raise ArgumentError, "mrbgems does not accept arguments" unless args.empty?

      unless %w[lock update].include?(command)
        raise ArgumentError, "--with is only available for mrbgems lock and update" if with
        raise ArgumentError, "--without is only available for mrbgems lock and update" if without
      end

      manager = mrbgems.new(**options)
      case command
      when "check"
        dependencies = manager.check
        output.puts("checked #{dependencies.length} mrbgems: #{manager.path}")
      when "list"
        list(manager, output)
      when "lock", "update"
        result = manager.lock(update: command == "update", with: with || [], without: without || [])
        output.puts("locked #{result.fetch("gems").length} mrbgems: #{manager.lock_path}")
      else
        raise ArgumentError, "unknown mrbgems command: #{command || "(none)"}"
      end
    end

    def self.list(manager, output)
      dependencies = manager.check
      lock = manager.read_lock(required: false)
      entries = lock&.fetch("gems", []) || []
      dependencies.each do |dependency|
        entry = entries.find { |item| matching_entry?(manager, dependency, item) }
        suffix = entry && (entry["commit"] || entry["sha256"])
        output.puts([dependency.type, dependency.source, suffix&.slice(0, 12)].compact.join(" "))
      end
    end
    private_class_method :list

    def self.matching_entry?(manager, dependency, entry)
      return false unless entry["type"] == dependency.type.to_s
      return entry["source"] == dependency.source if dependency.type == :github

      File.expand_path(entry["source"], File.dirname(manager.lock_path)) == dependency.path
    end
    private_class_method :matching_entry?
  end
end
