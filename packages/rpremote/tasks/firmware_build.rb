#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

REPOSITORY_ROOT = File.expand_path(ENV.fetch("RPREMOTE_ROOT", File.expand_path("../..", __dir__)))
DEFAULT_BOARD = "pico2"
SUPPORTED_BOARDS = %w[pico2 pico2_w].freeze

def command!(*command, chdir:, env: {})
  prefix = env.map { |key, value| "#{key}=#{value}" }.join(" ")
  puts "+ #{prefix} #{command.join(" ")}".strip
  abort "Command failed: #{command.join(" ")}" unless system(env, *command, chdir: chdir)
end

language = ENV.fetch("RPREMOTE_LANGUAGE", "picoruby")
target_version = ENV.fetch("RPREMOTE_LANGUAGE_VERSION", "4.0.3")
board = ENV.fetch("RPREMOTE_BOARD", DEFAULT_BOARD)
abort "Unsupported language: #{language}" unless language == "picoruby"
abort "Unsupported board: #{board}" unless SUPPORTED_BOARDS.include?(board)

picoruby_root = File.expand_path(ENV.fetch("PICORUBY_DIR"))
config_name = ENV.fetch("RPREMOTE_CONFIG_NAME", "r2p2-#{language}-#{board}")
base_config_path = File.join(picoruby_root, "build_config", "#{config_name}.rb")
config_path = ENV.fetch("RPREMOTE_MRUBY_CONFIG", base_config_path)
fingerprint = ENV.fetch("RPREMOTE_MRBGEMS_FINGERPRINT", nil)
build_name = [config_name, target_version, fingerprint].compact.join("-")
r2p2_gem_dir = File.join(picoruby_root, "mrbgems/picoruby-r2p2")
pico_sdk_path = File.join(r2p2_gem_dir, "lib/pico-sdk")
pico_extras_path = File.join(r2p2_gem_dir, "lib/pico-extras")
output_dir = File.join(REPOSITORY_ROOT, "build", build_name)
mruby_build_dir = File.join(picoruby_root, "build", config_name)
cmake_source_dir = File.join(r2p2_gem_dir, "cmake")

abort "PicoRuby source not found: #{picoruby_root}\nSet PICORUBY_DIR to a PicoRuby checkout." unless File.file?(File.join(picoruby_root, "Rakefile"))
abort "Build config not found: #{base_config_path}" unless File.file?(base_config_path)
abort "Generated build config not found: #{config_path}" unless File.file?(config_path)
build_config = File.read(base_config_path)
mrubyc_vm = build_config.match?(/mrubyc_hal|conf\.femtoruby/)
uses_wifi = build_config.match?(/\bUSE_WIFI\b/)
command!("rake", "r2p2:setup", chdir: picoruby_root) unless File.directory?(pico_sdk_path)

version_header = File.join(picoruby_root, "include/version.h")
version = File.read(version_header)[/#define PICORUBY_VERSION "(.+?)"/, 1]
abort "Could not determine PicoRuby version from #{version_header}" unless version
abort "PicoRuby source is #{version}, but #{target_version} was requested." unless version == target_version

cache_file = File.join(output_dir, "CMakeCache.txt")
if File.file?(cache_file) && !File.read(cache_file).include?("CMAKE_HOME_DIRECTORY:INTERNAL=#{cmake_source_dir}")
  puts "Removing stale CMake output: #{output_dir}"
  FileUtils.rm_rf(output_dir)
end
FileUtils.mkdir_p(output_dir)
build_env = {
  "MRUBY_CONFIG" => config_path,
  "PICORB_BOARD" => board,
  "PICO_SDK_PATH" => pico_sdk_path,
  "PICO_EXTRAS_PATH" => pico_extras_path
}

# PicoRuby keys build output by target, so an overlay can reuse stale objects; fresh builds keep changed local mrbgems in libmruby.a.
if fingerprint && File.directory?(mruby_build_dir)
  puts "Removing stale PicoRuby build output: #{mruby_build_dir}"
  FileUtils.rm_rf(mruby_build_dir)
end
command!("rake", chdir: picoruby_root, env: build_env)

cmake_definitions = [
  "-D", "PICORUBY_ROOT=#{picoruby_root}",
  "-D", "R2P2_GEM_DIR=#{r2p2_gem_dir}",
  "-D", "EXTRA_LIBRARY_PATH=#{File.join(mruby_build_dir, "lib")}",
  "-D", "EXTRA_INCLUDE_DIR=#{File.join(mruby_build_dir, "include")}",
  "-D", "PICO_CYW43_SUPPORTED=1",
  "-D", "MRUBY_CONFIG=#{config_name}",
  "-D", "PICORB_VM_MRUBY=#{mrubyc_vm ? 0 : 1}",
  "-D", "PICORB_VM_MRUBYC=#{mrubyc_vm ? 1 : 0}",
  "-D", "R2P2_NAME=R2P2-PICORUBY",
  "-D", "R2P2_BOARD_NAME=#{board.upcase}",
  "-D", "R2P2_VERSION=#{version}",
  "-D", "PICO_PLATFORM=rp2350",
  "-D", "PICO_BOARD=#{board}",
  "-D", "CMAKE_BUILD_TYPE=Release",
  "-D", "NDEBUG=1",
  "-D", "R2P2_NO_SHARED_ALLOC=OFF"
]
cmake_definitions.push("-D", "USE_WIFI=1") if uses_wifi
command!("cmake", "-S", cmake_source_dir, "-B", output_dir, *cmake_definitions,
         chdir: picoruby_root, env: build_env)
command!("cmake", "--build", output_dir, chdir: picoruby_root)

uf2_files = Dir[File.join(output_dir, "*.uf2")]
abort "Build finished but no UF2 file was created in #{output_dir}" if uf2_files.empty?

built_firmware = uf2_files.max_by { |path| File.mtime(path) }
destination = ENV.fetch("RPREMOTE_FIRMWARE", nil)
if destination
  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.cp(built_firmware, destination)
  puts "Built custom firmware: #{destination}"
else
  puts "Built custom firmware: #{built_firmware}"
end
