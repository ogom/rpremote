# 開発手順

[English](development.md)

[ハードウェアと安全上の注意](hardware.ja.md)に従って配線し、リポジトリルートで作業します。

## ビルドして配置する

ルートの`Mrbgems`で5つのGoryokaku mrbgemだけをプロジェクト固有gemとして有効にします。mrbgem、`mrbgem.rake`、`Mrbgems`を変更した場合は、lockを更新してファームウェアを再ビルドします。

```sh
rpremote mrbgems lock
rpremote deploy --build examples/picoruby/projects/goryokaku --timeout 120
```

`main.rb`のmode、PIN、音量だけを変更した場合は、組み込み済みファームウェアへ一時実行できます。

```sh
rpremote run examples/picoruby/projects/goryokaku --timeout 120
```

## 単独パターンを確認する

```sh
rpremote exec 'require "goryokaku-illumination"; Goryokaku::Illumination::Player.new.play_pattern(:warm_white)' --timeout 120
```

正常終了では`event=done status=ok`、異常終了ではcleanup後に`status=error`が表示されます。

## ホスト仕様を実行する

RSpecは設定、イベント順、モード選択、タンバリン変換、LED配置、mrbgemロード、文書リンクを検証します。

```sh
rake spec:goryokaku
```

mrbgem内のPicotestはPicoRuby／mruby/c互換の代表ケースです。RSpecと実機確認の代替ではありません。

## 実機確認

- `:illumination`：指定した演出と曲、繰り返し、終了時の消音・消灯
- `:musical`：Y-UPの安定、弱い振り、短い打撃、静止時の誤発音、音と光の同期
- `:combined`：Y-UPでの赤／青選択、Z-UPでの決定、姿勢表示への復帰
- ハードウェア：最大輝度時の電流・温度、I2C、PWM音量、MPU6050の取り付け方向

ホストテストでは、物理的な色、電源容量、音量、センサー感度、実時間の同期を検証できません。

## ログを保存する

```sh
mkdir -p tmp/goryokaku-run
rpremote run examples/picoruby/projects/goryokaku --timeout 120 2>&1 \
  | tee tmp/goryokaku-run/output.log
```

異常時は`event=error`と、LED、音、姿勢に異常が見えた時刻を対応付けます。
