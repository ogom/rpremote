# 開発手順

[English](development.md)

まず[ハードウェアと安全上の注意](hardware.ja.md)に従って、Raspberry Pi Pico 2（以降、Pico 2）の配線とLED用外部電源を準備してください。リポジトリルートで、ビルド、書き込み、サンプルの実行をまとめて行います。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

このコマンドは、ローカルの大仙古墳mrbgemを含むファームウェアをビルドしてPico 2へ書き込み、R2P2シェルへ再接続して`main.rb`を実行します。書き込みによってPico 2上のファームウェアは置き換えられます。シリアル経由でBOOTSELへ移行できない初回の書き込みでは、Pico 2のBOOTSELボタンを押して接続してください。

既定の`main.rb`は`:illumination`モードの`:tests`セットリストを実行します。選択したパターンが完了し、`DAISENKOFUN mode=illumination event=done status=ok`が表示されれば成功です。Pico 2へファームウェアを書き込んだ後は、変更したファイルに応じて手順を選びます。

| 変更したファイル | 実行すること |
| --- | --- |
| `main.rb`のみ | アプリケーションスクリプトを再実行 |
| `mrbgems/`、`Mrbgems`、ハードウェアドライバー | 依存関係を確認し、再ビルド、書き込み後にアプリケーションスクリプトを実行 |

## 最軽量の実機確認: `rpremote exec`

`rpremote exec`は、Rubyの式をR2P2シェルへ直接送信します。書き込み済みファームウェアに含まれる機能を確認する最も軽量な方法であり、`main.rb`の転送やファームウェアの再ビルドは必要ありません。

例えば、リポジトリルートから`structure_guide`だけを実行します。

```sh
rpremote exec 'require "daisenkofun-illuminations"; Daisenkofun::Illumination.new.play_pattern(:structure_guide)' --timeout 120
```

イルミネーションmrbgemは自動requireしないため、式の中で明示的に読み込みます。組み込み済みコンポーネントや単独パターンの確認には`rpremote exec`を使用し、`main.rb`の設定、動作モード、アプリケーション全体のライフサイクルを確認する場合は`rpremote run`を使用します。

選択したパターンが実行され、LEDを消灯してR2P2シェルへ戻ります。`DAISENKOFUN mode=illumination event=led_off`が表示されれば、イルミネーションの終了処理まで完了しています。

## `main.rb`を編集して実行する

動作モード、セットリスト、パターン、測定時間を変更する場合は、この手順を繰り返します。

```sh
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

`rpremote run`は`main.rb`の実行用コピーだけを`/home/.rpremote-run.rb`として転送します。`fs push`や`lib/daisenkofun`の同期は不要です。設定できる項目は[動作モードと設定](modes.ja.md)を参照してください。

成功すると`DAISENKOFUN mode=<選択したモード> event=done status=ok`が出力されます。`status=error`が出力された場合は、同じ行にあるエラークラスとメッセージを確認し、設定またはハードウェアの問題を修正してから再実行してください。

`--timeout 120`はアプリケーション全体の実行時間ではなく、R2P2シェルから出力を受け取れない最大時間です。Oximeterの標準測定時間は60秒であり、測定ログが継続して出力される間はタイムアウトがリセットされます。

## ファームウェアを再ビルドする

mrbgem、`Mrbgems`、ハードウェアドライバーを変更した場合は、リポジトリルートで次を実行します。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

書き込みによってPico 2上のファームウェアは置き換えられます。書き込み後は、上記の編集・実行コマンドを使用します。

## シリアルログを保存する

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined-10min.log
```

実行ごとにファイル名を変えます。長時間試験では、`event=fifo_backlog`、`event=loop_warning`、`event=error`、`event=done`とLED乱れを観測した時刻を対応付けて記録します。
