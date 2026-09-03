# 動作モードと設定

[English](modes.md)

[`main.rb`](../main.rb)の`mode`で、アプリケーションの動作を1つ選びます。各モードは相互に排他的です。

| `mode` | 使う場面 | 追加設定 |
| --- | --- | --- |
| `:illumination` | セットリストまたは単独のイルミネーションパターンを実行するとき | `setlist_name`または`pattern_key` |
| `:oximeter` | MAX30102で測定し、8個のLEDで状態を表示するとき | `duration_ms` |
| `:combined` | 測定、状態LED、拍動に同期するイルミネーション、音楽機能を同時に実行するとき | `duration_ms` |

`setlist_name`と`pattern_key`は同時に指定できません。`duration_ms`は正の整数で、Oximeterモードと複合モードでは`Oximeter::Config::RUN_DURATION_MS`（60秒）が既定値です。

## イルミネーションモード

`:illumination`は、セットリストまたは登録済みの単独パターンを実行するモードです。MAX30102と8個のOximeter状態表示LEDは初期化しません。

```ruby
mode = :illumination
setlist_name = :tests # :highlights、:story、:showcaseも選択可能
pattern_key = nil
duration_ms = nil
```

単独パターンを実行する場合は、`setlist_name = nil`にして登録済みの`pattern_key`を指定してください。`:tests`は短い確認用セットリストで、`structure_guide`を実行します。パターンの説明は[イルミネーション一覧](illuminations.ja.md)、セットリストの構成は[`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb)を参照してください。

## Oximeterモード

`:oximeter`は、MAX30102で心拍数とSpO2を推定するモードです。MAX30102と8個の状態LEDを制御しますが、572個のLEDイルミネーションとmusical購読コンポーネントは起動しません。

```ruby
mode = :oximeter
setlist_name = nil
pattern_key = nil
duration_ms = nil
```

状態LEDへ暗い白色の点が表示されたら、MAX30102のセンサー面へ指先を軽く当ててください。`event=finger_detected`の後は指を動かさず、`event=measurement_updated`または`event=measurement_completed`の推定値を確認してください。指を離すと`event=finger_removed`が出力され、測定結果はリセットされます。

> この機能は学習・演出用であり、医療機器ではありません。推定した心拍数やSpO2を診断、治療判断、安全監視に使用しないでください。

`Daisenkofun::Oximeter::Runner`が測定のライフサイクルを管理します。正常終了と例外終了のどちらでもセンサーを停止し、状態LEDを消灯します。

## 複合モード

`:combined`は、Oximeter測定、8個の状態LED、拍動に同期する572個のLED、musical購読コンポーネントを1つのイベントループで動かす、完全な対話型演出用のモードです。

```ruby
mode = :combined
setlist_name = nil
pattern_key = nil
duration_ms = nil
```

拍動を検出すると572個のLEDによる拍動イルミネーションが動作します。musical購読コンポーネントは既定で`NullOutput`を使用するため、出力を指定するまで音声ピンを取得しません。正常に終了すると`DAISENKOFUN mode=combined event=done status=ok`が表示されます。

イベントループは最初にOximeterのサンプルを読み、その後に購読コンポーネントを1回ずつ`tick`します。1 tickで処理するサンプル数は最大`MAX_SAMPLES_PER_TICK`件で、拍動イルミネーションは`50 ms`ごとに最大1フレームを描画します。

| 起動順 | コンポーネント | ハードウェア所有権 | 停止順 |
| --- | --- | --- | --- |
| 1 | `BeatIllumination` | GP14の572個のWS2812B | 3（消灯してclose） |
| 2 | `Musical::BeatSubscriber` | 注入された音声出力 | 2 |
| 3 | `Oximeter::Runner` | MAX30102と8個の状態LED | 1（発行停止、shutdown、消灯） |

イベント発行元のMAX30102を最初に停止し、その後に購読側を逆順で停止します。例外時も同じ順序です。共通tickが`25 ms`を超えて過去最大値を更新すると`event=loop_warning`、MAX30102の未処理サンプルが1 tickの上限を超えて過去最大値を更新すると`event=fifo_backlog`が出力されます。

## ハードウェアとセットリストの設定

GPIOと輝度は[`config.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb)で変更します。セットリストのパターン、`wait_ms`、`loops`は[`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb)で変更します。`:tests`、`:highlights`、`:story`、`:showcase`のフレーム間隔には、それぞれ`TESTS_FRAME_MS`、`HIGHLIGHTS_FRAME_MS`、`STORY_FRAME_MS`、`SHOWCASE_FRAME_MS`を使用します。mrbgemを変更した後は再ビルドと再書き込みをしてください。

## 実装の参照先

| パス | 役割 |
| --- | --- |
| `main.rb` | 設定検証、依存の組み立て、選択したモードの実行、終了処理 |
| `mrbgems/daisenkofun-runtime/` | 共通イベントループとコンソールロガー |
| `mrbgems/daisenkofun-illuminations/` | WS2812初期化、セットリスト、パターン、LED配置、拍動イルミネーション |
| `mrbgems/daisenkofun-oximeter/` | MAX30102測定、状態表示、実行ライフサイクル |
| `mrbgems/daisenkofun-musical/` | 拍動イベントの購読とtick型音声出力インターフェース |
