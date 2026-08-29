# rpremote PicoRubyサンプル

[English](README.md)

これらのサンプルはRaspberry Pi Pico 2およびPico 2 W上のPicoRuby R2P2を使います。コマンドはリポジトリのルートで実行します。

## 電子工作教材

[電子工作教材](education/README.ja.md)では、GPIO基礎からセンサーを組み合わせたプロジェクトまで順番に確認できます。

| サンプル                                                | 内容                                               | 使用部品                          |
| ------------------------------------------------------- | -------------------------------------------------- | --------------------------------- |
| [01_blink](education/01_blink/README.ja.md)             | オンボードLEDを点滅します。                        | Pico 2                            |
| [02_switch](education/02_switch/README.ja.md)           | スイッチを読みLEDを制御します。                    | タクトスイッチ                    |
| [03_speaker](education/03_speaker/README.ja.md)         | BTLアンプ経由で圧電ブザーを鳴らします。            | スイッチ、アンプ、ブザー          |
| [04_ws2812](education/04_ws2812/README.ja.md)           | WS2812Bを7色に切り替えます。                       | スイッチ、WS2812B                 |
| [06_mpu6050](education/06_mpu6050/README.ja.md)         | 姿勢と動きに色と音で反応します。                   | MPU6050、WS2812B、ブザー          |
| [07_dfu](education/07_dfu/README.ja.md)                 | アプリ更新と起動失敗時のロールバックを確認します。 | Pico 2                            |
| [08_my_gems](education/08_my_gems/README.ja.md)         | ローカルmrbgemをオンボードLEDで確認します。        | Pico 2                            |
| [09_my_gems_dfu](education/09_my_gems_dfu/README.ja.md) | ローカルmrbgemを使うアプリをDFUで更新します。      | Pico 2                            |
| [10_wifi](education/10_wifi/README.ja.md)               | Pico 2 Wを無線LANへ接続します。                    | Pico 2 W、無線LANアクセスポイント |

## 準備と実行

[パルスオキシメータープロジェクト](projects/oximeter/README.ja.md)では、ローカルのMAX30102とSPI WS2812 mrbgemを組み合わせて心拍数とSpO2を推定し、8個のNeoPixelへ状態を表示します。

```sh
rpremote setup
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

配線前に各サンプルのREADMEを確認してください。GPIO、ADC、I2C信号は3.3 V専用です。回路を変更する前にUSBを外してください。

## PicoModem DFU

[education/07_dfu](education/07_dfu/README.ja.md)には、PicoModem DFUでの起動成功とロールバックを確認する最小サンプル、およびv1からv2への実用的な更新例があります。
[education/09_my_gems_dfu](education/09_my_gems_dfu/README.ja.md)では、ローカルmrbgemを組み込んだファームウェアを維持したまま、利用するアプリだけをDFUで更新します。
