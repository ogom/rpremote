# 07 PicoModem DFU

[English](README.md)

教室などに設置したPico 2のアプリケーションを、BOOTSELボタンを押さずに更新する例です。オンボードLEDで動く「教室ビーコン」を安定版v1からv2へ更新します。起動に失敗する版から、直前の安定版へ自動で戻るところまで確認します。

PicoModem DFUが更新するのはPicoRubyアプリケーションです。PicoRuby本体、R2P2、組み込みmrbgemを変更する場合は、`rpremote build`と`rpremote flash`でUF2を書き換えてください。

## 前提

- PicoModem DFUを含むR2P2ファームウェアがPico 2へ書き込み済みであること
- Pico 2を1台だけUSB接続していること
- `rpremote ports`でR2P2のCDC 0ポートを検出できること

従来の`/home/app.rb`または`/home/app.mrb`があると、DFUスロットより先に起動します。最初に`/home`を確認し、必要なら従来アプリを削除してください。

```sh
rpremote fs ls :/home
rpremote fs rm :/home/app.rb
rpremote fs rm :/home/app.mrb
```

存在するファイルだけを削除します。配線は不要です。

## DFUサンプル

`app_v1.rb`は、GPIOの初期化に成功した後で`DFU.confirm`を呼ぶ安定版アプリです。`app_broken.rb`は、自己診断失敗を再現して`DFU.confirm`を呼ばずにロールバックを確認するアプリです。DFUの基本的な動作は[DFUドキュメント](../../../../docs/dfu.ja.md)を参照してください。

## 1. 安定版v1を配備する

まずアプリを非アクティブ側のDFUスロットへ転送します。この操作だけではアプリは起動しません。

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v1.rb
```

次に`rpremote reset`でR2P2を再起動します。v1が起動すると、オンボードLEDがゆっくり3回点滅します。

```sh
rpremote reset
rpremote dfu status
```

GPIOの初期化に成功した後、アプリは`DFU.confirm`を呼びます。`rpremote dfu status`に`confirmed rb`と`boot_count=0/3`が表示されれば、v1の起動確認は成功です。

## 2. v2へ更新する

v2は短い2回点滅を3セット繰り返します。BOOTSELボタンを押したり、UF2を書き直したりせずに、アプリだけを更新します。

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_v2.rb
```

次に`rpremote reset`でR2P2を再起動し、更新後のアプリを起動します。

```sh
rpremote reset
rpremote dfu status
```

LEDが2回ずつ点滅し、`rpremote dfu status`に`confirmed rb`と`boot_count=0/3`が表示されれば更新成功です。v1は、もう一方のA/Bスロットに直前の確認済みアプリとして残ります。

## 3. 起動失敗から自動で戻す

`app_broken.rb`は、必要な機器の自己診断に失敗した状況を再現します。出力を安全な状態にして、`DFU.confirm`を呼ばずに終了します。そのため、起動候補にはなっても安定版として確定されず、診断に使うR2P2シェルは引き続き利用できます。

```sh
rpremote dfu app examples/picoruby/education/07_dfu/app_broken.rb
```

次に`rpremote reset`でR2P2を再起動し、状態を確認します。

```sh
rpremote reset
rpremote dfu status
```

`boot_count`が増えている間は、`rpremote reset`と`rpremote dfu status`を繰り返します。設定された試行回数を使い切ると、次の起動で`active_slot`と`try_slot`が直前のv2のスロットへ戻ります。LEDが再びv2の2回点滅になり、`boot_count=0/3`と表示されればロールバック成功です。

実際の不具合でアプリが停止し、R2P2シェルへ接続できない場合は、USBを抜き差しして起動を繰り返します。ロールバック判定はアプリを読み込む前に行われます。設定された試行回数を使い切った次の起動で、確認済みスロットへ戻ります。

## 実用時のポイント

- `DFU.confirm`は、GPIO、センサー、設定ファイルなど、起動に必須の初期化と自己診断が成功した後に呼びます。
- アプリ全体の処理より前に呼ぶのではなく、安全に運転できる状態を確認してから確定します。
- DFU転送中に失敗しても、現在の確認済みスロットは維持されます。
- `.mrb`を配布する場合は、実機と同じPicoRuby版でコンパイルします。詳しくは[PicoModem DFUのドキュメント](../../../../docs/dfu.ja.md)を参照してください。
