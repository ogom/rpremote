# 開発手順

[English](development.md)

リポジトリルートで作業します。配線前に[ハードウェアと安全上の注意](hardware.ja.md)を確認してください。

## 単独パターンとモードの確認

組み込み済みの単独パターンは再ビルドせず確認できます。

```sh
rpremote exec 'require "goryokaku-illumination"; Goryokaku::Illumination::Player.new.play_pattern(:warm_white)' --timeout 120
```

設定、DFU確認、構成、終了処理を含むアプリケーション全体は次で確認します。

```sh
rpremote run examples/picoruby/projects/goryokaku/main.rb --timeout 120
```

正常終了時は`event=done status=ok`、異常終了時はcleanup後に`status=error`を出力して例外を再送出します。

## mrbgem変更後

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

`main.rb`だけを変更した場合は`rpremote run`だけで反映できます。起動アプリを更新する場合は`rpremote dfu app examples/picoruby/projects/goryokaku/main.rb`を実行します。

## リリース確認

- 21パターンのフレーム数、チェックサム、範囲外アクセスがホストテストと一致する。
- `:tests`、`:highlights`、`:story`、`:showcase`が完走し、終了時に消灯する。
- `:illumination`ではLED演出と「きらきら星」が同時に始まり、通常は曲を1回完奏し、終了時と例外時にPWM dutyが0になる。
- 起動時は未選択で、最初のY-UPタッチがイルミネーション候補になる。
- Y-UPでタッチするたびに候補が切り替わり、半月堡がイルミネーション候補では赤、タンバリン候補では青になる。
- Z-UPへ動かしても選択色が保持され、Z-UPでタッチした時だけ候補が確定する。
- Y-UP／Z-UP以外の姿勢ではタッチが無視される。
- タンバリン確定後は選択表示が消灯し、Y-UPでZ軸方向へ滑らかに振ると組5から多色の残光を走査、Z軸へ鋭い衝撃を与えると星形中心から半月堡・外周へ広がる花火状の光をシャンシャン音と同期する。
- イルミネーション中は現在姿勢を表示し、確定後は`setlist_name`を先頭から1回実行して姿勢表示へ戻り、動きでは発音しない。
- `:musical`ではタッチ選択を使わず、Y-UP安定後に振る／叩く奏法の音とLEDが連動する。
- 例外と`Ctrl-C`でLEDが消灯し、PWM dutyが0になる。
- LEDは大容量の外部5 V電源を使い、Pico 2とGNDを共通化する。
- 最大輝度と電流を実機で確認する。
