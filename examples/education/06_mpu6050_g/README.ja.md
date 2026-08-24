# 06 mpu6050 gesture

言語: PicoRuby<br>
ボード: Raspberry Pi Pico 2<br>
カスタムmrbgem: `picoruby-ws2812-plus`

[English](README.md)

MPU6050 の加速度変化から動きを検出し、WS2812B の色と圧電ブザーで反応します。

## 前提

`04_ws2812` と同じ、`ws2812-plus` を含むカスタム R2P2 ファームウェアが必要です。

## 配線

- WS2812B: DIN -> GP14（物理19番）、GND -> GND、VDD -> 3V3(OUT)
- MPU6050: SDA -> GP16（物理21番）、SCL -> GP17（物理22番）、GND -> GND、VCC -> 3V3(OUT)
- 圧電ブザー: GP18（物理24番） -> BTLアンプ入力、`OUT+` -> ブザーの `+`、`OUT-` -> ブザーの `-`

BTL出力の `OUT+`と`OUT-`はどちらもGNDへ接続しないでください。

## 実行

```sh
rpremote run examples/education/06_mpu6050_g/main.rb --timeout 15
```

大きく動かすと `X: shake`、`Y: pico`、または `Z: don` が表示され、色と音が変わります。最後に `mpu6050 sound: OK` が表示されれば成功です。
