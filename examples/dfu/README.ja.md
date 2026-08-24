# PicoModem DFU アプリケーション

言語: PicoRuby<br>
ボード: PicoModem DFUを含むR2P2を実行するRaspberry Pi Pico boards<br>
カスタムmrbgem: 不要

[English](README.md)

この最小アプリケーションは、DFUによる起動成功を確定します。コマンドはリポジトリの
ルートで実行します。

```sh
rpremote dfu app examples/dfu/app.rb
rpremote reset
```

次の起動でアプリケーションが実行され、そのスロットが確定します。出力を見るには、
resetする前に`rpremote monitor`を開いてください。`rpremote reset`自体はシリアル出力を
中継しません。

`DFU.confirm`は意図的に初期化の後に置いています。この方式をプロジェクトで使う場合は、
実際のアプリケーションの起動確認の後へ移動してください。

`.mrb`へコンパイルする場合は、インストール済みR2P2 firmwareと同じPicoRuby版の
コンパイラを使います。PicoRuby 3.4.xは`picorbc`で`RITE0300`を、PicoRuby 4.xは`mrbc`で
`RITE0400`を出力します。形式に互換性はありません。

## ロールバック試験

`unconfirmed.rb`は意図的に`DFU.confirm`を呼びません。自動ロールバックを確認するために
安全に使えます。設定された起動回数の後、R2P2は直前に確定したアプリケーションへ戻ります。

```sh
rpremote dfu app examples/dfu/unconfirmed.rb
rpremote reset
rpremote exec 'require "dfu"; p DFU.status'
```

最後の2コマンドを、`active_slot`が以前のconfirmedスロットに戻るまで繰り返します。試験
スロットの再試行中は`boot_count`が増え、ロールバック後は`0`へ戻ります。
