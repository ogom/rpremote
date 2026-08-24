# frozen_string_literal: true

require "fileutils"
require "net/http"
require "timeout"
require "uri"

module Rpremote
  class LanguageSource
    MAX_REDIRECTS = 5

    class Error < Rpremote::Error; end
    class DownloadError < Error; end
    class ExtractError < Error; end

    attr_reader :language, :version, :cache_dir

    def initialize(language: Target::DEFAULT_LANGUAGE, version: Target::DEFAULT_LANGUAGE_VERSION,
                   cache_dir: Target::DEFAULT_CACHE_DIR,
                   fetcher: nil, extractor: nil, preparer: nil)
      Language.validate!(language)

      @language = language
      @version = version
      @cache_dir = File.expand_path(cache_dir.gsub("{version}", version))
      @fetcher = fetcher || method(:download)
      @extractor = extractor || method(:extract)
      @preparer = preparer || method(:prepare_repository)
    end

    def setup(force: false)
      FileUtils.mkdir_p(cache_dir)
      fetch_archive if force || !File.size?(archive_path)
      unless File.directory?(source_dir) && !force
        FileUtils.rm_rf(source_dir) if force
        extractor.call(archive_path, cache_dir)
      end
      raise ExtractError, "PicoRuby source was not extracted: #{source_dir}" unless File.directory?(source_dir)

      preparer.call(source_dir)
      source_dir
    end

    def archive_url
      "https://github.com/picoruby/picoruby/archive/refs/tags/#{version}.zip"
    end

    def archive_path
      File.join(cache_dir, "picoruby-#{version}.zip")
    end

    def source_dir
      File.join(cache_dir, "picoruby-#{version}")
    end

    private

    attr_reader :fetcher, :extractor, :preparer

    def fetch_archive
      temporary = "#{archive_path}.part"
      File.binwrite(temporary, fetcher.call(archive_url))
      raise DownloadError, "downloaded PicoRuby archive is empty" unless File.size?(temporary)

      File.rename(temporary, archive_path)
    rescue SystemCallError => e
      raise DownloadError, "cannot store PicoRuby source: #{e.message}"
    ensure
      FileUtils.rm_f(temporary) if temporary
    end

    def extract(archive, destination)
      success = system("/usr/bin/ditto", "-x", "-k", archive, destination)
      raise ExtractError, "cannot extract PicoRuby archive: #{archive}" unless success
    end

    def prepare_repository(source)
      mruby_core = File.join(source, "mrbgems/picoruby-mruby/lib/mruby/lib/mruby/core_ext.rb")
      pico_sdk = File.join(source, "mrbgems/picoruby-r2p2/lib/pico-sdk/CMakeLists.txt")
      return if File.file?(mruby_core) && File.file?(pico_sdk)

      commands = []
      unless File.directory?(File.join(source, ".git"))
        commands << %w[git init]
        commands << ["git", "remote", "add", "origin", "https://github.com/picoruby/picoruby.git"]
      end
      commands.push(
        ["git", "fetch", "--depth", "1", "origin", "refs/tags/#{version}"],
        ["git", "checkout", "--force", "FETCH_HEAD"],
        ["git", "submodule", "update", "--init", "--recursive", "--depth", "1"]
      )
      commands.each do |command|
        next if system(*command, chdir: source)

        raise ExtractError, "cannot prepare PicoRuby submodules: #{command.join(" ")}"
      end
    end

    def download(url, redirects = MAX_REDIRECTS)
      raise DownloadError, "too many redirects while downloading PicoRuby" if redirects.negative?

      uri = URI(url)
      raise DownloadError, "PicoRuby download requires HTTPS" unless uri.is_a?(URI::HTTPS)

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "rpremote/#{Rpremote::VERSION}"
      response = Net::HTTP.start(
        uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60
      ) { |http| http.request(request) }

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        location = response["location"]
        raise DownloadError, "PicoRuby download redirect has no location" unless location

        download(URI.join(url, location).to_s, redirects - 1)
      else
        raise DownloadError, "PicoRuby download failed: HTTP #{response.code} #{response.message}"
      end
    rescue SocketError, SystemCallError, Timeout::Error => e
      raise DownloadError, "PicoRuby download failed: #{e.message}"
    end
  end
end
