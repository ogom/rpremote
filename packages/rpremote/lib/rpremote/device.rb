# frozen_string_literal: true

module Rpremote
  class Device
    GLOBS = ["/dev/cu.usbmodem*", "/dev/tty.usbmodem*"].freeze

    class NotFoundError < Rpremote::Error; end
    class MultipleDevicesError < Rpremote::Error; end

    class << self
      def ports
        GLOBS.flat_map { |pattern| Dir.glob(pattern) }.sort
      end

      def main_port(explicit_port = nil, available_ports: ports)
        return validate_explicit_port(explicit_port) if explicit_port

        callout_ports = available_ports.grep(%r{\A/dev/cu\.})
        candidates = callout_ports.empty? ? available_ports : callout_ports
        candidates = candidates.select { |path| cdc_zero?(path, candidates) }

        case candidates.length
        when 0
          raise NotFoundError, "R2P2 serial port not found; connect the Pico 2 or use --port PORT"
        when 1
          candidates.first
        else
          raise MultipleDevicesError,
                "multiple R2P2 devices found; use --port PORT (#{candidates.join(", ")})"
        end
      end

      private

      def validate_explicit_port(path)
        raise NotFoundError, "serial port not found: #{path}" unless File.exist?(path)

        path
      end

      # PicoRuby 3.4.x exposes two CDC interfaces and 4.x exposes three.
      # macOS numbers the interfaces with trailing 1, 3, and (when present) 5.
      # CDC 0 is therefore the first (trailing 1) interface in each USB group.
      def cdc_zero?(path, available_ports)
        basename = File.basename(path)
        siblings = ports_for_group(path, available_ports)
        siblings.length >= 2 && basename.end_with?("1")
      end

      def ports_for_group(path, available_ports)
        prefix = path.sub(/[135]\z/, "")
        available_ports.select { |candidate| candidate.sub(/[135]\z/, "") == prefix }
      end
    end
  end
end
