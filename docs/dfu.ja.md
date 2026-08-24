# PicoModem DFUによるアプリケーション更新

`rpremote dfu app`は、R2P2をBOOTSELモードにせず、PicoModem経由で起動用の
PicoRubyアプリケーションを更新します。

これはR2P2本体のUF2を書き換える機能ではありません。PicoRuby本体、R2P2、組み込みmrbgemを
変更したカスタムUF2は、引き続き`rpremote flash`でBOOTSEL書き込みします。

## 更新できるもの

DFUはR2P2のファイルシステムに次のいずれかをA/Bスロットとして保存します。

- `.rb`: PicoRubyソース。DFU typeは`RUBY`
- `.mrb`: mrubyバイトコード。DFU typeは`RITE`

受信データはCRC32で検証され、非アクティブ側のスロットへ保存されます。途中失敗時は
アクティブスロットを維持します。更新後のアプリが繰り返し起動に失敗すると、R2P2は
直前の確認済みスロットへ戻ります。

## 更新する

拡張子から形式を自動判定します。

```sh
rpremote dfu app examples/dfu/app.rb
rpremote dfu app app.mrb --timeout 30
```

拡張子を使わないファイルは形式を明示します。

```sh
rpremote dfu app dist/application --type rite
```

転送が終わると、新しいアプリは次回のR2P2再起動時に起動候補になります。必要に応じて
`rpremote reset`または電源再投入で再起動してください。

## 起動を確定する

新しいアプリは、正常に起動できたことを確認した後で`DFU.confirm`を呼びます。

```ruby
require "dfu"

# 初期化と自己診断
DFU.confirm

# アプリケーション本体
```

`DFU.confirm`を呼ばない場合、R2P2は起動失敗と見なし、設定されている試行回数を超えると
以前の確認済みアプリへ自動ロールバックします。無限ループへ入る前に確認するのではなく、
必要な初期化と自己診断が成功した後に呼んでください。

## 状態を確認する

`rpremote dfu status`はA/Bスロットの状態を短く表示します。

```sh
rpremote dfu status
# active_slot=a
# try_slot=a
# boot_count=0/3
# slot_a=confirmed mrb
# slot_b=confirmed mrb
```

## ロールバックを確認する

リポジトリの`examples/dfu/unconfirmed.rb`は、意図的に`DFU.confirm`を呼びません。次のように
送信して再起動し、状態を確認します。

```sh
rpremote dfu app examples/dfu/unconfirmed.rb
rpremote reset
rpremote exec 'require "dfu"; p DFU.status'
```

最後の2コマンドを繰り返します。テスト用スロットを試している間は`boot_count`が増え、試行回数を
超えると、`active_slot`が直前の`confirmed`スロットへ戻り、`boot_count`は`0`になります。
`rpremote reset`はアプリケーションのシリアル出力を中継しないため、出力を見る場合は別の端末で
`rpremote monitor`を先に起動してください。

## 失電復旧を確認する

少なくとも一方のスロットが`confirmed`であることを、先に`rpremote dfu status`で確認します。
次の例では`app.rb`を転送した後、**`rpremote reset`を実行せずに**USB給電を抜きます。
`slot_b=ready`で`try_slot=b`となった時点から、明示的に再起動するまで起動候補は保持されるため、
`staged ...`の表示直後である必要はありません。

```sh
rpremote dfu status
rpremote dfu app examples/dfu/app.rb
# "staged ..." の後、rpremote resetを実行せずにここでUSB給電を抜く
```

USB給電を再接続してR2P2が起動した後、状態を確認します。

```sh
rpremote dfu status
```

新しいアプリが`DFU.confirm`を呼べば、起動候補スロットが`confirmed`となり、`active_slot`と
`try_slot`が一致して`boot_count=0/3`になります。起動できない場合も、3回の試行後に以前の
確定済みスロットへ戻ります。転送途中やフラッシュ書き込み中の給電断は、ハードウェア操作の
タイミングを厳密に制御できないため、この公開前検証には含めません。

## `.mrb`を転送する

PicoRubyのコンパイラで生成したmrubyバイトコードも転送できます。**実機のPicoRubyと同じ
バージョンのコンパイラを使ってください。** バイトコード形式はPicoRuby 3.4系では`RITE0300`、
4系では`RITE0400`であり、互換ではありません。

```sh
# PicoRuby 3.4.5の場合（picorbc）
firmware/picoruby-3.4.5/build/host/bin/picorbc -o app.mrb app.rb

# PicoRuby 4.0.3の場合（mrbc）
firmware/picoruby-4.0.3/build/host/bin/mrbc -o app.mrb app.rb

rpremote dfu app app.mrb
rpremote reset
```

拡張子が`.mrb`なら`RITE`形式を自動選択します。このとき`rpremote`は接続済みR2P2の
`PICORUBY_VERSION`を読み取り、バイトコード先頭の`RITE0300`または`RITE0400`と照合します。
一致しない`.mrb`は転送前に拒否されます。拡張子を使わない場合だけ`--type rite`を指定します。

## `.mrb`を生成する

`rpremote dfu compile`は、選択したPicoRubyソースのホスト用コンパイラを自動選択して`.mrb`を
生成します。事前に同じバージョンのソースを`rpremote setup`し、コンパイラを含むビルドを行って
ください。

```sh
# PicoRuby 3.4.5のR2P2に合わせてRITE0300を生成する
rpremote dfu compile examples/dfu/app.rb --language-version 3.4.5 --output build/dfu/app.mrb
rpremote dfu app build/dfu/app.mrb

# PicoRuby 4.0.3の場合はRITE0400を生成する
rpremote dfu compile examples/dfu/app.rb --language-version 4.0.3
```

`--output`を省略すると、入力ファイルと同じディレクトリに`.mrb`を生成します。`--cache`で
PicoRubyソースを置いたディレクトリを指定できます。

## 制約

- 既存の`/home/app.rb`または`/home/app.mrb`はDFUスロットより優先して起動されます。
  DFUアプリを起動する前に、不要な従来アプリを削除してください。
- DFU転送はR2P2側でアプリ全体をRAMに保持してからフラッシュへ保存します。対象PicoRuby版と
  空きメモリで扱えるサイズを実機確認してください。
- 3.4.2と4.0.3の両方で、A/B更新、起動確定、ロールバックを実機確認してから公開します。
