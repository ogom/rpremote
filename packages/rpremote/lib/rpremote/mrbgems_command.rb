# frozen_string_literal: true

require "optparse"
require_relative "mrbgems"

module Rpremote
  class MrbgemsCommand
    DEFAULT_PATH = Mrbgems::DEFAULT_PATH

    def self.run(args, output: $stdout, mrbgems: Mrbgems)
      command = args.shift
      options = { path: DEFAULT_PATH, lock_path: nil }
      OptionParser.new do |opts|
        opts.on("--file FILE") { |value| options[:path] = value }
        opts.on("--lockfile FILE") { |value| options[:lock_path] = value }
      end.parse!(args)
      raise ArgumentError, "mrbgems does not accept arguments" unless args.empty?

      manager = mrbgems.new(**options)
      case command
      when "check"
        dependencies = manager.check
        output.puts("checked #{dependencies.length} mrbgems: #{manager.path}")
      when "list"
        list(manager, output)
      when "lock", "update"
        result = manager.lock(update: command == "update")
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
        entry = entries.find do |item|
          item["type"] == dependency.type.to_s && item["source"] == dependency.source
        end
        suffix = entry && (entry["commit"] || entry["sha256"])
        output.puts([dependency.type, dependency.source, suffix&.slice(0, 12)].compact.join(" "))
      end
    end
    private_class_method :list
  end
end
