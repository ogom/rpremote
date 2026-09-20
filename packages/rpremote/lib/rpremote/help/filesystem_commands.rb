# frozen_string_literal: true

module Rpremote
  module Help
    def self.fs_text(subcommand)
      return fs_subcommand_text(subcommand) if %w[cp push cat ls rm mkdir].include?(subcommand)

      <<~HELP
        Usage: #{COMMAND_USAGE.fetch(:fs_cp)}
               #{COMMAND_USAGE.fetch(:fs_push)}
               #{COMMAND_USAGE.fetch(:fs_cat)}
               #{COMMAND_USAGE.fetch(:fs_ls)}
               #{COMMAND_USAGE.fetch(:fs_rm)}
               #{COMMAND_USAGE.fetch(:fs_mkdir)}

        Uses :/REMOTE/PATH for R2P2 paths. Run `rpremote fs SUBCOMMAND --help` for details.
      HELP
    end

    def self.fs_subcommand_text(subcommand)
      usage = COMMAND_USAGE.fetch(:"fs_#{subcommand}")
      effect = case subcommand
               when "rm" then "Deletes the remote path permanently."
               when "mkdir" then "Creates a remote directory."
               when "cp" then "Transfers one file, or recursively uploads a local directory with --recursive."
               when "push" then "Creates missing remote directories and recursively uploads a local directory."
               else "Reads remote files."
               end
      <<~HELP
        Usage: #{usage}

        #{effect} Defaults are the automatic CDC 0 port, 115200 baud, and 20 seconds.
      HELP
    end
  end
end
