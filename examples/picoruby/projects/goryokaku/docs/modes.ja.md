# 動作モードと設定

[English](modes.md)

## 設定

[`main.rb`](../main.rb)の`Goryokaku::Application::Config`で動作を選びます。

```ruby
config = Goryokaku::Application::Config.new(
  mode: :illumination,
  setlist_name: :highlights,
  pattern_key: nil,
  repeat: false,
  buzzer_volume: 0.02
)
```

| 設定 | 用途 |
| --- | --- |
| `mode` | `:illumination`、`:musical`、`:combined`から選ぶ |
| `setlist_name` | `:tests`、`:highlights`、`:story`、`:showcase`から選ぶ |
| `pattern_key` | setlistの代わりに単独パターンを選ぶ |
| `repeat` | イルミネーションを停止まで繰り返す |
| `buzzer_volume` | PWM音量。`0`で無音にする |
| `musical_axis_signs` | MPU6050の取り付け方向に合わせて各軸を`1`または`-1`にする |
| `shake_threshold` | 振る奏法の反応しやすさを調整する |
| `strike_threshold` | 叩く奏法の反応しやすさを調整する |

PINとI2Cの既定値は[ハードウェア](hardware.ja.md)に記載しています。検出値を変更する場合は、弱い動きを拾えることだけでなく、静止時の誤発音がないことも実機で確認してください。

### 姿勢とタンバリン感度

次の値は`Goryokaku::Application::Config`の既定値です。通常は変更せず、MPU6050の取り付け方向や演奏者の動きに合わない場合だけ調整してください。

| 設定 | 既定値 | 小さくした場合／大きくした場合 |
| ---- | -----: | -------------------------------- |
| `musical_axis_signs` | `[1, 1, 1]` | 値の大小ではなく、取り付け方向が反対の軸だけ`-1`にする |
| `vertical_threshold` | `0.7` | 小さいほどY-UP／Z-UPを認識しやすいが、傾いた姿勢も拾いやすい |
| `horizontal_threshold` | `0.7` | 小さいほどX-UPを認識しやすいが、姿勢の境界が曖昧になりやすい |
| `orientation_stable_ms` | `100` | 小さいほど早く演奏可能になり、大きいほど姿勢の揺れに強い |
| `poll_interval_ms` | `20` | 小さいほど頻繁に検出するが処理回数が増える |
| `shake_threshold` | `0.2` | 小さいほど弱い振りに反応し、大きいほど誤発音を抑える |
| `shake_window_ms` | `250` | 大きいほどゆっくりした往復を1回の振りとして認識しやすい |
| `shake_reversals` | `2` | 小さいほど少ない往復で発音し、大きいほど確実な振りを要求する |
| `shake_retrigger_ms` | `100` | 大きいほど振った後の連続発音を抑える |
| `strike_threshold` | `0.45` | 小さいほど弱い打撃に反応し、大きいほど鋭い打撃だけを拾う |
| `strike_release_threshold` | `0.15` | 衝撃がこの値未満へ収まるまで次の打撃を受け付けない |
| `strike_retrigger_ms` | `120` | 大きいほど1回の打撃を複数回と誤認しにくい |

`strike_release_threshold`は`strike_threshold`より小さくしてください。まず既定値でY-UPを100 ms以上保ち、弱い振りと短い打撃を別々に試します。反応しない奏法のthresholdだけを少しずつ下げ、静止中や姿勢変更中に発音した場合は元へ戻してください。

## イルミネーションモード

`:illumination`は、選択したsetlistまたは単独パターンを380個のLEDで表示し、PWMブザーで「きらきら星」を同時に再生します。MPU6050とタッチスイッチは使用しません。

`setlist_name`と`pattern_key`は同時に指定できません。どちらも省略すると`:highlights`になります。`repeat: true`では光と曲を繰り返し、`buzzer_volume: 0`では光だけを実行します。全キー、模型上で見える演出、setlistの再生順、単独演出の設定例は[イルミネーション一覧](illuminations.ja.md)を参照してください。

## ミュージカルモード

`:musical`はタッチ選択を使わないタンバリン専用モードです。模型をY-UPにして組5を上に向け、姿勢が安定してから演奏します。

```ruby
mode: :musical,
setlist_name: nil,
pattern_key: nil,
repeat: false
```

- 振る奏法：模型面に垂直なZ軸方向へ滑らかに往復します。組5から多色の残光が移動し、「シャンシャン」という音が鳴ります。
- 叩く奏法：同じZ軸方向へ短く鋭い衝撃を与えます。星形中心から半月堡、外周へ花火状の光が広がり、立ち上がりの強い「シャンシャン」という音が鳴ります。

Y-UPから離れると演奏を停止します。このmodeでは`setlist_name`、`pattern_key`、`repeat: true`を指定できません。

## コンバインドモード

`:combined`では、姿勢とタッチスイッチでイルミネーションとタンバリンを切り替えます。

```ruby
mode: :combined,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

1. 模型をY-UPにしてタッチし、候補を選びます。
2. 半月堡の色を確認します。イルミネーションは赤、タンバリンは青です。
3. 選択色を保ったままZ-UPへ動かし、もう一度タッチして決定します。

候補を選ぶ前のZ-UPタッチと、Y-UP／Z-UP以外のタッチは無視されます。

選択待ちのLEDは現在の姿勢も示します。Z-UPでは全体が温白色、Y-UPとX-UPでは星形本体が桜色になります。候補を選択すると、姿勢をZ-UPへ変えても半月堡の赤または青を保持します。

| 決定したmode | 動作 |
| --- | --- |
| イルミネーション | 選択したsetlistと「きらきら星」を1回再生し、現在姿勢の表示へ戻る |
| タンバリン | Y-UPへ戻すと、振る／叩く奏法を音と光で演奏できる |

イルミネーションを決定するたびに、指定したsetlistと「きらきら星」を先頭から1回再生します。再生が終わると現在姿勢の表示へ戻ります。タンバリンを決定すると選択表示を消灯するので、Y-UPへ戻して演奏してください。待機中は姿勢変化とタッチ操作がログに表示され、約5秒ごとの`event=alive`で動作を確認できます。
