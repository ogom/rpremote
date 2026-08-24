# 02 switch

言語: PicoRuby<br>
ボード: Raspberry Pi Pico 2<br>
カスタムmrbgem: 不要

[English](README.md)

タクトスイッチを読み、押している間だけオンボード LED を点灯します。

## 配線

- GP15（物理20番） -> タクトスイッチ -> GND（物理23番）
- PicoRuby 側で内部プルアップを使うため、外部抵抗は不要です。

## 実行

```sh
rpremote run examples/education/02_switch/main.rb --timeout 15
```

スイッチを押すと `LED ON`、離すと `LED OFF` が表示されます。最後に `switch: OK` が表示されれば成功です。
