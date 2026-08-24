# 05 mpu6050 acceleration

言語: PicoRuby<br>
ボード: Raspberry Pi Pico 2<br>
カスタムmrbgem: `picoruby-ws2812-plus`

[English](README.md)

MPU6050 の加速度を読み、姿勢に応じて WS2812B の色を変えます。水平は緑、Y方向の傾きは赤、X方向の傾きは青です。

## 前提

`04_ws2812` と同じ、`ws2812-plus` を含むカスタム R2P2 ファームウェアが必要です。

## 配線

- WS2812B: DIN -> GP14（物理19番）、GND -> GND、VDD -> 3V3(OUT)
- MPU6050: SDA -> GP16（物理21番）、SCL -> GP17（物理22番）、GND -> GND、VCC -> 3V3(OUT)

## 実行

```sh
rpremote run examples/education/05_mpu6050_a/main.rb --timeout 15
```

シリアルに加速度と `level`、`X tilt`、または `Y tilt` が表示されます。最後に `mpu6050 tilt: OK` が表示されれば成功です。
