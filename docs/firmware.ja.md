# 04_ws2812 用カスタムファームウェア

`examples/education/04_ws2812/main.rb` は、標準のR2P2ファームウェアには
含まれていない `picoruby-ws2812-plus` gem を使用します。この例を実機で
動かすときだけ、以下のカスタムファームウェアを作成してPico 2へ書き込みます。

`Mrbgems` と `Mrbgems.lock` の書式・更新方法は
[Mrbgems と Mrbgems.lock](mrbgems.ja.md)を参照してください。

## 1. ソースを準備する

リポジトリのルートで、PicoRuby 4.0.3のソースを取得します。

```sh
rpremote setup \
  --language picoruby \
  --language-version 4.0.3 \
  --cache firmware
```

ソースは `firmware/picoruby-4.0.3/` に展開されます。公式ソースに
`picoruby-ws2812-plus` は含まれませんが、プロジェクトの `Mrbgems` に
依存関係が定義されています。

```ruby
vm :mrubyc

gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
```

`picoruby-ws2812-plus`はmruby/c向けのC拡張なので、`vm :mrubyc`も指定します。
PicoRuby 4系では公式の`femtoruby`ビルド設定、3系では`picoruby`ビルド設定へ
自動的に対応付けられます。

次のコマンドで定義と固定済みcommitを確認できます。

```sh
rpremote mrbgems check
rpremote mrbgems list
```

固定されたcommitは `Mrbgems.lock` に保存されています。最新版へ更新するときだけ
`rpremote mrbgems update` を実行します。

## 2. Pico 2用UF2をビルドする

```sh
rpremote build \
  --language picoruby \
  --language-version 4.0.3 \
  --board pico2 \
  --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

`rpremote build` は `Mrbgems` を自動検出し、PicoRuby公式設定へgemを追加した
一時ビルド設定を生成します。公式ソースを手作業で編集する必要はありません。

完成したUF2は `firmware/r2p2-picoruby-4.0.3-pico2.uf2` に保存されます。
中間ファイルは `build/` に作成されます。
`--firmware`を省略した場合も、`firmware/picoruby-4.0.3-pico2.uf2`が既定の出力先です。

## 3. Pico 2へ書き込む

Pico 2のBOOTSELボタンを押しながらUSB接続し、マウント先を指定します。

```sh
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 \
  --mount /Volumes/RP2350
```

## 4. WS2812Bを接続して実行する

- WS2812BのDINをGP14（物理19番）へ接続
- WS2812BのGNDをPico 2のGNDへ接続
- WS2812BのVDDを3V3(OUT)へ接続
- ボタンをGP15（物理20番）とGNDの間に接続

```sh
rpremote run examples/education/04_ws2812/main.rb --timeout 15
```

ボタンを押すたびに7色へ切り替わり、最後に `ws2812: OK` が表示されます。
5 V専用のWS2812Bモジュールを使う場合は、電源電圧とレベルシフタの要否を
確認してください。
