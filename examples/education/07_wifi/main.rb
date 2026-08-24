# frozen_string_literal: true

# Copy this file to main.local.rb and set the credentials there before running it.
wifi_country = "JP"
wifi_ssid = "YOUR_SSID"
wifi_password = "YOUR_PASSWORD"
connect_timeout_seconds = 15

if wifi_ssid == "YOUR_SSID" || wifi_password == "YOUR_PASSWORD"
  puts "Set WIFI_SSID and WIFI_PASSWORD in main.local.rb before running this example."
  return
end

require "cyw43"

unless CYW43.init(wifi_country, force: true)
  puts "wifi: failed to initialize CYW43"
  return
end

CYW43.enable_sta_mode
puts "Connecting to #{wifi_ssid}..."

connected = CYW43.connect_timeout(
  wifi_ssid,
  wifi_password,
  CYW43::Auth::WPA2_AES_PSK,
  connect_timeout_seconds
)
unless connected || CYW43.link_connected?
  puts "wifi: connection failed (#{CYW43.tcpip_link_status_name})"
  return
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
