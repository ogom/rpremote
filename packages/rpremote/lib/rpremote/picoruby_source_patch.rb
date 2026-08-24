# frozen_string_literal: true

module Rpremote
  class PicoRubySourcePatch
    JOB_PATH = "mrbgems/picoruby-shell/mrblib/job.rb"
    PATCH_ALIASES = { "3.4.2" => "3.4.5" }.freeze

    class Error < Rpremote::Error; end

    attr_reader :version

    def initialize(version:)
      @version = version
    end

    def apply(source)
      patch_version = PATCH_ALIASES.fetch(version, version)
      patch = File.expand_path("../../patches/picoruby-#{patch_version}-ruby-exception-status.patch", __dir__)
      return unless File.file?(patch) && File.file?(File.join(source, JOB_PATH))
      return if git_apply?(source, patch, "--reverse", "--check")

      raise Error, "cannot apply rpremote patch to PicoRuby #{version}" unless git_apply?(source, patch, "--check")
      raise Error, "cannot apply rpremote patch to PicoRuby #{version}" unless git_apply?(source, patch)
    end

    private

    def git_apply?(source, patch, *options)
      system("git", "apply", *options, patch, chdir: source, out: File::NULL, err: File::NULL)
    end
  end
end
