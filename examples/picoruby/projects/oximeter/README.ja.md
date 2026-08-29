# MAX30102とSPI NeoPixelによるパルスオキシメーター

[English](README.md)

MAX30102から心拍数とSpO2を推定し、8個のWS2812/NeoPixelで測定状態を表示するサンプルです。心拍数とSpO2の推定値はシリアルログで確認できます。

> このサンプルは学習用であり、医療機器ではありません。診断、治療判断、安全監視には使用しないでください。

## 配線

MAX30102をI2Cで接続します。

| MAX30102 | Raspberry Pi Pico 2 |
| --- | --- |
| VIN | 使用するブレークアウトボードの対応電圧 |
| GND | GND |
| SDA | GP16 |
| SCL | GP17 |

WS2812/NeoPixelをSPIで接続します。

| WS2812/NeoPixel | Raspberry Pi Pico 2 |
| --- | --- |
| DIN | GP3（`RP2040_SPI0`のCOPI） |
| GND | GND（PicoとLED外部電源で共通化） |
| LED電源 | 8個のLEDに対応できる外部電源 |

GP2はSPI SCKとして設定されますが、LEDには接続しません。

GPIOからLEDへ給電しないでください。LEDを5 Vで使用する場合は、3.3 Vから5 Vへのロジックレベル変換を推奨します。MAX30102ブレークアウトボードの対応入力電圧とI2Cレベル変換の有無も確認してください。

## ビルドと実行

リポジトリの`Mrbgems`には、必要なローカルmrbgemである[max30102](../../mrbgems/max30102/README.ja.md)と[ws2812_spi](../../mrbgems/ws2812_spi/README.ja.md)が定義されています。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote bootsel
rpremote flash
rpremote fs push examples/picoruby/projects/oximeter/lib/oximeter :/lib/oximeter
rpremote run examples/picoruby/projects/oximeter/main.rb --timeout 70
```

`fs push`はアプリのクラスをR2P2の`/lib/oximeter`へ転送します。ローカルの`lib/oximeter`内を変更した場合は、再度実行してください。

アプリは60秒間動作した後、MAX30102をシャットダウンしてLEDを消灯します。実行時間を変更するには、`lib/oximeter/config.rb`の`RUN_DURATION_MS`を編集します。`rpremote run --timeout`には、アプリの実行時間より長い値を指定してください。

## 使用方法

1. アプリを実行し、LEDに暗い白色の点が表示されるまで待ちます。
2. MAX30102のセンサー面に指先を軽く当てます。
3. LEDが青色の測定中表示に変わったら、指を動かしたり離したりせず、そのまま保ちます。
4. シリアルログに`OXIMETER_DATA,...,RESULT`が表示されたら、心拍数とSpO2の推定値を確認します。

測定中に指を離すと結果がリセットされ、指待ちの状態に戻ります。もう一度、指先を安定して当てて測定してください。

## 状態表示

### LED

| 状態 | LED表示 |
| --- | --- |
| 指待ち | 暗い白色の点が移動します。 |
| 測定中 | 青色の点が、暗い緑色の軌跡を伴って移動します。 |
| 測定完了（SpO2が97%以上） | 直前に検出した拍動と同期して、緑色の点が移動します。 |
| 測定完了（SpO2が97%未満） | 直前に検出した拍動と同期して、赤色の点が移動します。 |
| センサー初期化エラー | すべてのLEDが一時的に赤色になります。 |

緑色と赤色の切り替えに使う97%は、このサンプルの表示用しきい値です。医療上の判断基準ではありません。

### シリアルログ

| ログ | 意味 |
| --- | --- |
| `OXIMETER_START,...` | MAX30102を検出し、測定を開始しました。I2Cアドレスと実行時間を表示します。 |
| `Place a fingertip steadily over the MAX30102.` | センサーに指先を安定して当てるよう案内しています。 |
| `OXIMETER_WAIT,...` | 指を待っています。`red`と`ir`は赤色光と赤外光の生値です。 |
| `OXIMETER_FINGER,...,DETECTED,...` | 指を検出し、測定を開始しました。 |
| `OXIMETER_FINGER,...,REMOVED,...` | 指が離れたため、測定結果をリセットしました。 |
| `OXIMETER_BEAT,...,BUFFERING,...` | SpO2の推定に必要なセンサー値を収集中です。 |
| `OXIMETER_BEAT,...,SKIPPED,...` | 拍動候補の間隔が有効範囲外だったため、計算から除外しました。 |
| `OXIMETER_DATA,...,MEASURING` | 推定途中の値です。引き続き指を動かさずに待ちます。 |
| `OXIMETER_DATA,...,RESULT` | 8回の有効な拍動間隔から得た測定結果です。 |
| `OXIMETER_DONE,...` | 実行時間が終了しました。終了時点の心拍数とSpO2を表示します。 |
| `OXIMETER_ERROR,...` / `OXIMETER_WARN,...` | センサーの初期化または終了処理で問題が発生しました。 |

測定値は次の形式で表示されます。

```text
OXIMETER_DATA,timestamp_ms,red,ir,bpm,spo2,MEASURING|RESULT
```

- `timestamp_ms`: ボード起動後の経過時間（ミリ秒）
- `red`, `ir`: 赤色光と赤外光の生値
- `bpm`: 推定心拍数（1分あたりの拍動数）
- `spo2`: 推定SpO2（%）
- `MEASURING` / `RESULT`: 測定途中または測定完了

`SKIPPED`が表示されても、指を安定して当てたまま測定を続けてください。繰り返し表示されて結果が得られない場合は、指の位置や押し当てる強さ、周囲光を調整してください。

## 推定方法と制約

拍動検出には、IR値の8サンプル移動平均、50サンプルのベースライン、ヒステリシス付きのしきい値判定を使用します。350〜1500 msの拍動間隔を有効とし、最大8回分の平均から心拍数を求めます。指の検出基準はIR値20,000、ヒステリシスは3,000です。

SpO2の推定には、赤色光と赤外光をそれぞれ100サンプル使用します。各チャンネルのDC平均とAC標準偏差からratio-of-ratiosを求め、`110 - 25 × ((red_ac / red_dc) / (ir_ac / ir_dc))`を適用して0〜100%に制限します。

この計算式の係数は、使用するハードウェア向けに校正されていません。体動、周囲光、センサーを押す強さ、皮膚や循環の差、LED電流、ブレークアウトボードによって結果は大きく変化します。アルゴリズムを評価する場合は、適切に検証された機器と比較してください。

## ファイル構成

| ファイル | 役割 |
| --- | --- |
| `main.rb` | ハードウェアを初期化し、アプリの実行時間と終了処理を管理します。 |
| `lib/oximeter/config.rb` | 配線、サンプリング、検出、表示の設定を定義します。 |
| `lib/oximeter/rolling_statistics.rb` | サンプルの保持、平均値、標準偏差の計算を担当します。 |
| `lib/oximeter/monitor.rb` | 指と拍動を検出し、心拍数とSpO2を推定します。 |
| `lib/oximeter/status_leds.rb` | NeoPixelの状態表示を制御します。 |
