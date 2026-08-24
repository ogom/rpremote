# rpremote

[English](README.md)

Raspberry Pi Pico向けのカスタムPicoRuby R2P2ファームウェアを準備、ビルド、
書き込み、操作するためのコマンドラインツールです。

rpremoteの中心的な目的は、
[`picoruby-ws2812-plus`](https://github.com/ksbmyk/picoruby-ws2812-plus)のような
公開mrbgemやプロジェクト内のローカルmrbgemを、再現可能なRaspberry Pi Pico用
ファームウェアへ簡単に組み込めるようにすることです。このリポジトリには
`packages/rpremote`のRubyGemと、`examples`の実機サンプルが含まれます。

## 必要環境

- macOS
- Ruby 4.0以降
- Git、GNU Make、CMake、Arm GNU Toolchain
- 選択したR2P2ビルド設定に対応するRaspberry Pi Picoボード
- R2P2ビルド設定を含むPicoRuby

シリアル通信にはmacOSの`stty`とRuby標準IOを使うため、サードパーティ製の
シリアルポートgemは不要です。コマンド実行中はR2P2のCDC 0ポートを別の
ターミナルで開かないでください。

## インストール

公開されたgemをインストールします。

```sh
gem install rpremote
```

サンプルを使う場合は、このリポジトリをcloneし、リポジトリのルートで
コマンドを実行してください。

## クイックスタート

既定のPicoRubyソースをダウンロードして準備します。

```sh
rpremote setup
```

カスタムUF2をビルドします。プロジェクト直下の`Mrbgems`は自動検出されます。

```sh
rpremote build
```

既定では`firmware/picoruby-4.0.3/`にソース、`build/`に中間生成物、
`firmware/picoruby-4.0.3-pico2.uf2`に完成UF2を保存します。

BOOTSELを押しながらPico 2を接続し、書き込み後にRubyプログラムを実行します。

```sh
rpremote flash --mount /Volumes/RP2350
rpremote run examples/education/01_blink/main.rb
```

R2P2のシリアルポートは`rpremote ports`で確認できます。複数台を接続している
場合は`--port`でCDC 0を指定してください。

## mrbgemを追加する

ビルド時に組み込む公開gemとローカルgemを`Mrbgems`へ定義します。ローカルパスは
このファイルを基準に解決されます。

```ruby
vm :mrubyc

gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

依存関係を検査して固定してからビルドします。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
```

`Mrbgems.lock`はGitHubのcommitとローカルgemの内容hashを固定します。`build`は
既存lockを再利用します。依存関係を更新するときだけ`rpremote mrbgems update`を
実行してください。

## 対象を選択する

言語、言語バージョン、ボード、キャッシュ、ファームウェアのパスを指定できます。
コマンドラインオプションは`config/setting.json`より優先されます。

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 \
  --mount /Volumes/RP2350
```

現在実装されているのはPicoRubyです。将来のMicroPythonと追加ボード対応に備え、
`language`と`board`はインターフェースに残しています。

## コマンド

| コマンド | 説明 |
| --- | --- |
| `rpremote setup` | プロジェクト設定を作成し、言語ソースを準備します。 |
| `rpremote build` | mrbgemを含むカスタムUF2をビルドします。 |
| `rpremote build clean` | 生成された中間ビルドファイルを削除します。 |
| `rpremote dfu app FILE` | PicoModem DFUでRubyまたは版を照合したバイトコードのアプリを更新します。 |
| `rpremote dfu compile FILE` | DFU用にPicoRuby版と一致する`.mrb`を生成します。 |
| `rpremote dfu status` | DFUのアクティブおよび起動候補スロットを表示します。 |
| `rpremote mrbgems …` | mrbgem依存関係を検査、表示、固定、更新します。 |
| `rpremote flash` | ビルド済みUF2をRP2350 BOOTSELボリュームへ書き込む。 |
| `rpremote ports` | 検出したR2P2シリアルポートを表示します。 |
| `rpremote run FILE` | Rubyファイルを転送・実行し、終了後に削除します。 |
| `rpremote exec CODE` | 短いRubyコードを実行します。 |
| `rpremote monitor` | シリアルモニターを開く。 |
| `rpremote repl` | PicoIRBを開く。 |
| `rpremote reset` | R2P2を再起動し、再接続まで待つ。 |
| `rpremote fs …` | リモートファイルの転送、表示、一覧、削除、作成を行う。 |

完全な構文は`rpremote --help`で確認できます。対話コマンドは`Ctrl-]`で終了します。

## ドキュメント

- [オプションと設定ファイル](docs/config.ja.md) / [English](docs/config.md)
- [04_ws2812用カスタムファームウェア](docs/firmware.ja.md) / [English](docs/firmware.md)
- [MrbgemsとMrbgems.lock](docs/mrbgems.ja.md) / [English](docs/mrbgems.md)
- [PicoModem DFUによるアプリケーション更新](docs/dfu.ja.md) / [English](docs/dfu.md)
- [サンプル](examples/README.ja.md)
- [RubyGemパッケージガイド](packages/rpremote/README.ja.md)

## 関連プロジェクト

- [mbremote](https://github.com/ogom/mbremote)は、BBC micro:bit向けの
  MicroPython／PicoRubyプロジェクトをビルド、書き込み、操作する、同じコンセプトの
  ツールです。

## 開発

パッケージディレクトリで依存関係を導入し、検査を実行します。

```sh
cd packages/rpremote
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

公開前は`bundle exec rake release:check`を実行し、
[リリース手順](packages/rpremote/RELEASING.md)に従ってください。この検査はgemの
公開やGit tagのpushを行いません。

## ライセンス

[MIT](LICENSE)です。外部ソフトウェアについては
[第三者ソフトウェアに関する通知](packages/rpremote/THIRD_PARTY_NOTICES.md)を参照してください。
