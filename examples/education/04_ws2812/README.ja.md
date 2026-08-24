# 04 ws2812

言語: PicoRuby<br>
ボード: Raspberry Pi Pico 2<br>
カスタムmrbgem: `picoruby-ws2812-plus`

[English](README.md)

ボタンを押すたびに、GP14 に接続した WS2812B を7色で順番に点灯します。

## 前提

`ws2812-plus` を含むカスタム R2P2 ファームウェアが必要です。リポジトリ直下の
`Mrbgems` と `Mrbgems.lock` を使ってビルド・書き込みます。

```sh
rpremote mrbgems check
rpremote build --language picoruby --language-version 4.0.3 --board pico2 --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

## 配線

- WS2812B: DIN -> GP14（物理19番）、GND -> GND、VDD -> 3V3(OUT)
- ボタン: GP15（物理20番） -> タクトスイッチ -> GND

WS2812B モジュールの電源条件を確認してください。5 V 専用モジュールではレベルシフタが必要になることがあります。

## 実行

```sh
rpremote run examples/education/04_ws2812/main.rb --timeout 15
```

ボタンを押すごとに `color 1/7` から `color 7/7` が表示され、LED の色が切り替わります。最後に `ws2812: OK` が表示されれば成功です。
