# 動作モードと設定

[English](modes.md)

## イルミネーションモード

`:illumination`は、380個のLEDとPWMブザーを使用します。MPU6050とタッチスイッチは初期化しません。

```ruby
config = Goryokaku::Application::Config.new(
  mode: :illumination,
  setlist_name: :highlights,
  pattern_key: nil,
  repeat: false,
  led_pin: 14,
  led_count: 380,
  buzzer_pin: 18,
  buzzer_volume: 1
)
```

`setlist_name`と`pattern_key`は同時に指定できません。両方が`nil`の場合は`:highlights`を使用します。`repeat: true`は選択したセットリストまたはパターンを停止するまで繰り返します。

LED演出の開始と同時に、PWMブザーで「きらきら星」を再生します。曲は`C4 C4 G4 G4 A4 A4 G4 / F4 F4 E4 E4 D4 D4 C4`の14音で、通常音を400 ms、各フレーズ末尾を800 ms、音間を50 msとします。`repeat: false`ではLED演出が先に完了しても曲を最後まで1回再生し、`repeat: true`ではLEDと曲の両方を繰り返します。`buzzer_volume: 0`で曲を無効化できます。終了時と例外時はPWM dutyを0へ戻します。

### セットリスト

| 名前 | 内容 |
| --- | --- |
| `:tests` | 温白色の短い動作確認 |
| `:highlights` | 星形、半月堡、外周、虹、全景、花火を短く紹介する7演出 |
| `:story` | 城郭の出現、星空、紅白、桜、満開、花火へ展開する15演出 |
| `:showcase` | 登録済み21演出をすべて確認する全演出集 |

### 単独パターン

単独パターンでは`setlist_name: nil`にし、次のいずれかを`pattern_key`へ指定します。

| キー | 演出 |
| --- | --- |
| `:warm_white` | 全体を温白色でフェードイン |
| `:sakura_breathe` | 五芒星を桜色で呼吸明滅 |
| `:star_twinkle` | 五芒星をきらめかせる |
| `:ravelin_pulse` | 半月堡をパルス点灯 |
| `:outer_comet` | 外周を彗星状に点灯 |
| `:rainbow` | 五芒星へ虹色の軌跡を流す |
| `:parallel_left` | 左側の辺を並列点灯 |
| `:parallel_right` | 右側の辺を並列点灯 |
| `:full_zones` | 全ゾーンを順番に点灯、呼吸、消灯 |
| `:fireworks` | 花火演出を3回実行 |
| `:kouhaku` | 全体を紅白で交互に点滅 |
| `:twinkle` | 全体へ金色のきらめきを表示 |
| `:shooting_star` | 全体に金色の流れ星を表示 |
| `:breathing` | 全体を金色で呼吸明滅 |
| `:constellation` | 紅白の背景に金色の星を表示 |
| `:sakura_fubuki` | 全体に桜吹雪を表示 |
| `:sakura_stream` | 全体に桜色の流れを表示 |
| `:sakura_gradient` | 全体に桜色の帯を表示 |
| `:sakura_breathing` | 全体を桜色で呼吸明滅 |
| `:hanami` | 紅白の背景に桜色の光を表示 |
| `:mankai` | 全体を複数の桜色で点灯 |

例:

```ruby
mode: :illumination,
setlist_name: nil,
pattern_key: :fireworks,
repeat: false
```

各演出の開始時に次の形式でログを出力し、終了時には全LEDを消灯します。

```text
GORYOKAKU mode=illumination event=pattern index=1/7 key=warm_white wait_ms=35 loops=1
GORYOKAKU mode=illumination event=led_off
```

## ミュージカルモード

`:musical`はタッチ選択を使用せず、MPU6050、PWMブザー、380個のLEDを連動させるタンバリン専用モードです。

```ruby
mode: :musical,
setlist_name: nil,
pattern_key: nil,
repeat: false
```

Y-UPで星形本体の組5を上にして100 ms保持すると演奏可能になります。Z軸加速度が0.2 g以上となる滑らかな往復反転を2回検出する「振る（フル）奏法」では、弱い振りでも4.2〜7.4 kHzの金属的な高音を20 msごとに切り替えて減衰させる「シャンシャン」音とともに、組5から星形5組を多色の残光で走査します。同じZ軸へ鋭い衝撃を与える「叩く奏法」は0.45 g以上のjerkで検出し、4.1〜7.8 kHzの6音を20 msごとに減衰させる、立ち上がりの強い「シャンシャン」音を鳴らします。LEDは`fireworks`を参考に、星形中心から10方向へ多色の光を広げ、半月堡を点滅させた後に外周を大きく発光させます。0.15 g未満まで衝撃が収まるまで再検出せず、微小な静止ノイズによる連続発音を抑えます。

音と光は同じ奏法イベント、開始時刻、強度、継続時間を使用します。Y-UPから離れた場合、終了時、例外時はPWM dutyを0にして全LEDを消灯します。このモードでは`setlist_name`、`pattern_key`、`repeat: true`を指定できません。

## コンバインドモード

旧`my-penta`のセンサー連動動作は`:combined`で利用できます。

```ruby
mode: :combined,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

起動時はモード未選択です。最初のY-UPタッチでイルミネーションが選択され、以後のY-UPタッチでタンバリンと交互に切り替わります。モードは次の手順で選択・決定します。

1. IMUをY-UPにしてタッチスイッチを押し、選択候補を切り替える。
2. 半月堡の色を確認する。イルミネーション候補は赤、タンバリン候補は青で表示する。
3. IMUをZ-UPにしてタッチスイッチを押し、表示中の候補を確定する。

選択表示はZ-UPへ姿勢を変えても保持され、Z-UPでのタッチによって初めて実行モードへ反映されます。候補未選択時のZ-UPタッチと、Y-UP／Z-UP以外でのタッチは無視します。

| 状態 | 動作 |
| --- | --- |
| イルミネーションモード | Z-UPで全体を暖白色、Y-UP／X-UPで星郭を桜色に表示する。確定時は「きらきら星」と`setlist_name`を1回実行し、動きでは発音しない |
| タンバリンモード | Y-UPへ戻して演奏する。振る奏法は組5から多色の残光を走査し、叩く奏法は星形中心から半月堡・外周へ広がる花火状の光をシャンシャン音と同期する |

イルミネーションモードを確定するたびに、「きらきら星」とセットリストを先頭から実行し、両方の完了後は現在の姿勢に応じた表示へ戻ります。実行中は再生が完了するまで入力処理を待機します。タンバリンモードを確定すると選択表示を含むLEDを消灯します。`setlist_name`を省略した場合は`:highlights`を使用します。このモードでは`pattern_key`と`repeat: true`を指定できません。
