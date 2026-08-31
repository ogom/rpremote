# 大仙古墳 WS2812サンプル

[English](README.md)

Raspberry Pi Pico 2と`ws2812-plus`を使い、大仙古墳模型の572個のWS2812Bで複数のイルミネーションを実行するPicoRubyサンプルです。実行終了時にはすべてのLEDを消灯します。

## 安全上の注意

572個のLEDには、LEDの仕様と配線に合う外部電源を使用してください。Pico 2のGPIO、`3V3(OUT)`、`VBUS`からLEDへ給電しないでください。Pico 2とLED用電源のGNDは共通にし、配線を変更する前に両方の電源を切ってください。

現在の輝度は[`config.rb`](mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb)の`BRIGHTNESS_PERCENT`で決まります。電源容量、電圧降下、配線とコネクターの発熱を確認せずに輝度を上げないでください。

## 配線

| WS2812B | 接続先                         |
| ------- | ------------------------------ |
| DIN     | Pico 2のGP14（物理19番）       |
| GND     | Pico 2とLED用外部電源の共通GND |
| VDD     | LEDの仕様に合う外部電源        |

5 V動作のLEDが3.3 VのDIN信号を安定して認識しない場合は、適切なレベルシフターを使用してください。

## ビルドと実行

ビルド、ファームウェアの書き込み、`main.rb`の実行をまとめて行うには、リポジトリルートで次のコマンドを実行します。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

このコマンドは、`ws2812-plus`と`daisenkofun-illuminations`を含むR2P2ファームウェアをビルドしてPico 2へ書き込み、R2P2シェルへ再接続して`main.rb`を実行します。書き込みによってPico 2上の既存ファームウェアは置き換えられます。シリアル経由でBOOTSELへ移行できない最初の書き込みでは、Pico 2のBOOTSELボタンを押して接続してください。

### 個別に実行する場合

リポジトリルートで依存関係を確認し、`ws2812-plus`と`daisenkofun-illuminations`を含むR2P2ファームウェアをビルドします。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

初期化したPico 2へ、ビルドしたファームウェアを書き込みます。

```sh
rpremote flash
```

ファームウェアを書き込んだ後、`main.rb`を実行します。イルミネーションはファームウェアへ組み込まれるため、`lib/daisenkofun`の転送は不要です。

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

実行する構成は[`main.rb`](main.rb)の`run_mode`で`:short`、`:long`、`:all`、`:only`から選びます。`:only`では`only_key`へ実行するパターン名を指定します。

| モード   | 実行するパターン                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:short` | `structure_guide`、`divine_light`、`launch_fireworks`、`sunrise`、`dappled_light`、`triple_moat_mirror`、`water_ripples`                                                                                                                                                                                                                                                                                                                                                                                          |
| `:long`  | `structure_guide`、`sunrise`、`dappled_light`、`cherry_blossom`、`triple_moat_mirror`、`water_ripples`、`sakai_sunset`、`moonlight`、`starry_kofun`、`peekaboo`、`heartbeat`、`jewel_box`、`aurora`、`symmetric_forepart_chase`、`two_banks_clockwise`、`rainbow_comet`、`divine_light`、`attached_kofun_lights`、`launch_fireworks`                                                                                                                                                                              |
| `:all`   | `moonlight`、`starry_kofun`、`attached_kofun_lights`、`goodnight_pastel`、`dappled_light`、`green_shimmer`、`fireflies`、`sea`、`triple_moat_mirror`、`sunrise`、`sakai_sunset`、`golden_breath`、`aurora`、`divine_light`、`cherry_blossom`、`rose_garden`、`pastel_ribbon`、`princess_sparkle`、`unicorn_dream`、`peekaboo`、`heartbeat`、`jewel_box`、`symmetric_forepart_chase`、`rainbow_comet`、`two_banks_clockwise`、`color_bound`、`carnival_chase`、`torch_procession`、`fireworks`、`launch_fireworks` |
| `:only`  | `only_key`で選んだ1パターン                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

現在の`main.rb`は`run_mode = :short`、`only_key = :structure_guide`に設定しています。`:short`では`only_key`を使用しません。選択した7パターンが順番に実行され、最後に`daisenkofun: LEDs off`、`daisenkofun: OK`の順で表示されれば成功です。

## イルミネーション

選択可能な32パターンの名称と演出内容は[イルミネーション一覧](docs/illuminations.ja.md)を参照してください。

## 設定

GPIOと輝度は[`config.rb`](mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb)で変更できます。モードごとのパターン構成、`wait_ms`、`loops`は[`setlist.rb`](mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb)で変更します。`:short`、`:long`、`:all`のフレーム間隔は、それぞれ`SHORT_FRAME_MS`、`LONG_FRAME_MS`、`ALL_FRAME_MS`で設定します。LEDアドレスの詳細は[LED配置](docs/led_layout.ja.md)を参照してください。mrbgemを変更した後は、ファームウェアの再ビルドと再書き込みが必要です。

## ファイル構成

| ファイル                                                               | 役割                                                                      |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `main.rb`                                                              | 実行モードを選び、イルミネーションを開始します。                          |
| `mrbgems/daisenkofun-illuminations/mrbgem.rake`                        | ローカルmrbgemと`ws2812-plus`への依存を定義します。                       |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb`       | GPIOと輝度を定義します。                                                  |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/color.rb`        | イルミネーションで使用する色を定義します。                                |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/led_layout.rb`   | 572個のLEDアドレスと模型上の配置を定義します。                            |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illumination.rb` | WS2812を初期化し、選択されたイルミネーションを順番に実行して消灯します。  |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb`      | モードごとのパターン構成、`wait_ms`、`loops`、`:only`の選択を管理します。 |
| `mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illuminations/`  | 選択可能な32パターンと共通基底を実装します。                              |
| `docs/illuminations.ja.md`                                           | 選択可能なイルミネーションを説明します。                                  |
| `docs/led_layout.ja.md`                                                | 572個のLEDアドレスと模型の対応を説明します。                              |
| `docs/mrbgem_migration.ja.md`                                         | 読み込み方式の検証とmrbgemへ移管した経緯を記録します。                    |
| `docs/structure.ja.md`                                                | 大仙古墳の構造と模型で扱う要素を説明します。                              |
