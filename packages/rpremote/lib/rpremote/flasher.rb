# frozen_string_literal: true

require "fileutils"

module Rpremote
  class Flasher
    DEFAULT_VOLUMES_ROOT = "/Volumes"
    DEFAULT_TIMEOUT = 20.0
    INFO_FILE = "INFO_UF2.TXT"
    UF2_BLOCK_SIZE = 512
    UF2_MAGIC_START0 = 0x0A324655
    UF2_MAGIC_START1 = 0x9E5D5157
    UF2_MAGIC_END = 0x0AB16F30

    Result = Data.define(:mount, :destination, :port)

    class Error < Rpremote::Error; end
    class MountNotFoundError < Error; end
    class InvalidTargetError < Error; end
    class TimeoutError < Error; end

    attr_reader :volumes_root, :timeout

    def initialize(
      volumes_root: DEFAULT_VOLUMES_ROOT,
      timeout: DEFAULT_TIMEOUT,
      mount_probe: nil,
      port_probe: nil,
      sleeper: nil
    )
      @volumes_root = volumes_root
      @timeout = Float(timeout)
      @mount_probe = mount_probe || ->(path) { Dir.exist?(path) }
      @port_probe = port_probe || -> { Device.main_port }
      @sleeper = sleeper || ->(seconds) { sleep(seconds) }
      raise ArgumentError, "timeout must be positive" unless @timeout.positive?
    end

    def flash(uf2_path, mount: nil, port: nil, wait_for_port: true)
      validate_firmware!(uf2_path)
      target = find_mount(mount)
      destination = File.join(target, File.basename(uf2_path))
      copy_firmware(uf2_path, destination)
      wait_until("BOOTSEL drive to disappear") { !mount_probe.call(target) }
      return Result.new(mount: target, destination: destination, port: nil) unless wait_for_port

      detected_port = wait_until("R2P2 serial port to appear") { detect_port(port) }
      Result.new(mount: target, destination: destination, port: detected_port)
    end

    def find_mount(explicit_mount = nil)
      mounted = find_mounted(explicit_mount)
      return mounted if mounted

      raise MountNotFoundError,
            "Pico 2 BOOTSEL drive not found; reconnect it while holding BOOTSEL or use --mount DIR"
    end

    def find_mounted(explicit_mount = nil)
      if explicit_mount
        path = File.expand_path(explicit_mount)
        return unless Dir.exist?(path)

        return validate_mount!(path)
      end

      matches = bootsel_mounts
      return if matches.empty?
      return matches.first if matches.one?

      raise MountNotFoundError, "multiple Pico 2 BOOTSEL drives found; use --mount DIR"
    end

    def wait_for_mount(mount: nil)
      if mount
        path = File.expand_path(mount)
        return wait_until("Pico 2 BOOTSEL drive to appear") do
          next unless Dir.exist?(path)
          next unless valid_target?(path)

          path
        end
      end

      wait_until("Pico 2 BOOTSEL drive to appear") do
        matches = bootsel_mounts
        raise MountNotFoundError, "multiple Pico 2 BOOTSEL drives found; use --mount DIR" if matches.length > 1

        matches.first
      end
    end

    private

    attr_reader :mount_probe, :port_probe, :sleeper

    def validate_firmware!(path)
      raise InvalidTargetError, "UF2 file not found: #{path}" unless File.file?(path)
      raise InvalidTargetError, "firmware file must have a .uf2 extension" unless File.extname(path).casecmp?(".uf2")
      raise InvalidTargetError, "UF2 file is empty: #{path}" unless File.size?(path)
      raise InvalidTargetError, "firmware is not a valid UF2 file: #{path}" unless valid_uf2?(path)
    end

    def validate_mount!(path)
      raise MountNotFoundError, "BOOTSEL mount not found: #{path}" unless Dir.exist?(path)
      raise InvalidTargetError, "mount is not an RP2350 BOOTSEL drive: #{path}" unless valid_target?(path)

      path
    end

    def valid_target?(path)
      info_path = File.join(path, INFO_FILE)
      return false unless File.file?(info_path)

      File.basename(path).casecmp?("RP2350") || File.read(info_path).match?(/RP2350|Pico 2/i)
    rescue SystemCallError
      false
    end

    def bootsel_mounts
      Dir.glob(File.join(volumes_root, "*")).select do |path|
        Dir.exist?(path) && valid_target?(path)
      end
    end

    def copy_firmware(source, destination)
      FileUtils.copy_file(source, destination)
    rescue Errno::ENXIO
      # RP2350 may reboot and detach its BOOTSEL volume before macOS finishes
      # closing the destination. The disappearance and serial reconnect checks
      # in #flash determine whether the transfer actually completed.
      nil
    rescue SystemCallError => e
      raise Error, "failed to copy UF2 firmware: #{e.message}"
    end

    def wait_until(description)
      deadline = monotonic_time + timeout
      loop do
        result = yield
        return result if result
        raise TimeoutError, "timed out waiting for #{description}" if monotonic_time >= deadline

        sleeper.call(0.1)
      end
    end

    def valid_uf2?(path)
      size = File.size(path)
      return false if size < UF2_BLOCK_SIZE || (size % UF2_BLOCK_SIZE).positive?

      start_magic = File.binread(path, 8).unpack("V2")
      end_magic = File.binread(path, 4, UF2_BLOCK_SIZE - 4).unpack1("V")
      start_magic == [UF2_MAGIC_START0, UF2_MAGIC_START1] && end_magic == UF2_MAGIC_END
    end

    def detect_port(explicit_port)
      return explicit_port if explicit_port && File.exist?(explicit_port)

      port_probe.call
    rescue Device::NotFoundError, Device::MultipleDevicesError
      nil
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
