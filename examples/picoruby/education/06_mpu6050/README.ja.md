# 06 MPU6050

言語: PicoRuby, ボード: Raspberry Pi Pico 2, カスタムmrbgem: `picoruby-ws2812-plus`

[English](README.md)

MPU6050の加速度から姿勢と動きを検出し、WS2812Bの色と圧電ブザーで反応します。
静かに傾けると、水平は緑、Y方向は赤、X方向は青で表示します。
大きく動かすと、変化が最も大きい軸に応じて色と音を変えます。

## 前提

`04_ws2812`と同じ、`ws2812-plus`を含むカスタムR2P2ファームウェアが必要です。

## 配線

- WS2812B: DIN -> GP14（物理19番）、GND -> GND、VDD -> 3V3(OUT)
- MPU6050: SDA -> GP16（物理21番）、SCL -> GP17（物理22番）、GND -> GND、VCC -> 3V3(OUT)
- 圧電ブザー: GP18（物理24番） -> BTLアンプ入力、`OUT+` -> ブザーの`+`、`OUT-` -> ブザーの`-`

BTL出力の`OUT+`と`OUT-`はどちらもGNDへ接続しないでください。

## 実行

```sh
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

姿勢に応じて`level`、`X tilt`、`Y tilt`が表示されます。
大きく動かすと`X: shake`、`Y: pico`、`Z: don`が表示され、色と音が変わります。
最後に`mpu6050: OK`が表示されれば成功です。
