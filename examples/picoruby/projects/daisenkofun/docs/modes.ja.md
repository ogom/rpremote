# 動作モードと設定

[English](modes.md)

[`main.rb`](../main.rb)の`Daisenkofun::Application::Config`で、アプリケーションの動作を1つ選びます。各モードは相互に排他的です。

| `mode` | 使う場面 | 追加設定 |
| --- | --- | --- |
| `:illumination` | セットリストまたは単独のイルミネーションパターンを実行するとき | `setlist_name`または`pattern_key`、`repeat` |
| `:oximeter` | MAX30102で測定し、8個のLEDで状態を表示するとき | `duration_ms` |
| `:combined` | 測定、状態LED、拍動に同期するイルミネーション、音楽機能を同時に実行するとき | `duration_ms`、`buzzer_pin`、`musical_style` |

`setlist_name`と`pattern_key`は同時に指定できません。`duration_ms`は正の整数で、Oximeterモードと複合モードでは`Oximeter::Config::RUN_DURATION_MS`（60秒）が既定値です。

## 設定項目

次の表は`Daisenkofun::Application::Config`が解決する既定値です。現在の`main.rb`は同じGPIO値を明示し、`duration_ms: 60_000`を指定しています。

| 項目 | 既定値または解決後の値 | 使用するモード・用途 |
| --- | --- | --- |
| `mode` | `:combined` | アプリケーションの動作モード |
| `setlist_name` | `nil`。イルミネーションモードでパターンも未指定なら`:highlights` | イルミネーションモード |
| `pattern_key` | `nil` | イルミネーションモード |
| `repeat` | `false` | イルミネーションモード |
| `duration_ms` | `nil`。Oximeter・複合モードでは`60_000` | Oximeter・複合モード |
| `ws2812_pin` | `14` | 572個のイルミネーションLEDのデータ |
| `i2c_sda_pin` / `i2c_scl_pin` | `16` / `17` | MAX30102のI2C |
| `spi_sck_pin` / `spi_copi_pin` | `2` / `3` | `RP2040_SPI0`経由の8個の状態LED |
| `buzzer_pin` | `18`。`nil`で無音 | 複合モード |
| `musical_style` | `:heartbeat_signature` | 複合モード |

`mode`は`:illumination`、`:oximeter`、`:combined`のいずれか、`musical_style`は`:pulse_translation`、`:kofun_canon`、`:heartbeat_signature`のいずれかです。WS2812/I2C/SPIの5つのPIN値は0以上の整数である必要があり、ハードウェアを初期化する前に検証されます。

## イルミネーションモード

`:illumination`は、セットリストまたは登録済みの単独パターンを実行するモードです。MAX30102と8個のOximeter状態表示LEDは初期化しません。

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :illumination,
  setlist_name: :tests, # :highlights、:story、:showcaseも選択可能
  pattern_key: nil,
  repeat: false,
  duration_ms: nil
)
```

単独パターンを実行する場合は、`setlist_name = nil`にして登録済みの`pattern_key`を指定してください。`:tests`は短い確認用セットリストで、`structure_guide`を実行します。パターンの説明は[イルミネーション一覧](illuminations.ja.md)、セットリストの構成は[`setlist.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/setlist.rb)を参照してください。

`repeat = true`で、セットリスト全体または単独パターンを中断されるまで繰り返します。`false`では1周で終了して消灯します。現在の`main.rb`は複合モードの設定です。イルミネーションの短い動作確認には上記の`:tests`と`repeat = false`を使用してください。`repeat`は他のモードでは使用しません。`duration_ms`はイルミネーションでは指定できません。

直接呼び出す場合は`Daisenkofun::Illumination::Player#play_setlist(:story, repeat: true)`または`Daisenkofun::Illumination::Player#play_pattern(:sunrise, repeat: true)`を使用します。`repeat:`を省略すると1周で終了します。連続再生中はLED接続を維持し、例外で抜けると消灯・解放します。再生中は通常の完了ログ`event=done status=ok`は出力されません。

## Oximeterモード

`:oximeter`は、MAX30102で心拍数とSpO2を推定するモードです。MAX30102と8個の状態LEDを制御しますが、572個のLEDイルミネーションとmusical購読コンポーネントは起動しません。

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :oximeter,
  duration_ms: nil
)
```

状態LEDへ暗い白色の点が表示されたら、MAX30102のセンサー面へ指先を軽く当ててください。`event=finger_detected`の後は指を動かさず、`event=measurement_updated`または`event=measurement_completed`の推定値を確認してください。指を離すと`event=finger_removed`が出力され、測定結果はリセットされます。

> この機能は学習・演出用であり、医療機器ではありません。推定した心拍数やSpO2を診断、治療判断、安全監視に使用しないでください。

`Daisenkofun::Oximeter::Runner`が測定のライフサイクルを管理します。正常終了と例外終了のどちらでもセンサーを停止し、状態LEDを消灯します。

## 複合モード

`:combined`は、Oximeter測定、8個の状態LED、拍動に同期する572個のLED、musical購読コンポーネントを1つのイベントループで動かす、完全な対話型演出用のモードです。

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :combined,
  duration_ms: nil,
  ws2812_pin: 14,
  i2c_sda_pin: 16,
  i2c_scl_pin: 17,
  spi_sck_pin: 2,
  spi_copi_pin: 3,
  buzzer_pin: 18, # nilで音を無効化
  musical_style: :heartbeat_signature # :pulse_translation または :kofun_canon
)
```

拍動を検出すると572個のLEDによる生体イルミネーションと、`buzzer_pin`が`nil`でなければGP18のPWMブザーが動作します。無音と`:pulse_translation`では`Illumination::Biometrics::BeatPulse`、`:kofun_canon`と`:heartbeat_signature`では音声出力と同じPlannerインスタンスを共有する`Illumination::Biometrics::MoatCanon`を使用します。正常に終了すると`DAISENKOFUN mode=combined event=done status=ok`が表示されます。

`:kofun_canon`は1拍を0%、約33%、約67%に分け、内濠・中濠・外濠を表す3音を順に鳴らします。3つの声には五音音階の0・2・4段の差を付け、前拍から拍間隔が40 ms以上短くなると順方向、40 ms以上長くなると逆方向へ巡回します。SpO₂の個人基準に対する方向は4拍ごとの境界で基本順へ反映します。脈波幅から求めたdutyには濠ごとに+0.4、0、-0.4ポイントの差を加えます。実際の濠部分にはLEDがないため、濠を挟む輪郭LEDを対応する音と同時に点灯します。

`:heartbeat_signature`は、7拍までは古墳の輪唱を続け、8拍目に直近8拍から生成した「心拍の署名」を鳴らします。各拍の間隔と前拍からの変化、最初の拍に対するSpO₂の方向、脈波幅を、それぞれ五音音階の音高、音価、2〜6%のPWM dutyへ変換します。8音は8拍目の拍間隔内に並び、輪郭LEDは内濠・中濠・外濠を順に巡ります。次の拍から輪唱へ戻り、さらに8拍を集めます。同じ8拍の入力からは同じ署名が生成され、指を離すと収集中の拍は破棄されます。

案1・案2の主音と半拍後の応答を使う場合は`musical_style = :pulse_translation`を選択します。この方式の主音は`256000 / interval_ms`をCメジャーの五音音階へ丸めた音です。実測心拍で主音を鳴らし、直近の拍間隔の半分後に応答音を鳴らします。SpO₂の最初の8更新の中央値を個人基準とし、平滑化した推定値との差で応答を音階1段下・同音・1段上から選びます。基準が未確定、値が無効、または5秒を超えて更新がないときは同音です。SpO₂が同じ拍で更新された場合は次拍の音へ反映されます。

MAX30102のIR波形は拍ごとに区切り、谷の深さの半分以下にある連続区間を脈波幅として求めます。脈波幅を拍間隔で正規化し、PWM dutyへ2〜6%の範囲で写します。波形がまだ1拍分ない場合や振幅・サンプル数が不足する場合は3%です。次の心拍は予約済みの音を取り消し、指を離すと消音して個人基準、署名用の拍、波形状態を初期化します。確認方法は[開発手順](development.ja.md#心拍メロディーを確認する)を参照してください。

イベントループは最初にOximeterのサンプルを読み、その後に購読コンポーネントを1回ずつ`tick`します。1 tickで処理するサンプル数は最大`MAX_SAMPLES_PER_TICK`件で、拍動イルミネーションは`50 ms`ごとに最大1フレームを描画します。

| 起動順 | コンポーネント | ハードウェア所有権 | 停止順 |
| --- | --- | --- | --- |
| 1 | `Musical::Subscriber` | 注入された音声出力 | 3 |
| 2 | `Illumination::BiometricPlayer` | GP14の572個のWS2812B | 2（消灯してclose） |
| 3 | `Oximeter::Runner` | MAX30102と8個の状態LED | 1（発行停止、shutdown、消灯） |

イベント発行元のMAX30102を最初に停止し、その後に購読側を逆順で停止します。例外時も同じ順序です。共通tickが`25 ms`を超えて過去最大値を更新すると`event=loop_warning`、MAX30102の未処理サンプルが1 tickの上限を超えて過去最大値を更新すると`event=fifo_backlog`が出力されます。

リファクタリング後のmrbgem名前空間を使い、イルミネーション、Oximeter、複合動作をPico 2実機で確認済みです。確認した構成では、起動、センサーイベント、LED描画、音楽キュー、正常終了時の解放が動作しています。配線、閾値、タイミング、ファームウェアを変更した場合は実機確認をやり直してください。

## ハードウェアとセットリストの設定

WS2812のデータPIN、MAX30102のI2C SDA/SCL PIN、状態LEDのSPI SCK/COPI PIN、ブザーPINは[`main.rb`](../main.rb)の`Application::Config`で変更します。572個のLEDの輝度はイルミネーションの[`config.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/config.rb)、8個の状態LEDの輝度はOximeterの[`config.rb`](../mrbgems/daisenkofun-oximeter/mrblib/daisenkofun-oximeter/config.rb)で変更します。セットリストのパターン、`wait_ms`、`loops`は[`setlist.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/setlist.rb)で変更します。mrbgem変更後は再ビルドと再書き込みが必要ですが、`main.rb`のPIN設定だけを変更した場合はアプリケーションの再実行だけで反映できます。

## 実装の参照先

| パス | 役割 |
| --- | --- |
| `main.rb` | 設定の宣言とアプリケーションの起動 |
| `mrbgems/daisenkofun-application/` | 設定検証、依存の組み立て、選択したモードの実行、検証レポート、終了処理 |
| `mrbgems/daisenkofun-runtime/` | `Daisenkofun::Runtime`のClock、ConsoleLogger、協調イベントループ |
| `mrbgems/daisenkofun-illumination/` | WS2812初期化、セットリスト、演出パターン、LED配置、生体パターン |
| `mrbgems/daisenkofun-oximeter/` | `Daisenkofun::Oximeter`のDevice、測定、イベント、状態表示、Runner |
| `mrbgems/daisenkofun-musical/` | `Daisenkofun::Musical`のSubscriber、Translator、Planner、Output |
