# frozen_string_literal: true

module Rpremote
  class PicoRubySourcePatch
    JOB_PATH = "mrbgems/picoruby-shell/mrblib/job.rb"
    BOOTSEL_PATH = "mrbgems/picoruby-machine/include/machine.h"
    PATCH_ALIASES = { "3.4.2" => "3.4.5" }.freeze

    class Error < Rpremote::Error; end

    attr_reader :version

    def initialize(version:)
      @version = version
    end

    def apply(source)
      return unless Dir.exist?(source)

      patch_version = PATCH_ALIASES.fetch(version, version)
      patches(patch_version).each do |patch, prerequisite|
        next unless File.file?(patch) && File.file?(File.join(source, prerequisite))
        next if prerequisite == BOOTSEL_PATH && File.read(File.join(source, prerequisite)).include?("Machine_bootsel")

        next if git_apply?(source, patch, "--reverse", "--check")

        raise Error, "cannot apply rpremote patch to PicoRuby #{version}" unless git_apply?(source, patch, "--check")
        raise Error, "cannot apply rpremote patch to PicoRuby #{version}" unless git_apply?(source, patch)
      end
      nil
    end

    private

    def patches(patch_version)
      definitions = {
        "ruby-exception-status" => JOB_PATH,
        "bootsel" => BOOTSEL_PATH
      }
      definitions.map do |name, prerequisite|
        [File.expand_path("../../patches/picoruby-#{patch_version}-#{name}.patch", __dir__), prerequisite]
      end
    end

    def git_apply?(source, patch, *options)
      system("git", "apply", "--unidiff-zero", *options, patch, chdir: source, out: File::NULL, err: File::NULL)
    end
  end
end
