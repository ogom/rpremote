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

## 一時実行と再起動後の自動実行

`rpremote run`と`deploy`による`main.rb`の実行は一時的です。動作確認にはこの方法を使い、Pico 2を再起動した後も五稜郭アプリを自動実行したい場合だけDFU起動アプリへ登録します。

```sh
rpremote dfu app examples/picoruby/projects/goryokaku/main.rb
rpremote dfu status
rpremote reset
```

起動に成功するとアプリケーションが`DFU.confirm`を呼び、候補スロットが確定します。DFUへ登録する前に、必要な5つのmrbgemを含むファームウェアが書き込まれていることを確認してください。mrbgemを変更した場合は、DFUアプリの更新だけでなくファームウェアの再ビルドと書き込みも必要です。

起動アプリを削除する場合は次を実行します。`dfu remove`はA/B両スロットを削除し、元に戻せません。

```sh
rpremote dfu remove
rpremote reset
```

## 単独パターンを確認する

```sh
rpremote exec 'require "goryokaku-illumination"; Goryokaku::Illumination::Player.new.play_pattern(:warm_white)' --timeout 120
```

正常終了では`event=done status=ok`、異常終了ではcleanup後に`status=error`が表示されます。

## ホスト仕様を実行する

RSpecは設定、イベント順、モード選択、タンバリン変換、LED配置、mrbgemロード、文書リンクを検証します。

```sh
rake spec:examples:picoruby:goryokaku
```

mrbgem内のPicotestはPicoRuby／mruby/c互換の代表ケースです。RSpecと実機確認の代替ではありません。

## 実機確認

- `:illumination`：指定した演出と曲、繰り返し、終了時の消音・消灯
- `:musical`：Y-UPの安定、弱い振り、短い打撃、静止時の誤発音、音と光の同期
- `:combined`：Y-UPでの赤／青選択、Z-UPでの決定、姿勢表示への復帰
- ハードウェア：最大輝度時の電流・温度、I2C、PWM音量、MPU6050の取り付け方向

ホストテストでは、物理的な色、電源容量、音量、センサー感度、実時間の同期を検証できません。

## ログの読み方

| ログ | 意味と確認すること |
| ---- | ------------------ |
| `mode=... event=start` | 指定したmodeで起動した |
| `event=pattern index=... key=...` | setlist内で開始した演出と進行位置 |
| `event=led_off` | 終了処理で全LEDを消灯した |
| `event=orientation mode=y_up|z_up|x_up|unknown` | MPU6050から認識した現在姿勢 |
| `event=touch action=select mode=...` | Y-UPのタッチで選択候補を切り替えた |
| `event=touch action=confirm mode=...` | Z-UPのタッチで表示中の候補を決定した |
| `event=touch action=ignored ...` | 候補未選択、または対象外の姿勢だったためタッチを無視した |
| `event=alive` | 複合モードのイベントループが動作している |
| `event=done status=ok` | 正常に終了した |
| `event=done status=error` | cleanup後に失敗した。直前の例外を確認する |

`status=ok`だけで物理的な色、音量、動作感度、同期までは確認できません。ログと模型上の動作を対応付けてください。

## ログを保存する

```sh
mkdir -p tmp/goryokaku-run
rpremote run examples/picoruby/projects/goryokaku --timeout 120 2>&1 \
  | tee tmp/goryokaku-run/output.log
```

異常時は`event=error`と、LED、音、姿勢に異常が見えた時刻を対応付けます。
