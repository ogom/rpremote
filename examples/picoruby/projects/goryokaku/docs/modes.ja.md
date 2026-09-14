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

## イルミネーションモード

`:illumination`は、選択したsetlistまたは単独パターンを380個のLEDで表示し、PWMブザーで「きらきら星」を同時に再生します。MPU6050とタッチスイッチは使用しません。

`setlist_name`と`pattern_key`は同時に指定できません。どちらも省略すると`:highlights`になります。`repeat: true`では光と曲を繰り返し、`buzzer_volume: 0`では光だけを実行します。選択できる演出は[イルミネーション一覧](illuminations.ja.md)を参照してください。

## ミュージカルモード

`:musical`はタッチ選択を使わないタンバリン専用モードです。模型をY-UPにして組5を上に向け、姿勢が安定してから演奏します。

- 振る奏法：模型面に垂直なZ軸方向へ滑らかに往復します。組5から多色の残光が移動し、「シャンシャン」という音が鳴ります。
- 叩く奏法：同じZ軸方向へ短く鋭い衝撃を与えます。星形中心から半月堡、外周へ花火状の光が広がり、立ち上がりの強い「シャンシャン」という音が鳴ります。

Y-UPから離れると演奏を停止します。このmodeでは`setlist_name`、`pattern_key`、`repeat: true`を指定できません。

## コンバインドモード

`:combined`では、姿勢とタッチスイッチでイルミネーションとタンバリンを切り替えます。

1. 模型をY-UPにしてタッチし、候補を選びます。
2. 半月堡の色を確認します。イルミネーションは赤、タンバリンは青です。
3. 選択色を保ったままZ-UPへ動かし、もう一度タッチして決定します。

候補を選ぶ前のZ-UPタッチと、Y-UP／Z-UP以外のタッチは無視されます。

| 決定したmode | 動作 |
| --- | --- |
| イルミネーション | 選択したsetlistと「きらきら星」を1回再生し、現在姿勢の表示へ戻る |
| タンバリン | Y-UPへ戻すと、振る／叩く奏法を音と光で演奏できる |

待機中は姿勢変化とタッチ操作がログに表示され、約5秒ごとの`event=alive`で動作を確認できます。
