# MAX30102とSPI NeoPixelによるパルスオキシメーター

[English](README.md)

MAX30102から心拍数とSpO2を推定し、8個のWS2812/NeoPixelで測定状態を表示するPicoRubyサンプルです。推定値はシリアルログで確認します。

> このサンプルは学習用であり、医療機器ではありません。診断、治療判断、安全監視には使用しないでください。

## 配線と安全

| MAX30102 | Raspberry Pi Pico 2 |
| -------- | ------------------- |
| VIN | 使用するブレークアウトボードの対応電圧 |
| GND | GND |
| SDA | GP16 |
| SCL | GP17 |

| WS2812/NeoPixel | Raspberry Pi Pico 2 |
| ---------------- | ------------------- |
| DIN | GP3（`RP2040_SPI0`のCOPI） |
| GND | PicoとLED外部電源の共通GND |
| LED電源 | 8個のLEDに対応できる外部電源 |

GP2はSPI SCKとして設定されますが、LEDには接続しません。GPIOからLEDへ給電しないでください。LEDを5 Vで使う場合は3.3 Vから5 Vへのロジックレベル変換を推奨します。MAX30102ブレークアウトボードの対応入力電圧とI2Cレベル変換の有無も確認してください。

## ビルドと実行

ルートの`Mrbgems`で[max30102](../../mrbgems/max30102/README.ja.md)と[ws2812_spi](../../mrbgems/ws2812_spi/README.ja.md)を有効にし、リポジトリルートから配置します。

```sh
rpremote mrbgems lock
rpremote deploy --build examples/picoruby/projects/oximeter --timeout 120
```

`deploy`はファームウェアを書き込み、`lib/oximeter`を転送して`main.rb`を実行します。`main.rb`だけを変更した場合は、組み込み済みファームウェアと転送済みライブラリに対して次を実行できます。

```sh
rpremote run examples/picoruby/projects/oximeter --timeout 120
```

アプリは60秒間動作し、終了時にMAX30102をシャットダウンしてLEDを消灯します。

## 測定方法

1. 実行し、LEDに暗い白色の点が表示されるまで待ちます。
2. MAX30102のセンサー面へ指先を軽く当てます。
3. LEDが青色になったら、指を動かさずに保ちます。
4. ログに`OXIMETER_DATA,...,RESULT`が表示されたら推定値を確認します。

途中で指を離すと測定結果をリセットし、指待ちへ戻ります。`SKIPPED`が繰り返される場合は、指の位置、押し当てる強さ、周囲光を調整してください。

## 状態表示

| 状態 | LED表示 |
| ---- | ------- |
| 指待ち | 暗い白色の点が移動する |
| 測定中 | 青色の点が暗い緑色の軌跡と移動する |
| 測定完了、SpO2が97%以上 | 最後の拍動に同期して緑色の点が移動する |
| 測定完了、SpO2が97%未満 | 最後の拍動に同期して赤色の点が移動する |
| センサー初期化エラー | 全LEDが一時的に赤色になる |

97%はこのサンプルの表示色を選ぶための値であり、医療上の判断基準ではありません。

主なログは、`OXIMETER_WAIT`（指待ち）、`OXIMETER_FINGER`（指の検出・除去）、`OXIMETER_BEAT`（拍動または収集中）、`OXIMETER_DATA`（推定値）、`OXIMETER_DONE`（終了）、`OXIMETER_ERROR`／`OXIMETER_WARN`（異常）です。

```text
OXIMETER_DATA,timestamp_ms,red,ir,bpm,spo2,MEASURING|RESULT
```

## 推定方法と限界

拍動検出にはIR値の移動平均、ベースライン、ヒステリシスを使用し、350 msより長く1500 ms未満の拍動間隔から心拍数を推定します。SpO2は赤色光と赤外光のDC平均とAC標準偏差からratio-of-ratiosを求め、0〜100%へ制限します。

この計算は使用するハードウェア向けに校正されていません。体動、周囲光、指の圧力、皮膚や循環の差、LED電流、ブレークアウトボードによって結果は大きく変わります。アルゴリズムを評価するときは、適切に検証された機器と比較してください。

## 設計資料とテスト

- [Pub/Subの設計](docs/pub_sub.ja.md) — 測定処理と表示処理を分離する理由
- [`tick`による時間駆動](docs/tick.ja.md) — イベントがない間もLEDを動かす方法

ホスト上の仕様はリポジトリルートから実行します。

```sh
rake spec:examples:picoruby:oximeter
```

RSpecは設定、計算、イベント、表示、資料の契約を検証します。`test/`のPicotestはPicoRuby／mruby/cでのロードと構成を確認します。物理的な電源、センサー精度、光、タイミングは実機で確認してください。
