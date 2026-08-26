# 08 ローカルmrbgem

言語: PicoRuby, ボード: Raspberry Pi Pico 2, カスタムmrbgem: `examples/picoruby/mrbgems/my_gems`のローカル`picoruby-my_gems`

[English](README.md)

プロジェクト内の`my_gems` mrbgemを読み込み、`MyGems`でPico 2のオンボードLEDを5回点滅させます。

## 前提

プロジェクト直下の`Mrbgems`から、`Mrbgems`を基準とした相対パスでローカルgemを指定します。

```ruby
gem path: "examples/picoruby/mrbgems/my_gems"
```

依存関係を検査・固定し、カスタムR2P2ファームウェアをビルドして書き込みます。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

`Mrbgems.lock`にはローカルgem内容のSHA-256が記録されます。ローカルgemを変更したら、`rpremote mrbgems lock`をもう一度実行してください。

## 配線

Pico 2では配線不要です。

## 実行

```sh
rpremote run examples/picoruby/education/08_my_gems/main.rb --timeout 15
```

オンボードLEDが5回点滅し、`my_gems: OK`が表示されれば成功です。
