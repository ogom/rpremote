#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

def abort_with(message)
  warn message
  exit 1
end

gem_dir = Pathname(ARGV[0] || abort_with("usage: #{$PROGRAM_NAME} GEM_DIR [PICORUBY_ROOT]")).expand_path
abort_with("mrbgem directory not found: #{gem_dir}") unless gem_dir.directory?
abort_with("mrbgem.rake not found: #{gem_dir}") unless gem_dir.join("mrbgem.rake").file?
abort_with("host smoke tests support pure-Ruby mrbgems only: #{gem_dir}") if gem_dir.join("src").directory?

test_files = Dir.glob(gem_dir.join("test/**/*_test.rb").to_s).sort
abort_with("no test files found: #{gem_dir.join('test')}") if test_files.empty?

repo_root = Pathname(__dir__).join("../..").expand_path
picoruby_root = if ARGV[1]
                  Pathname(ARGV[1]).expand_path
                else
                  settings_path = repo_root.join("config/setting.json")
                  version = if settings_path.file?
                              JSON.parse(settings_path.read)["language_version"]
                            end
                  configured = repo_root.join("firmware/picoruby-#{version}") if version
                  configured&.directory? ? configured : nil
                end

unless picoruby_root
  candidates = Dir.glob(repo_root.join("firmware/picoruby-*").to_s)
                  .select { |path| File.directory?(path) }
                  .sort
  picoruby_root = Pathname(candidates.last) unless candidates.empty?
end
abort_with("prepared PicoRuby source not found; run `rpremote setup`") unless picoruby_root&.directory?

picotest_lib = picoruby_root.join("mrbgems/picoruby-picotest/mrblib")
abort_with("Picotest not found under: #{picoruby_root}") unless picotest_lib.directory?

$LOAD_PATH.unshift(picotest_lib.to_s)
$LOAD_PATH.unshift(gem_dir.join("mrblib").to_s)
$LOAD_PATH.unshift(gem_dir.join("test/mock").to_s) if gem_dir.join("test/mock").directory?

require "picotest"

before = ObjectSpace.each_object(Class).to_a
test_files.each { |file| load file }
test_classes = ObjectSpace.each_object(Class).select do |klass|
  !before.include?(klass) && klass < Picotest::Test && klass.name&.end_with?("Test")
end.sort_by(&:name)
abort_with("no Picotest::Test classes found: #{gem_dir}") if test_classes.empty?

failures = 0
assertions = 0
tests = 0

test_classes.each do |klass|
  klass.new.list_tests.sort.each do |test_name|
    test = klass.new
    tests += 1
    begin
      test.setup
      test.public_send(test_name)
    rescue Exception => error # Picotest assertions may intentionally exercise Exception subclasses.
      failures += 1
      warn "\n#{klass}##{test_name}: #{error.class}: #{error.message}"
    ensure
      begin
        test.teardown
      rescue Exception => error
        failures += 1
        warn "\n#{klass}##{test_name} teardown: #{error.class}: #{error.message}"
      end
    end

    result = test.result
    assertions += result["success_count"]
    failures += result["failures"].length
    failures += result["exceptions"].length
    failures += result["crashes"].length
  end
end

puts "\n#{gem_dir.basename}: #{tests} tests, #{assertions} successful assertions, #{failures} failures"
puts "Host smoke test only; target VM and hardware were not exercised."
exit(failures.zero? ? 0 : 1)
