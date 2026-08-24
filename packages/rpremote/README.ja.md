# rpremote CLIリファレンス

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

## 対象を選択する

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 --mount /Volumes/RP2350
```

コマンドラインオプションは`config/setting.json`より優先されます。現在実装されているのはPicoRubyです。将来のMicroPythonと追加Picoボード対応に備え、`language`と`board`はインターフェースに残しています。

## コマンド

| コマンド | 説明 |
| --- | --- |
| `rpremote setup` | 設定を作成し、言語ソースを準備します。 |
| `rpremote build` | mrbgemを含むカスタムUF2をビルドします。 |
| `rpremote build clean` | 中間ビルドファイルを削除します。 |
| `rpremote dfu app FILE` | PicoModem DFUでRubyまたは版を照合したバイトコードのアプリを更新します。 |
| `rpremote dfu compile FILE` | DFU用にPicoRuby版と一致する`.mrb`を生成します。 |
| `rpremote dfu status` | DFUのアクティブおよび起動候補スロットを表示します。 |
| `rpremote mrbgems …` | mrbgemを検査、表示、固定、更新します。 |
| `rpremote flash` | 選択したUF2をBOOTSEL経由で書き込みます。 |
| `rpremote config show` | 設定ファイルとコマンドラインオプションを反映した実効設定を表示します。 |
| `rpremote ports` | R2P2シリアルポートを表示します。 |
| `rpremote run FILE` | Rubyファイルを転送して実行し、出力をリアルタイム表示します。Ruby例外時は非0で終了します。 |
| `rpremote exec CODE` | 短いRubyコードを実行します。Ruby例外時は非0で終了します。 |
| `rpremote monitor` / `repl` | 対話型シリアルセッションを開きます。 |
| `rpremote reset` | R2P2を再起動して再接続まで待ちます。 |
| `rpremote fs cp/cat/ls/rm/mkdir` | R2P2ファイルシステムを操作します。 |

コマンド一覧は`rpremote --help`で確認できます。コマンド固有の構文、既定値、影響は`rpremote <command> --help`で確認できます。

```sh
rpremote flash --help
rpremote dfu app --help
```

`monitor`と`repl`は`Ctrl-]`で終了します。

`run`と`exec`の例外終了コードには、Ruby例外ステータスに対応したR2P2ファームウェアが必要です。[GitHubリポジトリ](https://github.com/ogom/rpremote)のPicoRubyソースから`rpremote build`で生成したUF2が対応しています。

## 操作モデル

- `run`と`exec`はRubyコードを一時的に転送・実行して出力を表示し、一時リモートファイルを削除します。対応するR2P2ファームウェアがRuby例外を報告した場合は、非0で終了します。
- `flash`はUF2をRP2350 BOOTSELボリュームへコピーし、永続的なR2P2ファームウェアを置き換えます。
- `dfu app`はRubyソースまたは対応するバイトコードのアプリを非アクティブDFUスロットへ登録します。R2P2を再起動して試行し、正常に起動したアプリは`DFU.confirm`を呼び出します。
- リモートパスには`:/REMOTE/PATH`を使います。`fs cp`はローカルパスとリモートパスの間で転送し、`fs rm`は指定したリモートパスを完全に削除します。

## ドキュメントとサンプル

[GitHubリポジトリ](https://github.com/ogom/rpremote)に、英語・日本語のガイド、設定リファレンス、Mrbgems.lockの解説、カスタムファームウェア手順、電子工作サンプルがあります。

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
