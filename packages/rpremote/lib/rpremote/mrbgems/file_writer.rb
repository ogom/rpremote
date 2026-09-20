# frozen_string_literal: true

module Rpremote
  class Mrbgems
    module FileWriter
      private

      def write_json(filename, contents)
        write_file(filename, "#{JSON.pretty_generate(contents)}\n")
      end

      def write_file(filename, contents)
        return if File.file?(filename) && File.binread(filename) == contents

        FileUtils.mkdir_p(File.dirname(filename))
        temporary = "#{filename}.tmp-#{Process.pid}"
        File.binwrite(temporary, contents)
        File.rename(temporary, filename)
      ensure
        FileUtils.rm_f(temporary) if temporary
      end
    end

    include FileWriter
  end
end
