# frozen_string_literal: true

module Rpremote
  class RecursiveCopy
    def initialize(output:, serial: Serial, device: Device)
      @output = output
      @serial = serial
      @device = device
    end

    def call(source, destination, options)
      validate!(source, destination)
      remote_root = RemotePath.validate(destination)
      directories, files = collect(source, remote_root)
      create_directories(directories, options)
      upload_files(files, options)
      output.puts("uploaded #{files.length} files: #{source} -> #{destination}")
    rescue Errno::ENOENT => e
      raise ArgumentError, e.message
    end

    private

    attr_reader :output, :serial, :device

    def validate!(source, destination)
      raise ArgumentError, "recursive cp only supports a local source and remote destination" if RemotePath.remote?(source)
      raise ArgumentError, "recursive cp source must be a directory: #{source}" unless File.directory?(source)

      RemotePath.validate(destination)
    end

    def collect(source, remote_root)
      directories = [remote_root]
      files = []
      local_entries(source).each do |path|
        remote_path = File.join(remote_root, path.delete_prefix("#{source}/"))
        File.directory?(path) ? directories << remote_path : files << [path, remote_path]
      end
      [directories.sort_by { |path| [path.count("/"), path] }.uniq, files.sort]
    end

    def local_entries(source)
      entries = Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH).reject do |path|
        %w[. ..].include?(File.basename(path))
      end
      symbolic_link = entries.find { |path| File.symlink?(path) }
      raise ArgumentError, "recursive cp does not support symbolic links: #{symbolic_link}" if symbolic_link

      entries
    end

    def create_directories(directories, options)
      with_port(options) do |port|
        shell = Shell.new(port, timeout: options[:timeout])
        shell.synchronize!
        directories.each do |path|
          quoted_path = Shell.quote_argument(path)
          next unless shell.execute("ls #{quoted_path}").start_with?("ls:")

          result = shell.execute("mkdir #{quoted_path}")
          raise Shell::CommandError, result.strip unless result.empty?

          output.puts("created remote directory: :#{path}")
        end
      end
    end

    def upload_files(files, options)
      with_port(options) do |port|
        modem = PicoModem.new(port, timeout: options[:timeout])
        files.each do |local_path, remote_path|
          size = modem.upload(remote_path, File.binread(local_path))
          output.puts("uploaded #{size} bytes: #{local_path} -> :#{remote_path}")
        end
      end
    end

    def with_port(options, &)
      port_path = device.main_port(options[:port])
      serial.open(port_path, baud: options[:baud], &)
    end
  end
end
