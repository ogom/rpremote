# 開発手順

[English](development.md)

まず[ハードウェアと安全上の注意](hardware.ja.md)に従って、Raspberry Pi Pico 2（以降、Pico 2）の配線とLED用外部電源を準備してください。リポジトリルートで、ビルド、書き込み、サンプルの実行をまとめて行います。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

このコマンドは、ローカルの大仙古墳mrbgemを含むファームウェアをビルドしてPico 2へ書き込み、R2P2シェルへ再接続して`main.rb`を実行します。書き込みによってPico 2上のファームウェアは置き換えられます。シリアル経由でBOOTSELへ移行できない初回の書き込みでは、Pico 2のBOOTSELボタンを押して接続してください。

現在の`main.rb`は`:combined`モードで60秒間測定し、`:heartbeat_signature`を実行します。イルミネーションだけを短く確認する場合は、`Application::Config`を`mode: :illumination`、`setlist_name: :tests`、`repeat: false`、`duration_ms: nil`へ変更してください。Pico 2へファームウェアを書き込んだ後は、変更したファイルに応じて手順を選びます。

| 変更したファイル | 実行すること |
| --- | --- |
| `main.rb`のみ | アプリケーションスクリプトを再実行 |
| `daisenkofun-application`を含む`mrbgems/`、`Mrbgems`、ハードウェアドライバー | 依存関係を確認し、再ビルド、書き込み後にアプリケーションスクリプトを実行 |

## 最軽量の実機確認: `rpremote exec`

`rpremote exec`は、Rubyの式をR2P2シェルへ直接送信します。書き込み済みファームウェアに含まれる機能を確認する最も軽量な方法であり、`main.rb`の転送やファームウェアの再ビルドは必要ありません。

例えば、リポジトリルートから`structure_guide`だけを実行します。

```sh
rpremote exec 'require "daisenkofun-illumination"; Daisenkofun::Illumination::Player.new.play_pattern(:structure_guide)' --timeout 120
```

イルミネーションmrbgemは自動requireしないため、式の中で明示的に読み込みます。組み込み済みコンポーネントや単独パターンの確認には`rpremote exec`を使用し、`main.rb`の設定、動作モード、アプリケーション全体のライフサイクルを確認する場合は`rpremote run`を使用します。

選択したパターンが実行され、LEDを消灯してR2P2シェルへ戻ります。`DAISENKOFUN mode=illumination event=led_off`が表示されれば、イルミネーションの終了処理まで完了しています。

## `main.rb`を編集して実行する

動作モード、セットリスト、パターン、測定時間を変更する場合は、この手順を繰り返します。

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

`rpremote run`は`main.rb`の実行用コピーだけを`/home/.rpremote-run.rb`として転送します。`fs push`や`lib/daisenkofun`の同期は不要です。設定できる項目は[動作モードと設定](modes.ja.md)を参照してください。

1回再生が正常に完了すると`DAISENKOFUN mode=<選択したモード> event=done status=ok`が出力されます。`status=error`が出力された場合は、同じ行にあるエラークラスとメッセージを確認し、設定またはハードウェアの問題を修正してから再実行してください。

CoCリファクタリング後のruntime、Oximeter、musical、illuminationの各mrbgemは、この手順によるPico 2実機確認が完了しています。この結果をリリース基準とし、mrbgem、ドライバ、配線、閾値、タイミングを変更した場合は該当modeを再確認してください。

`--timeout 120`はアプリケーション全体の実行時間ではなく、R2P2シェルから出力を受け取れない最大時間です。Oximeterの標準測定時間は60秒であり、測定ログが継続して出力される間はタイムアウトがリセットされます。

## 連続再生をDFUアプリへ反映する

連続再生APIは組み込みmrbgemの変更を含むため、初回は下記の手順でファームウェアを再ビルド・書き込みしてください。その後、`main.rb`の`repeat = true`を確認して起動アプリを更新します。

```sh
rpremote dfu app examples/picoruby/projects/daisenkofun/main.rb
rpremote reset
```

以降、`repeat`やセットリストなど`main.rb`の設定だけを変更する場合は、このDFU更新と再起動だけで反映できます。連続再生中は完了ログを待たず、`event=pattern`の`index`が最後から`1`へ戻って次の周回に進むことを確認してください。

## ファームウェアを再ビルドする

mrbgem、`Mrbgems`、ハードウェアドライバーを変更した場合は、リポジトリルートで次を実行します。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

書き込みによってPico 2上のファームウェアは置き換えられます。書き込み後は、上記の編集・実行コマンドを使用します。

## 最小限のホスト回帰テスト

Picotestは、目視だけでは毎回同じ条件で確認しにくい動作に絞って残しています。ハードウェアとの連携とアプリケーション全体の動作はPico 2実機で確認します。

| コンポーネント | 残す検証範囲 |
| --- | --- |
| Application | [`config_test.rb`](../mrbgems/daisenkofun-application/test/config_test.rb): モードの既定値と公開設定の検証 |
| Runtime | [`event_loop_test.rb`](../mrbgems/daisenkofun-runtime/test/event_loop_test.rb): 起動、tick、逆順停止、失敗時の終了処理 |
| Oximeter | [`measurement_processor_test.rb`](../mrbgems/daisenkofun-oximeter/test/measurement_processor_test.rb): 指、拍、測定、脈波形、リセットのイベント |
| Musical | [`heartbeat_signature_planner_test.rb`](../mrbgems/daisenkofun-musical/test/heartbeat_signature_planner_test.rb)と[`kofun_canon_output_test.rb`](../mrbgems/daisenkofun-musical/test/kofun_canon_output_test.rb): 再現可能な署名と予約されたPWM輪唱 |
| Illumination | [`patterns_test.rb`](../mrbgems/daisenkofun-illumination/test/patterns_test.rb)、[`biometric_player_test.rb`](../mrbgems/daisenkofun-illumination/test/biometric_player_test.rb)、[`moat_canon_test.rb`](../mrbgems/daisenkofun-illumination/test/moat_canon_test.rb): 全32演出パターンの保存出力と生体描画 |

`patterns_test.rb`は生成フレームを[`pattern_baselines.rb`](../mrbgems/daisenkofun-illumination/test/pattern_baselines.rb)と比較し、内部をリファクタリングしても全演出パターンの見た目を維持します。

## 心拍メロディーを確認する

残したmusicalテストで、固定入力による音列、PWM duty、輪唱スケジュールを確認します。実機ではGP18へ教材03_speakerと同じPWMブザーを接続し、MAX30102と572個のLEDを接続した状態で`main.rb`を通常の実行入口として使います。

リファクタリング後の`Musical::Subscriber`、Planner、Output、Oximeterのデバイスライフサイクル、同期イルミネーションは、実機上で組み合わせた動作を確認済みです。新しいリリース候補では再度この確認を行い、`event=verification`の結果を保持してください。

`main.rb`の`Daisenkofun::Application::Config`を次のように設定します。古墳の輪唱だけを確認する場合は`musical_style: :kofun_canon`、8拍ごとの心拍の署名を確認する場合は`:heartbeat_signature`を選択します。

```ruby
config = Daisenkofun::Application::Config.new(
  mode: :combined,
  duration_ms: 60_000,
  buzzer_pin: 18,
  musical_style: :heartbeat_signature
)
```

mrbgemをビルドして書き込んだ後、次を実行します。

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 90
```

指を置いて60秒の計測を完走させます。`source=canon`は通常輪唱、`source=heartbeat_signature`は8拍から生成した署名音です。音と濠境界LEDが同期すること、署名が8音鳴った後に通常輪唱へ戻ること、指を離すと直ちに消音し、置き直すと新しい8拍の収集が始まることを確認してください。

終了時の`event=verification status=ok`は15音以上かつ最大開始遅延25 ms以内を示します。`cues`、`max_delay_ms`、`:heartbeat_signature`では`signatures`も出力します。ログの`pulse_width_ratio`は正規化した脈波幅、`pulse_width_ms`は近似幅、`pulse_amplitude`はIR振幅、`duty_percent`はPWM設定値です。

音階値はPWMへの要求周波数です。Pico 2での125 MHz固定計算の問題は今回のメロディー実装では変更していないため、実周波数の精度は別途検証します。

## シリアルログを保存する

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined-10min.log
```

実行ごとにファイル名を変えます。長時間試験では、`event=fifo_backlog`、`event=loop_warning`、`event=error`、`event=done`とLED乱れを観測した時刻を対応付けて記録します。
