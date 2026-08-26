# frozen_string_literal: true

require_relative "rpremote/version"

module Rpremote
  class Error < StandardError; end
end

require_relative "rpremote/checksum"
require_relative "rpremote/config"
require_relative "rpremote/target"
require_relative "rpremote/language"
require_relative "rpremote/remote_path"
require_relative "rpremote/picomodem"
require_relative "rpremote/device"
require_relative "rpremote/dfu_compiler"
require_relative "rpremote/serial"
require_relative "rpremote/terminal"
require_relative "rpremote/shell"
require_relative "rpremote/runner"
require_relative "rpremote/resetter"
require_relative "rpremote/recursive_copy"
require_relative "rpremote/picoruby_source_patch"
require_relative "rpremote/language_source"
require_relative "rpremote/nuke_firmware"
require_relative "rpremote/mrbgems"
require_relative "rpremote/mrbgems_command"
require_relative "rpremote/flasher"
require_relative "rpremote/builder"
require_relative "rpremote/dfu_command"
require_relative "rpremote/setup_command"
require_relative "rpremote/build_command"
require_relative "rpremote/flash_command"
require_relative "rpremote/bootsel_command"
require_relative "rpremote/deploy_command"
