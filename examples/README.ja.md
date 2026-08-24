# rpremote サンプル

言語: PicoRuby<br>
ボード: Raspberry Pi Pico 2およびPico 2 W<br>
カスタムmrbgem: 04〜06は`picoruby-ws2812-plus`、08はローカル`picoruby-my_gems`

[English](README.md)

このディレクトリには[rpremote](../README.ja.md)向けのPicoRuby実機サンプルが
含まれます。コマンドはリポジトリのルートで実行します。

## 電子工作教材

[education](education/README.ja.md)では、Raspberry Pi Pico 2のGPIO基礎から
センサーを組み合わせた電子工作まで順番に確認できます。

| サンプル | 内容 | 使用部品 |
| --- | --- | --- |
| [01_blink](education/01_blink/README.ja.md) | オンボードLEDを点滅します。 | Pico 2 |
| [02_switch](education/02_switch/README.ja.md) | スイッチを読みLEDを制御します。 | タクトスイッチ |
| [03_speaker](education/03_speaker/README.ja.md) | BTLアンプ経由で圧電ブザーを鳴らします。 | スイッチ、アンプ、ブザー |
| [04_ws2812](education/04_ws2812/README.ja.md) | WS2812Bを7色に切り替えます。 | スイッチ、WS2812B |
| [05_mpu6050_a](education/05_mpu6050_a/README.ja.md) | 加速度センサーの傾きを色で示します。 | MPU6050、WS2812B |
| [06_mpu6050_g](education/06_mpu6050_g/README.ja.md) | 動きに色と音で反応します。 | MPU6050、WS2812B、ブザー |
| [07_wifi](education/07_wifi/README.ja.md) | Pico 2 Wを無線LANへ接続します。 | Pico 2 W、無線LANアクセスポイント |
| [08_my_gems](education/08_my_gems/README.ja.md) | ローカルmrbgemをオンボードLEDで確認します。 | Pico 2 |

## 準備と実行

リポジトリの`Mrbgems`には、04〜06で使う`picoruby-ws2812-plus`と、08で使う
ローカルの`examples/mrbgems/my_gems`が定義されています。

```sh
rpremote setup
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run examples/education/01_blink/main.rb --timeout 15
```

配線前に各サンプルのREADMEを確認してください。GPIO、ADC、I2C信号は3.3 V専用です。
回路を変更する前にUSBを外してください。

## PicoModem DFU

[dfu/app.rb](dfu/README.ja.md)は、PicoModem DFUでの起動成功を確定する最小アプリです。
