# rpremote

[English](README.md)

Raspberry Pi Pico向けのカスタムPicoRuby R2P2ファームウェアを準備、ビルド、
書き込み、操作するためのコマンドラインツールです。

公開mrbgemとローカルmrbgemを再現可能なファームウェアへ組み込み、生成したUF2の
BOOTSEL書き込み、R2P2経由のバイナリ安全なファイル転送とRuby実行を行えます。

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

既定では`firmware/picoruby-4.0.3/`にソースを準備し、
`firmware/picoruby-4.0.3-pico2.uf2`を生成します。対象ボードを明示する必要がある
場合は、`rpremote ports`でR2P2のCDC 0ポートを確認してください。

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

`Mrbgems.lock`はGitHubのcommitとローカルgemの内容hashを固定します。`build`は
既存lockを再利用し、`rpremote mrbgems update`だけが新しいcommitを解決します。

## 対象を選択する

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 \
  --mount /Volumes/RP2350
```

コマンドラインオプションは`config/setting.json`より優先されます。現在実装されて
いるのはPicoRubyです。将来のMicroPythonと追加Picoボード対応に備え、
`language`と`board`はインターフェースに残しています。

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
| `rpremote flash` | 選択したUF2をBOOTSEL経由で書き込む。 |
| `rpremote ports` | R2P2シリアルポートを表示します。 |
| `rpremote run FILE` | Rubyファイルを転送して実行します。 |
| `rpremote exec CODE` | 短いRubyコードを実行します。 |
| `rpremote monitor` / `repl` | 対話型シリアルセッションを開く。 |
| `rpremote reset` | R2P2を再起動して再接続まで待つ。 |
| `rpremote fs cp/cat/ls/rm/mkdir` | R2P2ファイルシステムを操作します。 |

完全な構文は`rpremote --help`で確認できます。`monitor`と`repl`は`Ctrl-]`で
終了します。

## ドキュメントとサンプル

[GitHubリポジトリ](https://github.com/ogom/rpremote)に、英語・日本語のガイド、
設定リファレンス、Mrbgems.lockの解説、カスタムファームウェア手順、電子工作
サンプルがあります。

## 関連プロジェクト

- [mbremote](https://github.com/ogom/mbremote)は、BBC micro:bit向けの
  MicroPython／PicoRubyプロジェクトをビルド、書き込み、操作する、同じコンセプトの
  ツールです。

## 開発

```sh
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

公開前は`bundle exec rake release:check`を実行し、
[RELEASING.md](RELEASING.md)に従ってください。

## ライセンス

[MIT](LICENSE)です。外部ソフトウェアについては
[第三者ソフトウェアに関する通知](THIRD_PARTY_NOTICES.md)を参照してください。
