# frozen_string_literal: true

# Copy this file to main.local.rb and set the credentials there before running it.
WIFI_COUNTRY = "JP"
WIFI_SSID = "iPhoneOg"
WIFI_PASSWORD = "asdfghjk"
CONNECT_TIMEOUT_MS = 15_000

if WIFI_SSID == "YOUR_SSID" || WIFI_PASSWORD == "YOUR_PASSWORD"
  puts "Set WIFI_SSID and WIFI_PASSWORD in main.local.rb before running this example."
  exit 1
end

require "cyw43"

unless CYW43.init(WIFI_COUNTRY)
  puts "wifi: failed to initialize CYW43"
  exit 1
end

CYW43.enable_sta_mode
puts "Connecting to #{WIFI_SSID}..."

unless CYW43.connect_timeout(WIFI_SSID, WIFI_PASSWORD, CYW43::Auth::WPA2_AES_PSK, CONNECT_TIMEOUT_MS)
  puts "wifi: connection failed (#{CYW43.tcpip_link_status_name})"
  exit 1
end

puts "wifi: connected (#{CYW43.tcpip_link_status_name})"
led = CYW43::GPIO.new(CYW43::GPIO::LED_PIN)
3.times do
  led.write(1)
  sleep_ms 250
  led.write(0)
  sleep_ms 250
end

CYW43.disconnect
CYW43.disable_sta_mode
puts "wifi: OK"
