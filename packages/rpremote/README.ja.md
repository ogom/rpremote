# rpremote

[English](README.md)

Raspberry Pi Pico向けのカスタムPicoRuby R2P2ファームウェアを準備、ビルド、書き込み、操作するためのコマンドラインツールです。

公開mrbgemとローカルmrbgemを再現可能なファームウェアへ組み込み、生成したUF2のBOOTSEL書き込み、R2P2経由のバイナリ安全なファイル転送とRuby実行を行えます。

## 必要環境

- macOSとRuby 4.0以降
- ファームウェアビルド用のGit、GNU Make、CMake、Arm GNU Toolchain
- 選択したR2P2ビルド設定に対応するRaspberry Pi Picoボード
- R2P2ビルド設定を含むPicoRuby

## インストール

```sh
gem install rpremote
```

## クイックスタート

プロジェクトのディレクトリで実行します。

```sh
rpremote setup
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run main.rb
```

`setup`はRaspberry Pi公式のリセット用`nuke_universal.uf2`も`firmware/`へダウンロードします。

再利用するRubyコードを`lib/NAME`へ置くプロジェクトでは、`deploy`が既存ファームウェアを書き込み、そのディレクトリをR2P2へコピーしてからエントリーファイルを一時実行します。`--build`を付けると、同じ処理の前にファームウェアをビルドします。

```sh
rpremote deploy path/to/project
rpremote deploy path/to/project --build
```

既定では`firmware/picoruby-4.0.3/`にソースを準備し、`firmware/picoruby-4.0.3-pico2.uf2`を生成します。対象ボードを明示する必要がある場合は、`rpremote ports`でR2P2のCDC 0ポートを確認してください。

## mrbgemを追加する

プロジェクト直下に`Mrbgems`を作成します。ローカルパスはこのファイルを基準にします。

```ruby
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

依存関係を検査、固定してビルドします。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

`Mrbgems.lock`はGitHubのコミットとローカルgemの内容ハッシュを固定します。`build`は既存のlockを再利用し、`rpremote mrbgems update`だけが新しいコミットを解決します。

ファームウェアへ組み込む一方で、すべての`run`、`exec`、`deploy`に先行ロードしないgemには`auto_require: false`を指定できます。アプリケーション側から必要なgemを明示的に`require`してください。

## 対象を選択する

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 --mount /Volumes/RP2350
```

コマンドラインオプションは`config/setting.json`より優先されます。現在実装されているのはPicoRubyです。将来のMicroPythonと追加Picoボード対応に備え、`language`と`board`はインターフェースに残しています。

## 作業を選ぶ

- `setup`でプロジェクトを準備し、`config show`で実効設定を確認します。最初のファームウェア導入には`build`と`flash`を使います。
- プロジェクト開発では`deploy PATH`を使います。選択したファームウェアを書き込み、存在する場合は`PATH/lib/NAME`をコピーして`PATH/main.rb`を実行します。先にファームウェアを再ビルドする場合は`--build`を付けます。
- Rubyを一時実行する場合は`run`または`exec`、対話型シリアル接続には`monitor`または`repl`を使います。`monitor`と`repl`は`Ctrl-]`で終了します。
- R2P2上へファイルを保持する場合は`fs`、再起動後も実行するA/B起動アプリには`dfu`を使います。

完全なコマンド一覧は`rpremote --help`で確認します。現在の構文、既定値、処理順、影響についてはコマンドヘルプが実行可能なリファレンスです。

```sh
rpremote deploy --help
rpremote dfu app --help
rpremote fs cp --help
```

### 安全上の境界

- `flash`は永続的なR2P2ファームウェアを置き換えます。`bootsel --reset-flash-memory`はPico 2の外部フラッシュ全体を消去するため、実行後にR2P2を再度書き込む必要があります。
- `dfu remove`はDFUのA/B両アプリスロットを完全に空にします。RAM上ですでに動作しているアプリを停止するには、別途リセットします。
- `fs rm`は指定したリモートパスを完全に削除します。再帰転送ではボード上だけに存在するファイルを削除しません。
- `run`と`exec`は一時リモートファイルを削除します。Ruby例外時の非0終了には対応するR2P2ファームウェアが必要で、このリポジトリからビルドしたUF2は対応しています。

## ドキュメントとサンプル

- [作業に応じてコマンドを選ぶ](https://github.com/ogom/rpremote/blob/main/docs/command.ja.md)
- [プロジェクトを設定する](https://github.com/ogom/rpremote/blob/main/docs/config.ja.md)
- [カスタムファームウェアをビルドする](https://github.com/ogom/rpremote/blob/main/docs/firmware.ja.md)
- [MrbgemsとMrbgems.lockを管理する](https://github.com/ogom/rpremote/blob/main/docs/mrbgems.ja.md)
- [PicoModem DFUで起動アプリを更新する](https://github.com/ogom/rpremote/blob/main/docs/dfu.ja.md)
- [電子工作サンプルを見る](https://github.com/ogom/rpremote/tree/main/examples)

## 関連プロジェクト

- [mbremote](https://github.com/ogom/mbremote)は、BBC micro:bit向けのMicroPython／PicoRubyプロジェクトをビルド、書き込み、操作する、同じコンセプトのツールです。

## 開発

依存gemを導入して、テスト、静的解析、RBSを検証します。

```sh
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

変更したローカル版を試すときは、次を実行します。ネットワークへ接続せずにgemをビルドし、現在のRuby環境へインストールします。

```sh
bundle exec rake install:local
rpremote --version
```

リリースする版は`lib/rpremote/version.rb`と`CHANGELOG.md`を更新します。公開前は`bundle exec rake release:check`を実行し、[RELEASING.md](RELEASING.md)に従ってください。

## ライセンス

[MIT](LICENSE)です。外部ソフトウェアについては[第三者ソフトウェアに関する通知](THIRD_PARTY_NOTICES.md)を参照してください。
