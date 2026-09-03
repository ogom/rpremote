# `tick`による時間駆動処理

[English](tick.md)

この文書では、`main.rb`の実行ループが`StatusLed::Presenter#tick(timestamp_ms)`を呼び出し、時間依存のLED表示を1段階ずつ進める仕組みを説明します。状態変化を通知する`publish`とPub/Sub全体については、[OximeterのPub/Sub実装](pub_sub.ja.md)を参照してください。

## `publish`と`tick`の違い

| 呼び出し | 意味 | 受け取り側 |
| --- | --- | --- |
| `dispatcher.publish(event, payload)` | 指検出や拍動などの状態変化を通知します。 | `call(event, payload)` |
| `presenter.tick(timestamp_ms)` | 現在時刻を渡し、LEDアニメーションを1段階進めます。 | `tick(timestamp_ms)` |

`tick`自体はセンサーを読み取らず、測定イベントも生成しません。イベント配送を担当する`Dispatcher`にも`tick`はありません。時間駆動コンポーネントを明示的に呼ぶことで、イベント契約と実行スケジュールを分離しています。

## 呼び出しの流れ

[`main.rb`](../main.rb)はMAX30102のFIFOにあるサンプルを処理した後、メインループごとにPresenterの`tick`を呼び出します。

```ruby
while @clock.millis - started_at < @duration_ms
  available = @sensor.available_samples
  while available > 0
    sample = @sensor.read
    @processor.process_sample(
      red: sample[:red],
      ir: sample[:ir],
      timestamp_ms: @clock.millis
    )
    available -= 1
  end
  @presenter.tick(@clock.millis)
  @clock.wait_ms(@poll_interval_ms)
end
```

```text
FIFOサンプルを読み取る
        │
        ▼
Measurement::Processor#process_sample
        │ 必要ならイベントをpublish
        ▼
StatusLed::Presenter#call ──▶ 表示状態を保存
        │
        ▼ ループから明示的にtick
StatusLed::Presenter#tick
        │
        ▼
StatusLed::Renderer#render ──▶ 更新間隔に達していればLEDを描画
```

## LED表示での利用

`StatusLed::Presenter#call`は、測定イベントから次の内部状態を更新します。

- 表示モード：`:no_finger`、`:measuring`、`:result`
- 推定BPMとSpO2
- 最後に拍動を検出した時刻

`StatusLed::Presenter#tick`は、その状態と`timestamp_ms`を[`StatusLed::Renderer#render`](../lib/oximeter/status_led/renderer.rb)へ渡します。

```ruby
def tick(timestamp_ms)
  @renderer.render(
    @mode,
    timestamp_ms,
    spo2: @spo2,
    bpm: @bpm,
    last_beat_at: @last_beat_at
  )
  self
end
```

Rendererは、前回の描画時刻からモード別の間隔が経過していなければ何も描画せずに戻ります。

| モード | 描画間隔 | 動作 |
| --- | --- | --- |
| `:no_finger` | 120 ms | 暗い白色の点を移動します。 |
| `:measuring` | 90 ms | 青色の点と軌跡を移動します。 |
| `:result` | 40 ms | BPMと最終拍動時刻から表示位置を求めます。 |

この間引きにより、メインループは約2 msごとに`tick`を呼び出せますが、WS2812への送信は必要なフレームだけに制限されます。

## `tick`が必要な理由

イベントだけでLEDを描画すると、指待ちのように新しいイベントが発生しない状態ではアニメーションが止まります。また、拍動イベントが発生した瞬間だけでは、次の拍動までの移動表示を作れません。

イベントで「何が起きたか」を保存し、`tick`で「現在時刻ではどう見せるか」を計算することで、次を分離できます。

- センサーのサンプリング周期
- 指検出や拍動イベントの発生頻度
- LEDアニメーションのフレーム間隔

## 実装時のルール

- `tick`は短時間で戻し、内部で`sleep_ms`を呼びません。
- 1回の`tick`で長いループや複数フレームの一括描画を行わず、必要なら1段階だけ進めます。
- 経過時間は呼び出し元から渡された`timestamp_ms`で判定します。コンポーネントごとに時刻を読み直さず、同一ループの時間基準を揃えます。
- `tick`内の例外は呼び出し元へ伝播します。
- `tick`は同期処理であり、別スレッドや割り込みではありません。

## 現在の単独サンプルの制約

単独Oximeterのメインループは、FIFOにある全サンプルを処理してからPresenterの`tick`を呼び出します。サンプルが大量に滞留した場合は、LEDの更新間隔が延びる可能性があります。

これは処理順序から生じる可能性であり、LED乱れの原因を特定するものではありません。同時動作へ拡張するときは、1ループで処理するセンサーサンプル数を制限し、各コンポーネントの`tick`が定期的に呼ばれる構成を検討します。Daisenkofun側の共通イベントループでは、この上限を`MAX_SAMPLES_PER_TICK`として設けています。
