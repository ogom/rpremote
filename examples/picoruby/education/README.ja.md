# PicoRuby電子工作教材

[English](README.md)

Raspberry Pi Pico 2 / Pico 2 WとPicoRubyで、基本的な電子工作を順に学ぶ教材です。

`04_ws2812`と`06_mpu6050`は[`picoruby-ws2812-plus`](https://github.com/ksbmyk/picoruby-ws2812-plus)を組み込んだカスタムR2P2ファームウェアが必要です。`06_mpu6050`では、ローカルの`picoruby-mpu6050`も組み込みます。
これらのgemにはビルド時に埋め込むC拡張があるため、公式配布のR2P2 4.0.3へ後から追加することはできません。

`08_my_gems`ではPure Rubyのローカルmrbgemを確認し、`09_my_gems_dfu`ではそのmrbgemを利用するアプリだけをDFUで更新します。追加するmrbgemは同じカスタムファームウェアへ組み込みます。

## 事前準備

WS2812を使う前に、リポジトリに含まれるカスタムファームウェアをビルドして書き込みます。追加gemは`Mrbgems`、固定コミットは`Mrbgems.lock`で管理されます。UF2は`firmware/`に明示した名前で出力します。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

ファームウェアを書き込んだ後、接続を確認します。

```sh
rpremote ports
```

Pico 2を1台だけ接続した状態で、各プログラムを実行します。教材はボタン操作の時間を確保するため約10秒動作します。`--timeout 15`を指定してください。

```sh
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

プログラムを繰り返し動かしたいときは、`main.rb`の`SAMPLES`を変更してください。無限ループに変更したプログラムは`rpremote monitor`で観察し、`Ctrl-]`でローカル側のモニターを終了できます。

## 安全

- GPIOとADCは3.3 V専用です。5 VをGPIO、ADC、I2C信号線へ接続しないでください。
- LEDには330 Ωから1 kΩの抵抗を必ず直列に入れてください。
- モーター、リレー、大電流LEDはGPIOから直接駆動しないでください。
- 配線を変更する前にUSBを外してください。

## 教材

| No. | 題材          | 内容                                                        |
| --- | ------------- | ----------------------------------------------------------- |
| 01 | blink | Pico 2のオンボードLED（GP25）を点滅し、シリアルへ出力します。 |
| 02 | switch | GP15のタクトスイッチを読み、オンボードLEDを制御します。 |
| 03 | speaker | GP15のスイッチでGP18の圧電ブザーを鳴らします。 |
| 04 | ws2812 | GP14のWS2812Bを、ボタンを押すたびに7色で点灯します。 |
| 06 | mpu6050 | 6軸を同時に読み、姿勢と動きに応じて色とブザー音を変えます。 |
| 07 | dfu | アプリをv1からv2へ更新し、起動失敗時のロールバックを試します。 |
| 08 | my_gems | ローカルmrbgemを読み込み、Pico 2のオンボードLEDを点滅します。 |
| 09 | my_gems_dfu | ローカルmrbgemを使うアプリをDFUで更新します。 |
| 10 | wifi | Pico 2 Wを無線LANへ接続し、オンボードLEDを点滅します。 |

## 配線

### 01 blink

Pico 2では配線不要です。

```sh
rpremote run examples/picoruby/education/01_blink/main.rb --timeout 15
```

### 02 switch

- GP15（物理20番） -> タクトスイッチ -> GND（物理23番）
- PicoRuby側で内部プルアップを有効にするため、外部抵抗は不要です。

```sh
rpremote run examples/picoruby/education/02_switch/main.rb --timeout 15
```

### 03 speaker

- スイッチは`02_switch`と同じGP15を使います。
- GP18（物理24番） -> BTLアンプの入力
- BTLアンプの`OUT+` -> 圧電ブザーの`+`
- BTLアンプの`OUT-` -> 圧電ブザーの`-`
- `OUT+`と`OUT-`はどちらもGNDへ接続しないでください。

```sh
rpremote run examples/picoruby/education/03_speaker/main.rb --timeout 15
```

### 04 ws2812 / 06 mpu6050

- WS2812B: DIN -> GP14（物理19番）、GND -> PicoのGND、VDD -> 3V3(OUT)
- タクトスイッチ（`04_ws2812`のみ）: GP15 -> スイッチ -> GND
- MPU6050: SDA -> GP16（物理21番）、SCL -> GP17（物理22番）、GND -> GND、VCC -> 3V3(OUT)
- `06_mpu6050`はさらにGP18 -> BTLアンプ入力、アンプの`OUT+`/`OUT-` -> 圧電ブザーの`+`/`-`

```sh
rpremote run examples/picoruby/education/04_ws2812/main.rb --timeout 15
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

WS2812Bモジュールの電源条件を必ず確認してください。5 V専用モジュールを3.3 V ロジックで確実に動かすには、レベルシフタが必要になることがあります。

### 07 dfu

Pico 2では配線不要です。
PicoModem DFUでアプリだけを更新するため、BOOTSELモードやUF2の再書き込みは不要です。
安定版v1を配備してからv2へ更新し、起動に失敗する版から自動で戻る流れを確認します。
詳細は[07_dfu](07_dfu/README.ja.md)を参照してください。

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v1.rb
rpremote reset
rpremote dfu status
```

### 08 my_gems

Pico 2では配線不要です。ローカルmrbgemをlockした後にファームウェアをビルドし、サンプルを実行します。

```sh
rpremote run examples/picoruby/education/08_my_gems/main.rb --timeout 15
```

### 09 my_gems_dfu

`08_my_gems`で組み込んだローカルmrbgemを維持したまま、利用するアプリだけをDFUでv1からv2へ更新します。詳細は[09_my_gems_dfu](09_my_gems_dfu/README.ja.md)を参照してください。

```sh
rpremote dfu app examples/picoruby/education/09_my_gems_dfu/app_v1.rb
rpremote reset
rpremote dfu status
```

### 10 wifi

Pico 2 Wと`pico2_w`向けカスタムファームウェアが必要です。Wi-FiのSSIDとパスワードを`main.local.rb`へ設定して実行します。詳細は[10_wifi](10_wifi/README.ja.md)を参照してください。

```sh
rpremote run examples/picoruby/education/10_wifi/main.local.rb --timeout 30
```

## 評価の観点

- 最終行の`...: OK`と終了コード0を確認します。Ruby例外が発生すると`rpremote run`は例外内容を表示して非0で終了します。
- I2C接続失敗時は、MPU6050のアドレス`0x68`、SDA/SCLの接続、3.3 V電源を確認します。
- WS2812Bの色が違う場合はDIN/DOUTの向きとRGB/GRB順を確認します。
