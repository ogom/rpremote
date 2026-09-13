# 五稜郭イルミネーションとタンバリン

[English](README.md)

Raspberry Pi Pico 2で、五稜郭模型に配置した380個のWS2812Bとタンバリンを制御するPicoRubyプロジェクトです。`:illumination`、`:musical`、`:combined`の3モードを選択できます。

## 準備

[ハードウェアと安全上の注意](docs/hardware.ja.md)を確認してから配線してください。380個のLEDには大容量の外部5 V電源が必要です。Pico 2からLEDへ給電しないでください。

## ビルドと実行

リポジトリルートで、依存関係のlock、ファームウェアのビルド、書き込み、実行を行います。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote bootsel
rpremote flash
rpremote run examples/picoruby/projects/goryokaku/main.rb --timeout 120
```

現在の`main.rb`は`:musical`で停止するまでタンバリン入力ループを継続します。`:illumination`は指定した演出を実行して終了し、`:combined`はタッチ操作でイルミネーションとタンバリンを選択します。終了するには`Ctrl-C`を押してください。終了処理でブザーを停止し、全LEDを消灯します。ビルドから実行までを一括して行う場合は、次のコマンドも使用できます。

```sh
rpremote deploy --build examples/picoruby/projects/goryokaku --timeout 120
```

`mrbgems/`またはルートの`Mrbgems`を変更した後は、再度lock、ビルド、書き込みが必要です。`main.rb`のPIN値だけを変更した場合は、`rpremote run`の再実行だけで反映できます。

## 動作モード

設定方法、セットリスト、単独パターンの一覧は[動作モードと設定](docs/modes.ja.md)を参照してください。

### イルミネーション

`main.rb`の設定は次のとおりです。

```ruby
mode: :illumination,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

`:tests`、`:highlights`、`:story`、`:showcase`のセットリスト、または登録済みの単独パターンを実行できます。`:story`は、城郭の出現から星空、桜、花火までを15演出で構成します。LED演出と同時にPWMブザーで「きらきら星」を1回再生します。`repeat: true`では曲も繰り返し、`buzzer_volume: 0`で無効化できます。このモードではMPU6050とタッチスイッチを初期化しません。

### ミュージカル

`mode: :musical`ではタッチ選択を使用しません。Y-UPで組5を上にして保持すると、Z軸を滑らかに往復する振る奏法とZ軸へ鋭い衝撃を与える叩く奏法のどちらも「シャンシャン」という金属的な音色で演奏できます。LEDは振る奏法で多色の残光を走査し、叩く奏法では`fireworks`をもとに星形中心から10方向へ広がり、半月堡と外周を発光させます。

### コンバインド

`main.rb`で`mode: :combined`、実行したい`setlist_name`、`pattern_key: nil`を指定します。

| 操作／状態 | 動作 |
| --- | --- |
| 起動時 | モード未選択。最初のY-UPタッチでイルミネーションを選択 |
| IMUをY-UPにしてタッチ | 選択候補を切り替える。イルミネーションは半月堡が赤、タンバリンは青 |
| IMUをZ-UPにしてタッチ | 表示中の候補を決定 |
| イルミネーションモード | 現在姿勢に応じて表示し、決定時は「きらきら星」と`setlist_name`を1回実行後に姿勢表示へ戻る |
| タンバリンモードでY-UPにして振る／叩く | シャンシャン音と星形・半月堡・外周の演奏イルミネーションを同期再生 |

起動時に`GORYOKAKU mode=combined event=start`、姿勢変化時に`event=orientation`が表示されます。選択時は`event=touch action=select mode=...`、決定時は`event=touch action=confirm mode=...`が表示されます。待機中は約5秒ごとの`event=alive`で動作を確認できます。

## LED配置と演出

[LED配置](docs/led_layout.ja.md)は、五芒星0–169、半月堡170–189、外周190–379のアドレスを定義します。移管したillumination gemには、温白色・桜色、各ゾーンのフェード／トレイル／虹色、複合ゾーン演出、花火演出が含まれます。

## ファイル構成

| パス | 役割 |
| --- | --- |
| `main.rb` | PIN設定とアプリケーション起動 |
| `mrbgems/goryokaku-application/` | 設定、検証、構成ルート |
| `mrbgems/goryokaku-runtime/` | 時計、ログ、協調イベントループ |
| `mrbgems/goryokaku-interaction/` | タッチとMPU6050のイベント検出 |
| `mrbgems/goryokaku-illumination/` | 380個のLED配置と演出 |
| `mrbgems/goryokaku-musical/` | 非ブロッキングPWMブザー出力 |
| `docs/hardware.ja.md` | 配線、電源、安全上の注意 |
| `docs/modes.ja.md` | モード、セットリスト、単独パターン |
| `docs/development.ja.md` | 開発と検証の手順 |

ホストテストはRuby上のモックを使い、ゾーン境界、ブザー出力、アプリケーション連携、終了処理を確認します。物理的な色、タイミング、電源、MPU6050の取り付け方向は実機で確認してください。
