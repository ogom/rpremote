# frozen_string_literal: true

module Rpremote
  class CLI
    module FilesystemCommands
      private

      def fs(args)
        subcommand = args.shift
        recursive = subcommand == "cp" && (args.delete("--recursive") || args.delete("-r"))
        options = parse_connection_options(args)
        case subcommand
        when "cp"
          copy(args, options, recursive: recursive)
        when "push"
          copy(args, options, recursive: true, command: "push")
        when "cat"
          cat(args, options)
        when "ls", "rm", "mkdir"
          filesystem_shell_command(subcommand, args, options)
        else
          raise ArgumentError, "unknown fs command: #{subcommand || "(none)"}"
        end
      rescue Shell::TimeoutError => e
        raise Shell::TimeoutError, "filesystem connection failed: #{e.message}"
      end

      def copy(args, options, recursive: false, command: "cp")
        usage = command == "push" ? "rpremote fs push LOCAL_DIR :/REMOTE_DIR" : "rpremote fs cp SOURCE DESTINATION"
        raise ArgumentError, "usage: #{usage} [options]" unless args.length == 2

        source, destination = args
        source_remote = RemotePath.remote?(source)
        destination_remote = RemotePath.remote?(destination)
        raise ArgumentError, "exactly one cp path must be remote (prefix remote paths with :)" if source_remote == destination_remote
        return RecursiveCopy.new(output: stdout, serial: serial, device: device).call(source, destination, options) if recursive

        ensure_filesystem_connection!(options)
        if source_remote
          data = with_modem(options) { |modem| modem.download(RemotePath.unwrap(source)) }
          File.binwrite(local_destination(destination, source), data)
          stdout.puts("downloaded #{data.bytesize} bytes: #{source} -> #{destination}")
        else
          data = File.binread(source)
          with_modem(options) { |modem| modem.upload(RemotePath.unwrap(destination), data) }
          stdout.puts("uploaded #{data.bytesize} bytes: #{source} -> #{destination}")
        end
      rescue Errno::ENOENT => e
        raise ArgumentError, e.message
      end

      def cat(args, options)
        raise ArgumentError, "usage: rpremote fs cat :/REMOTE/PATH [options]" unless args.length == 1
        raise ArgumentError, "cat path must be remote (prefix it with :)" unless RemotePath.remote?(args.first)

        stdout.write(with_modem(options) { |modem| modem.download(RemotePath.unwrap(args.first)) })
      end

      def filesystem_shell_command(command, args, options)
        usage = "usage: rpremote fs #{command} :/REMOTE/PATH [options]"
        raise ArgumentError, usage unless args.length == 1

        path = RemotePath.validate(args.first)
        stdout.puts("deleting remote path permanently: #{path}") if command == "rm"
        output = with_shell(options) do |shell|
          shell.execute("#{command} #{Shell.quote_argument(path)}")
        end
        ensure_filesystem_success!(command, output)
        stdout.write(output)
      end

      def ensure_filesystem_success!(command, output)
        failed = command == "ls" ? output.start_with?("ls:") : !output.empty?
        raise Shell::CommandError, output.strip if failed
      end

      def ensure_filesystem_connection!(options)
        output = with_shell(options) { |shell| shell.execute("ls '/'") }
        ensure_filesystem_success!("ls", output)
      end

      def with_modem(options)
        port_path = device.main_port(options[:port])
        serial.open(port_path, baud: options[:baud]) do |port|
          yield PicoModem.new(port, timeout: options[:timeout])
        end
      end

      def with_shell(options)
        port_path = device.main_port(options[:port])
        serial.open(port_path, baud: options[:baud]) do |port|
          shell = Shell.new(port, timeout: options[:timeout])
          shell.synchronize!
          yield shell
        end
      end

      def local_destination(destination, source)
        return destination unless File.directory?(destination)

        File.join(destination, File.basename(RemotePath.unwrap(source)))
      end
    end
  end
end
