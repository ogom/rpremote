# PicoRubyサンプル用カスタムファームウェア

`examples/picoruby/education/04_ws2812/main.rb`は`picoruby-ws2812-plus`、`06_mpu6050/main.rb`はそのgemとローカルの`picoruby-mpu6050`を使用します。これらのC拡張は標準のR2P2ファームウェアに含まれていません。どちらかのサンプルをPico 2で実行するときは、以下のカスタムファームウェアを作成して書き込みます。

`Mrbgems`と`Mrbgems.lock`の書式・更新方法は[MrbgemsとMrbgems.lock](mrbgems.ja.md)を参照してください。

## 1. ソースを準備する

リポジトリのルートで、最新のPicoRubyソースを取得します。

```sh
rpremote setup
```

`master`ブランチのソースは`firmware/picoruby-latest/`に展開されます。公式ソースにこれらのサンプルgemは含まれませんが、プロジェクトの`Mrbgems`に公開gemとローカルgemの依存関係が定義されています。

### PicoRubySourcePatch

`PicoRubySourcePatch`はrpremoteに同梱され、展開済みPicoRubyソースへ必要なR2P2シェルのパッチを適用します。
Rubyプログラムの例外時にR2P2が専用ステータスを出力するため、例外文の文字列判定をせずに`rpremote run`と`rpremote exec`を非0で終了できます。

`rpremote setup`はソース準備後に、`rpremote build`はビルド前にパッチを適用します。
すでに適用済みなら変更しないため、gemを更新した後に既存キャッシュをビルドしても現在のパッチが適用されます。

同梱パッチの対象はPicoRuby 4.0.4、4.0.3、3.4.5です。PicoRuby 3.4.2には互換性のある3.4.5用パッチを使います。
これはソースパッチの対象を示すものであり、すべてのR2P2版がすべてのボードで正常に起動することを保証するものではありません。

パッチ適用に失敗した場合、キャッシュ済みソースが想定したPicoRubyリリースと異なります。
`config/setting.json`の`language_version`を更新するか、`--language-version`で対象バージョンを指定してください。設定ファイルを更新した場合は`rpremote setup --force`でキャッシュを作り直します。一時的に指定する場合は、`setup`と再ビルドの両方に同じ`--language-version VERSION`を指定してください。

```ruby
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "examples/picoruby/mrbgems/mpu6050"
```

どちらのgemにもmruby/c向けのC拡張があるため、`vm :mrubyc`を指定します。PicoRuby 4系では公式の`femtoruby`ビルド設定、3系では`picoruby`ビルド設定へ自動的に対応付けられます。

次のコマンドで定義と固定済みコミットを確認できます。

```sh
rpremote mrbgems check
rpremote mrbgems list
```

固定されたコミットは`Mrbgems.lock`に保存されています。最新版へ更新するときだけ`rpremote mrbgems update`を実行します。

## 2. Pico 2用UF2をビルドする

```sh
rpremote build --firmware firmware/r2p2-picoruby-latest-pico2.uf2
```

`rpremote build`は`Mrbgems.lock`を自動検出し、lock済みgemから一時ビルド設定を生成します。`Mrbgems`の評価やlockの更新は行いません。
公式ソースを手作業で編集する必要はありません。R2P2例外ステータス用の`PicoRubySourcePatch`だけはrpremoteが管理して適用します。

完成したUF2は`firmware/r2p2-picoruby-latest-pico2.uf2`に保存されます。中間ファイルは`build/`に作成されます。`--firmware`を省略した場合は、`firmware/picoruby-latest-pico2.uf2`が既定の出力先です。

## 3. Pico 2へ書き込む

Pico 2のBOOTSELボタンを押しながらUSB接続し、マウント先を指定します。

```sh
rpremote flash --firmware firmware/r2p2-picoruby-latest-pico2.uf2
```

## 4. サンプルを配線して実行する

- WS2812BのDINをGP14（物理19番）へ接続
- WS2812BのGNDをPico 2のGNDへ接続
- WS2812BのVDDを3V3(OUT)へ接続
- ボタンをGP15（物理20番）とGNDの間に接続

```sh
rpremote run examples/picoruby/education/04_ws2812/main.rb --timeout 15
```

ボタンを押すたびに7色へ切り替わり、最後に`ws2812: OK`が表示されます。5 V専用のWS2812Bモジュールを使う場合は、電源電圧とレベルシフタの要否を確認してください。

`06_mpu6050`では、さらにMPU6050とブザーを[サンプルREADME](../examples/picoruby/education/06_mpu6050/README.ja.md)に従って接続し、同じファームウェアで実行します。

```sh
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

mrbgemを変更した後は、ビルド、BOOTSEL移行、書き込み、実行の手順を繰り返します。

```sh
rpremote build --firmware firmware/r2p2-picoruby-latest-pico2.uf2
rpremote bootsel
rpremote flash --firmware firmware/r2p2-picoruby-latest-pico2.uf2
rpremote run examples/picoruby/education/06_mpu6050/main.rb --timeout 15
```

`deploy PATH --build`は上記のビルド、BOOTSEL移行、書き込みを行った後、プロジェクトの`PATH/lib/NAME`を`:/lib/NAME`へコピーして`PATH/main.rb`を一時実行します。`--build`を付けない`deploy PATH`はビルドを省略し、既存UF2を書き込んでからプロジェクトをコピー・実行します。
