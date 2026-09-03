# OximeterのPub/Sub実装

[English](pub_sub.md)

この文書では、Oximeterが測定処理と表示処理を分離するために使用するPub/Sub（Publish/Subscribe）の実装と、その仕組みが必要な理由を説明します。時間経過に応じて表示を動かす`tick`については、[`tick`による時間駆動処理](tick.ja.md)を参照してください。

## 構成

測定値からLED表示用の状態が更新されるまで、イベントは次の順序で同期的に渡されます。

```text
MAX30102
    │ red / ir
    ▼
Measurement::Processor [Publisher]
    │ publish(event, payload)
    ▼
Dispatcher
    │ call(event, payload)
    ▼
StatusLed::Presenter [Subscriber]
    └─ 表示モード、BPM、SpO2、最終拍動時刻を保持
```

| 役割 | このサンプルの実装 | 責務 |
| --- | --- | --- |
| Publisher（発行元） | `Measurement::Processor` | センサー値から指、拍動、測定結果を判定し、イベントを発行します。 |
| Dispatcher（配送役） | `Dispatcher` | 発行されたイベントを登録済みの購読先へ同期配送します。 |
| Subscriber（購読先） | `StatusLed::Presenter` | イベントをLED表示用の状態へ変換します。 |

イベント受信時は表示状態だけを更新します。8個の状態表示LEDを実際に描画する処理は、[`tick`による時間駆動処理](tick.ja.md)で説明します。

## イベントの定義

イベント名は[`lib/oximeter/measurement/events.rb`](../lib/oximeter/measurement/events.rb)の`Oximeter::Measurement::Events`に定数として定義しています。

| イベント | 発行条件 | 主なpayload |
| --- | --- | --- |
| `finger_detected` | IR値が指検出のしきい値を上回ったとき | `timestamp_ms`, `ir` |
| `finger_removed` | IR値が指除去のしきい値を下回ったとき | `timestamp_ms`, `ir` |
| `beat` | 有効範囲内の拍動間隔を検出したとき | `timestamp_ms`, `red`, `ir`, `interval_ms`, `bpm` |
| `measurement_updated` | 心拍数とSpO2の推定値を更新したとき | `timestamp_ms`, `red`, `ir`, `bpm`, `spo2` |
| `measurement_completed` | 必要数の拍動を初めて収集したとき | `timestamp_ms`, `red`, `ir`, `bpm`, `spo2` |

イベント名は処理を命令する名前ではなく、発生済みの事実を表す名前にしています。例えば`turn_led_blue`ではなく`finger_detected`を発行するため、表示方法を測定ロジックから切り離せます。

## 購読の登録

[`main.rb`](../main.rb)はDispatcherを生成し、Presenterを登録してから、同じDispatcherをProcessorへ渡します。

```ruby
dispatcher = Oximeter::Dispatcher.new
presenter = Oximeter::StatusLed::Presenter.new(renderer)
dispatcher.subscribe(presenter)
processor = Oximeter::Measurement::Processor.new(dispatcher: dispatcher)
```

`subscribe`は受け取ったオブジェクトを配列へ追加し、`self`を返します。複数の購読先を登録した場合は、登録した順番で呼び出されます。

## イベントの発行と配送

`Measurement::Processor`は状態が変化した場所で`publish`を呼び出します。指検出の例は次のとおりです。

```ruby
@dispatcher.publish(Events::FINGER_DETECTED, {
  timestamp_ms: timestamp_ms,
  ir: ir
})
```

[`Dispatcher#publish`](../lib/oximeter/dispatcher.rb)は購読先を登録順に走査し、それぞれの`call(event, payload)`をその場で呼び出します。

```ruby
def publish(event, payload)
  index = 0
  while index < @subscribers.length
    @subscribers[index].call(event, payload)
    index += 1
  end
  self
end
```

この実装はスレッド、イベントキュー、遅延配送を使わない同期型です。`publish`はすべての購読処理が終了してから呼び出し元へ戻ります。

## 購読側の処理

[`StatusLed::Presenter`](../lib/oximeter/status_led/presenter.rb)は`call`でイベントを受け取り、表示モード、BPM、SpO2、最終拍動時刻を更新します。

```ruby
def call(event, payload)
  case event
  when Measurement::Events::FINGER_DETECTED
    reset_measurement
    @mode = States::MEASURING
  when Measurement::Events::BEAT
    @bpm = payload[:bpm]
    @last_beat_at = payload[:timestamp_ms]
  # ...
  end
  self
end
```

`call`は表示に必要な状態を保存しますが、WS2812への描画は行いません。実際の描画は`tick`から行うため、センサーイベントの発生頻度とLEDのフレーム間隔を分離できます。

## Pub/Subが必要な理由

### 測定アルゴリズムを表示装置から独立させる

`Measurement::Processor`が`StatusLed::Renderer`を直接呼ぶと、測定アルゴリズムが8個のWS2812、色、アニメーションへ依存します。Pub/SubではProcessorは測定上の事実だけを発行するため、LEDがない構成でも測定処理を使用できます。

### 変更範囲を局所化する

表示色やアニメーションを変更しても測定アルゴリズムには影響しません。反対に、拍動検出やSpO2推定を変更しても、イベント名とpayloadの契約を維持すれば購読側を変更せずに済みます。

### 単体テストをしやすくする

LEDの代わりにイベントを記録する購読オブジェクトを登録すれば、実機なしでProcessorがどのイベントをどの順序で発行したか確認できます。表示側も、任意のイベントを`call`へ渡して独立して検証できます。

## 購読先を追加する例

購読クラスは`call(event, payload)`を実装します。

```ruby
class BeatLogger
  def call(event, payload)
    return self unless event == Oximeter::Measurement::Events::BEAT

    puts "BEAT,bpm=#{payload[:bpm]}"
    self
  end
end

dispatcher.subscribe(BeatLogger.new)
```

時間経過による更新も必要なコンポーネントは`tick(timestamp_ms)`を実装し、アプリケーションのループから明示的に呼び出します。Dispatcherはイベント配送だけを担当し、時間更新は行いません。

## 実装上の注意

- 配送は同期実行です。購読処理を短時間で返さないと、センサー読み取りと後続の購読先を停止させます。
- 購読先で例外が発生すると`publish`から例外が伝播し、それ以降の購読先は呼ばれません。
- 現在の実装にはイベントの保存、再送、優先順位、`unsubscribe`はありません。
- payloadは同じオブジェクトが各購読先へ渡されます。購読側では内容を変更せず、読み取り専用として扱います。
- イベント名やpayloadを変更するときは、発行側とすべての購読側を同じ契約として更新します。
