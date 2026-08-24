# 04_ws2812 用カスタムファームウェア

`examples/picoruby/education/04_ws2812/main.rb`は、標準のR2P2ファームウェアには含まれていない`picoruby-ws2812-plus` gemを使用します。この例を実機で動かすときだけ、以下のカスタムファームウェアを作成してPico 2へ書き込みます。

`Mrbgems`と`Mrbgems.lock`の書式・更新方法は[MrbgemsとMrbgems.lock](mrbgems.ja.md)を参照してください。

## 1. ソースを準備する

リポジトリのルートで、PicoRuby 4.0.3のソースを取得します。

```sh
rpremote setup --language picoruby --language-version 4.0.3 --cache firmware
```

ソースは`firmware/picoruby-4.0.3/`に展開されます。公式ソースに`picoruby-ws2812-plus`は含まれませんが、プロジェクトの`Mrbgems`に依存関係が定義されています。

### PicoRubySourcePatch

`PicoRubySourcePatch`はrpremoteに同梱され、展開済みPicoRubyソースへ必要なR2P2 Shellパッチを適用します。
Rubyプログラムの例外時にR2P2が専用ステータスを出力するため、例外文の文字列判定をせずに`rpremote run`と`rpremote exec`を非0で終了できます。

`rpremote setup`はソース準備後に、`rpremote build`はビルド前にパッチを適用します。
すでに適用済みなら変更しないため、gemを更新した後に既存キャッシュをビルドしても現在のパッチが適用されます。

同梱パッチの対象はPicoRuby 4.0.3と3.4.5です。PicoRuby 3.4.2には互換性のある3.4.5用パッチを使います。
これはソースパッチの対象を示すものであり、すべてのR2P2版がすべてのボードで正常に起動することを保証するものではありません。

パッチ適用に失敗した場合、キャッシュ済みソースが想定したPicoRubyリリースと異なります。
`rpremote setup --force --language-version VERSION`でその版のキャッシュを作り直してから、再度ビルドしてください。

```ruby
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
```

`picoruby-ws2812-plus`はmruby/c向けのC拡張なので、`vm :mrubyc`も指定します。PicoRuby 4系では公式の`femtoruby`ビルド設定、3系では`picoruby`ビルド設定へ自動的に対応付けられます。

次のコマンドで定義と固定済みコミットを確認できます。

```sh
rpremote mrbgems check
rpremote mrbgems list
```

固定されたコミットは`Mrbgems.lock`に保存されています。最新版へ更新するときだけ`rpremote mrbgems update`を実行します。

## 2. Pico 2用UF2をビルドする

```sh
rpremote build --language picoruby --language-version 4.0.3 --board pico2 --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

`rpremote build`は`Mrbgems`を自動検出し、PicoRuby公式設定へgemを追加した一時ビルド設定を生成します。
公式ソースを手作業で編集する必要はありません。R2P2例外ステータス用の`PicoRubySourcePatch`だけはrpremoteが管理して適用します。

完成したUF2は`firmware/r2p2-picoruby-4.0.3-pico2.uf2`に保存されます。中間ファイルは`build/`に作成されます。`--firmware`を省略した場合も、`firmware/picoruby-4.0.3-pico2.uf2`が既定の出力先です。

## 3. Pico 2へ書き込む

Pico 2のBOOTSELボタンを押しながらUSB接続し、マウント先を指定します。

```sh
rpremote flash --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2 --mount /Volumes/RP2350
```

## 4. WS2812Bを接続して実行する

- WS2812BのDINをGP14（物理19番）へ接続
- WS2812BのGNDをPico 2のGNDへ接続
- WS2812BのVDDを3V3(OUT)へ接続
- ボタンをGP15（物理20番）とGNDの間に接続

```sh
rpremote run examples/picoruby/education/04_ws2812/main.rb --timeout 15
```

ボタンを押すたびに7色へ切り替わり、最後に`ws2812: OK`が表示されます。5 V専用のWS2812Bモジュールを使う場合は、電源電圧とレベルシフタの要否を確認してください。
