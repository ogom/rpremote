# 開発手順

[English](development.md)

最初に[ハードウェアと安全上の注意](hardware.ja.md)に従って、Pico 2、LED用電源、MAX30102、PWMアンプを接続します。

## ビルドして配置する

mrbgem、`Mrbgems`、ドライバーを変更した場合は、ファームウェアのビルドを含めて配置します。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun --build
```

このプロジェクトは多数のRubyファイルを実機上で順次コンパイルせず、5つのローカルmrbgemとしてファームウェアへ組み込みます。この判断の背景とトレードオフは[mrbgemを使う理由](mrbgem_migration.ja.md)を参照してください。

## 設定を変更して実行する

ファームウェアを変更せず、[`main.rb`](../main.rb)のmode、実行時間、PIN、音量などだけを変更した場合は次を実行します。

```sh
rpremote run examples/picoruby/projects/daisenkofun --timeout 120
```

設定項目は[動作モードと設定](modes.ja.md)を参照してください。正常終了では`event=done status=ok`が表示されます。

## コンポーネントを短く確認する

組み込み済みの単独パターンなどは`rpremote exec`で確認できます。

```sh
rpremote exec 'require "daisenkofun-illumination"; Daisenkofun::Illumination::Player.new.play_pattern(:structure_guide)' --timeout 120
```

## ホスト仕様を実行する

RSpecは、設定、イベント順、音楽変換、LED配置、mrbgemロード、文書リンクなどの内部契約を検証します。

```sh
cd packages/rpremote
bundle exec rake spec:daisenkofun
```

mrbgem内のPicotestは、PicoRuby／mruby/c互換性を確認する代表ケースです。RSpecと実機確認の代替ではありません。

## 実機確認

変更した機能に応じて、次を確認します。

- `:illumination`: 指定したパターン、消灯、繰り返し
- `:oximeter`: 指の検出・取り外し、測定値、状態LED
- `:combined`: 音と濠LEDの同期、消音、正常終了
- 電源・配線変更: ハンクアップ、発熱、LED乱れ、I2Cエラーがないこと

ホストテストでは電源、PWM音量、LEDの実時間表示、センサー品質を検証できません。

## ログを保存する

```sh
mkdir -p tmp/daisenkofun-longrun
rpremote run examples/picoruby/projects/daisenkofun --timeout 120 2>&1 \
  | tee tmp/daisenkofun-longrun/combined.log
```

異常時は`event=error`、`event=loop_warning`、`event=fifo_backlog`と、LEDや音に異常が見えた時刻を対応付けます。
