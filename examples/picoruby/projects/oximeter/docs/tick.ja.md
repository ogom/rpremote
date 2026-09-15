# `tick`による時間駆動

[English](tick.md)

測定イベントは「何が起きたか」を通知します。LEDアニメーションには、イベントがない間も「現在時刻ではどう見せるか」を更新する仕組みが必要です。その役割を`StatusLed::Presenter#tick(timestamp_ms)`が担います。

## `publish`との違い

| 呼び出し | 役割 |
| -------- | ---- |
| `dispatcher.publish(event, payload)` | 指検出や拍動などの状態変化を同期通知する |
| `presenter.tick(timestamp_ms)` | 現在時刻を渡し、表示を必要なら1フレーム進める |

`tick`はセンサーを読まず、測定イベントも生成しません。Dispatcherも時間を進めません。イベント配送の設計は[Pub/Subの設計](pub_sub.ja.md)を参照してください。

## 呼び出しの流れ

```text
MAX30102のFIFOを読む
        │
        ▼
Measurement::Processor#process_sample
        │ 必要ならpublish
        ▼
StatusLed::Presenter#call ──▶ 表示状態を保存
        │
        ▼ メインループからtick
StatusLed::Presenter#tick
        │
        ▼
StatusLed::Renderer#render ──▶ 描画間隔に達した場合だけ送信
```

メインループはFIFOのサンプルを処理した後、Presenterへ同じボード時刻を渡します。Presenterは表示モード、BPM、SpO2、最後の拍動時刻をRendererへ渡し、Rendererがフレームの要否と位置を決めます。

## 表示間隔

| 状態 | 間隔 | 表示 |
| ---- | ---: | ---- |
| 指待ち | 120 ms | 暗い白色の点 |
| 測定中 | 90 ms | 青色の点と緑色の軌跡 |
| 結果 | 40 ms | BPMと最後の拍動に同期する緑色または赤色の点 |

メインループは約2 msごとに`tick`できますが、Rendererは必要な時刻までWS2812へ再送しません。これにより測定ループを止めずにLED転送を抑えます。

## 実装上の境界

- `tick`は`sleep_ms`を呼ばず、短時間で戻る
- 1回の呼び出しでは必要な1フレームだけを描画する
- 経過時間は呼び出し元の`timestamp_ms`で判断する
- 例外は呼び出し元へ伝え、終了処理でセンサー停止と消灯を行う
- `tick`は同期処理であり、スレッドや割り込みではない

## 単独サンプルの制約

現在のメインループは、FIFO内の全サンプルを処理してから`tick`を呼びます。サンプルが大量に滞留するとLED更新が遅れる可能性があります。

同時動作へ拡張する場合は、1ループで処理するサンプル数を制限し、各コンポーネントが定期的に`tick`される構成を検討します。これは処理順から分かる制約であり、個別のLED異常原因を断定するものではありません。
