# OximeterのPub/Sub設計

[English](pub_sub.md)

Oximeterは、センサー値を解釈する測定処理と、その結果を見せるLED表示をPub/Subで分離します。この資料は実装手順ではなく、分離する理由と変更時に守る境界を説明します。時間による描画は[`tick`による時間駆動](tick.ja.md)を参照してください。

## 構成

```text
MAX30102
    │ red / ir
    ▼
Measurement::Processor ── publish ──▶ Dispatcher
                                           │ 同期配送
                                           ▼
                                  StatusLed::Presenter
                                           │ 表示状態
                                           ▼
                                  StatusLed::Renderer
```

| 役割 | 実装 | 責務 |
| ---- | ---- | ---- |
| Publisher | `Measurement::Processor` | 指、拍動、推定結果という測定上の事実を発行する |
| Dispatcher | `Dispatcher` | 登録された購読先へイベントを同期配送する |
| Subscriber | `StatusLed::Presenter` | 測定イベントをLED表示用の状態へ変換する |
| Renderer | `StatusLed::Renderer` | 現在時刻と表示状態から8個のLEDを描画する |

ProcessorはLEDの色やアニメーションを知りません。Presenterもセンサーを読みません。この境界により、LEDのない構成で測定したり、測定アルゴリズムを変えずに表示を交換したりできます。

## 測定イベント

イベント名は命令ではなく、すでに発生した事実を表します。例えば`turn_led_blue`ではなく`finger_detected`を発行することで、青色にする判断を表示側に残します。

| イベント | 意味 |
| -------- | ---- |
| `finger_detected` | 指を検出し、新しい測定を開始した |
| `finger_removed` | 指が離れ、測定状態をリセットした |
| `beat` | 有効な拍動間隔を検出した |
| `measurement_updated` | 心拍数とSpO2の推定値を更新した |
| `measurement_completed` | 必要な拍動数へ初めて到達した |

イベント名の正本は[`measurement/events.rb`](../lib/oximeter/measurement/events.rb)です。payloadには時刻と、その事実を解釈するために必要な測定値だけを含めます。

## 同期配送を使う理由

イベント数と購読先が少ないため、スレッドやキューを持たない同期配送にしています。処理順が見えやすく、PicoRuby上のメモリ消費と終了処理を単純にできます。

一方で、購読処理が長いとセンサー読み取りと後続の購読先を止めます。購読先の例外は発行元へ伝わり、それ以降の購読先は呼ばれません。イベントの保存、再送、優先順位、購読解除もありません。

このため購読先は次を守ります。

- `call(event, payload)`を短時間で返す
- payloadを読み取り専用として扱う
- 時間のかかるアニメーションを`call`内で完走させない
- イベント名やpayloadを変えるときは発行側と購読側を一緒に更新する

## イベントと時間の分離

Presenterの`call`は「何が起きたか」を表示状態として保存するだけです。WS2812への描画はメインループから呼ばれる`tick(timestamp_ms)`が進めます。

この分離により、指待ちのようにイベントが発生しない時間もLEDを動かせます。また、センサーのサンプリング周期、測定イベントの頻度、LEDのフレーム間隔を独立して調整できます。
