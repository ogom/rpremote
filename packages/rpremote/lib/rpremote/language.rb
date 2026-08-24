# frozen_string_literal: true

module Rpremote
  module Language
    SUPPORTED = %w[picoruby].freeze

    module_function

    def validate!(language)
      return language if SUPPORTED.include?(language)

      raise ArgumentError, "unsupported language: #{language}"
    end
  end
end
