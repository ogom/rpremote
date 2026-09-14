# 動作モードと設定

[English](modes.md)

[`main.rb`](../main.rb)の`Daisenkofun::Application::Config`で動作を選びます。

| `mode` | 動作 |
| --- | --- |
| `:illumination` | 登録済みのsetlistまたは単独パターンを再生する |
| `:oximeter` | MAX30102で測定し、8個の状態LEDへ表示する |
| `:combined` | 測定、572個のLED、状態LED、PWM音を同期して動かす |

## 設定例

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :combined,
  setlist_name: nil,
  pattern_key: nil,
  repeat: false,
  duration_ms: 60_000,
  ws2812_pin: 14,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  spi_sck_pin: 2,
  spi_copi_pin: 3,
  buzzer_pin: 18,
  buzzer_volume: 3,
  musical_style: :heartbeat_signature
)
```

| 項目 | 用途 |
| --- | --- |
| `setlist_name` | `:tests`、`:highlights`、`:story`、`:showcase`から選ぶ |
| `pattern_key` | 登録済みパターンを1つ選ぶ |
| `repeat` | イルミネーションを中断まで繰り返す |
| `duration_ms` | Oximeterまたは複合モードの実行時間 |
| 各PIN | 模型の配線に合わせてGPIOを指定する |
| `buzzer_pin` | `nil`で音を無効にする |
| `buzzer_volume` | 0〜100。`0`で音を無効にする |
| `musical_style` | `:pulse_translation`、`:kofun_canon`、`:heartbeat_signature`から選ぶ |

`setlist_name`と`pattern_key`は同時に指定できません。イルミネーションモードでは`duration_ms`を指定せず、Oximeterと複合モードでは正の実行時間を指定します。

## イルミネーションモード

`:illumination`は、MAX30102と8個の状態LEDを使用せず、572個のLEDで選択した演出を再生します。短い動作確認には次の設定を使います。

```ruby
mode: :illumination,
setlist_name: :tests,
pattern_key: nil,
repeat: false,
duration_ms: nil
```

単独演出は`setlist_name: nil`にして`pattern_key`を指定します。`repeat: false`では1回再生して消灯し、`repeat: true`では中断するまで繰り返します。利用できる全キー、見える演出、setlistの再生順は[イルミネーション一覧](illuminations.ja.md)を参照してください。

## Oximeterモード

```ruby
mode: :oximeter,
duration_ms: 60_000
```

状態LEDが待機表示になったらMAX30102へ指先を軽く当てます。指を動かさず、`event=measurement_updated`または`event=measurement_completed`を確認してください。指を離すと測定値はリセットされます。

> 推定した心拍数とSpO₂は演出用です。医療判断には使用しないでください。

## 複合モード

```ruby
mode: :combined,
duration_ms: 60_000,
buzzer_volume: 3,
musical_style: :heartbeat_signature
```

心拍を検出すると、選択した`musical_style`に応じて音と濠の輪郭LEDが動きます。

- `:pulse_translation`: 心拍ごとの主音と応答音
- `:kofun_canon`: 内濠・中濠・外濠を巡る3音の輪唱
- `:heartbeat_signature`: 7拍は輪唱し、8拍目に直近8拍から作った8音を演奏

音の意味と調整方法は[生体パルスと音楽](biometric_pwm_music.ja.md)を参照してください。
