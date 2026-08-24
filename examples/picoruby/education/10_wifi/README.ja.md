# 10 Wi-Fi

言語: PicoRuby, ボード: Raspberry Pi Pico 2 W, カスタムmrbgem: 不要

[English](README.md)

Pico 2 Wを無線LANへ接続し、接続後にオンボードLEDを3回点滅します。

## 前提

`board`が`pico2_w`のカスタムR2P2ファームウェアが必要です。Pico 2用のUF2では無線LANは使えません。

```sh
rpremote build --language picoruby --language-version 3.4.5 --board pico2_w
rpremote flash --mount /Volumes/RP2350
```

2.4 GHzのWPA2-PSKアクセスポイントを使用してください。国コードは日本では`JP`です。

## Wi-Fi設定

認証情報をGitへ保存しないため、`main.rb`をローカル用ファイルへコピーして編集します。

```sh
cp examples/picoruby/education/10_wifi/main.rb examples/picoruby/education/10_wifi/main.local.rb
```

`main.local.rb`の次の値をアクセスポイントに合わせて変更します。

```ruby
wifi_ssid = "YOUR_SSID"
wifi_password = "YOUR_PASSWORD"
```

`main.local.rb`は`.gitignore`の対象です。パスワードを含むファイルをコミットしないでください。

## 実行

```sh
rpremote run examples/picoruby/education/10_wifi/main.local.rb --timeout 30
```

`wifi: connected (LINK_UP)`、オンボードLEDの3回点滅、最後に`wifi: OK`が表示されれば成功です。接続できない場合はSSID・パスワード・2.4 GHz帯・国コードを確認してください。接続待ち時間はプログラム内で15秒に設定しています。

プログラムは実行ごとにCYW43を初期化するため、前回の中断後に接続が残っていても再実行できます。
