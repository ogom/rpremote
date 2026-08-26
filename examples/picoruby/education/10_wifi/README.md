# 10 Wi-Fi

Language: PicoRuby, Board: Raspberry Pi Pico 2 W, Custom mrbgem: none

[日本語](README.ja.md)

Connects Pico 2 W to Wi-Fi, then blinks the onboard LED three times.

## Prerequisites

Custom R2P2 firmware for board `pico2_w` is required. A UF2 built for Pico 2 cannot use Wi-Fi.

```sh
rpremote build --language picoruby --language-version 3.4.5 --board pico2_w
rpremote flash --mount /Volumes/RP2350
```

Use a 2.4 GHz WPA2-PSK access point. The country code for Japan is `JP`.

## Wi-Fi settings

Do not save credentials in Git. Copy `main.rb` to a local file and edit it.

```sh
cp examples/picoruby/education/10_wifi/main.rb examples/picoruby/education/10_wifi/main.local.rb
```

Set these values in `main.local.rb` for your access point.

```ruby
wifi_ssid = "YOUR_SSID"
wifi_password = "YOUR_PASSWORD"
```

`main.local.rb` is ignored by Git. Do not commit a file containing a password.

## Run

```sh
rpremote run examples/picoruby/education/10_wifi/main.local.rb --timeout 30
```

The example succeeds when `wifi: connected (LINK_UP)` is printed, the onboard LED blinks three times, and `wifi: OK` appears.
If it cannot connect, check the SSID, password, 2.4 GHz band, and country code.
The program waits up to 15 seconds for a connection.

The program initializes CYW43 on every run, so it can be run again even when a previous interrupted run left a connection active.
