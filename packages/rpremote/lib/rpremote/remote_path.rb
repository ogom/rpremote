# frozen_string_literal: true

module Rpremote
  module RemotePath
    PREFIX = ":"

    module_function

    def remote?(path)
      path.start_with?(PREFIX)
    end

    def unwrap(path)
      path.delete_prefix(PREFIX)
    end

    def validate(path)
      raise ArgumentError, "path must be remote (prefix it with :)" unless remote?(path)

      remote = unwrap(path)
      raise ArgumentError, "remote path must be absolute" unless remote.start_with?("/")
      raise ArgumentError, "remote path must not contain .." if remote.split("/").include?("..")

      remote
    end
  end
end
