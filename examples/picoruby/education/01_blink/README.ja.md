# 01 blink

[English](README.md)

Pico 2のオンボードLED（GP25）を5回点滅させ、シリアルへ状態を出力します。

## 配線

Pico 2は配線不要です。

## 実行

リポジトリ直下で実行します。

```sh
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

`blink: OK`が表示され、LEDが5回点滅すれば成功です。
