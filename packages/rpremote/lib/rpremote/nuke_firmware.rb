# frozen_string_literal: true

require "fileutils"
require "net/http"
require "timeout"
require "uri"

module Rpremote
  class NukeFirmware
    URL = "https://github.com/raspberrypi/pico-sdk-prebuilts/releases/latest/download/nuke_universal.uf2"
    FILENAME = "nuke_universal.uf2"
    MAX_REDIRECTS = 5

    class DownloadError < Rpremote::Error; end

    def initialize(directory: Target::DEFAULT_CACHE_DIR, fetcher: nil)
      @directory = File.expand_path(directory)
      @fetcher = fetcher || method(:download)
    end

    def setup(force: false)
      FileUtils.mkdir_p(directory)
      return path if File.size?(path) && !force

      temporary = "#{path}.part"
      File.binwrite(temporary, fetcher.call(URL))
      raise DownloadError, "downloaded nuke_universal.uf2 is empty" unless File.size?(temporary)

      File.rename(temporary, path)
      path
    rescue SystemCallError => e
      raise DownloadError, "cannot store nuke_universal.uf2: #{e.message}"
    ensure
      FileUtils.rm_f(temporary) if temporary
    end

    private

    attr_reader :directory, :fetcher

    def path
      File.join(directory, FILENAME)
    end

    def download(url, redirects = MAX_REDIRECTS)
      raise DownloadError, "too many redirects while downloading nuke_universal.uf2" if redirects.negative?

      uri = URI(url)
      raise DownloadError, "nuke_universal.uf2 download requires HTTPS" unless uri.is_a?(URI::HTTPS)

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "rpremote/#{Rpremote::VERSION}"
      response = Net::HTTP.start(
        uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60
      ) { |http| http.request(request) }

      case response
      when Net::HTTPSuccess then response.body
      when Net::HTTPRedirection
        location = response["location"]
        raise DownloadError, "nuke_universal.uf2 download redirect has no location" unless location

        download(URI.join(url, location).to_s, redirects - 1)
      else
        raise DownloadError, "nuke_universal.uf2 download failed: HTTP #{response.code} #{response.message}"
      end
    rescue SocketError, SystemCallError, Timeout::Error => e
      raise DownloadError, "nuke_universal.uf2 download failed: #{e.message}"
    end
  end
end
