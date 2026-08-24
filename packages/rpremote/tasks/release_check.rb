# frozen_string_literal: true

require "fileutils"
require "bundler"
require "open3"
require "rbconfig"
require "rubygems/package"
require "tmpdir"
require_relative "../lib/rpremote/version"

module Rpremote
  module ReleaseCheck
    EXPECTED_FILES = %w[
      CHANGELOG.md
      LICENSE
      README.md
      README.ja.md
      RELEASING.md
      THIRD_PARTY_NOTICES.md
      exe/rpremote
      tasks/firmware_build.rb
    ].freeze

    module_function

    def call
      gem_file = File.expand_path("rpremote-#{Rpremote::VERSION}.gem")
      validate_package(gem_file)
      smoke_test(gem_file)
      puts "release check passed: #{File.basename(gem_file)}"
    end

    def validate_package(gem_file)
      package = Gem::Package.new(gem_file)
      specification = package.spec
      missing_files = EXPECTED_FILES - package.contents
      changelog_entry = "## [#{Rpremote::VERSION}]"

      unless specification.version.to_s == Rpremote::VERSION
        abort "built gem version does not match #{Rpremote::VERSION}"
      end
      unless File.read("CHANGELOG.md").include?(changelog_entry)
        abort "CHANGELOG.md has no entry for #{Rpremote::VERSION}"
      end
      abort "built gem is missing: #{missing_files.join(", ")}" unless missing_files.empty?
      abort "built gem does not require MFA" unless specification.metadata["rubygems_mfa_required"] == "true"
    end

    def smoke_test(gem_file)
      Dir.mktmpdir("rpremote-release-") do |directory|
        gem_home = File.join(directory, "gems")
        bin_dir = File.join(directory, "bin")
        FileUtils.mkdir_p([gem_home, bin_dir])
        environment = { "GEM_HOME" => gem_home, "GEM_PATH" => gem_home }

        install_gem(environment, gem_home, bin_dir, gem_file)
        run_cli(environment, bin_dir)
      end
    end

    def install_gem(environment, gem_home, bin_dir, gem_file)
      command = [
        RbConfig.ruby, "-S", "gem", "install", "--local", "--no-document",
        "--install-dir", gem_home, "--bindir", bin_dir, gem_file
      ]
      run!(environment, command, "isolated gem install")
    end

    def run_cli(environment, bin_dir)
      stdout = run!(environment, [File.join(bin_dir, "rpremote"), "--version"], "installed CLI")
      abort "installed CLI reported #{stdout.strip.inspect}" unless stdout.strip == Rpremote::VERSION
    end

    def run!(environment, command, description)
      stdout, stderr, status = Bundler.with_unbundled_env do
        Open3.capture3(environment, *command)
      end
      abort "#{description} failed:\n#{stdout}#{stderr}" unless status.success?

      stdout
    end
  end
end
