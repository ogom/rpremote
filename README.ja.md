# rpremote

[English](README.md)

Raspberry Pi Pico向けのカスタムPicoRuby R2P2ファームウェアを準備、ビルド、書き込み、操作するためのコマンドラインツールです。

rpremoteの中心的な目的は、[`picoruby-ws2812-plus`](https://github.com/ksbmyk/picoruby-ws2812-plus)のような公開mrbgemやプロジェクト内のローカルmrbgemを、再現可能なRaspberry Pi Pico用ファームウェアへ簡単に組み込めるようにすることです。このリポジトリには`packages/rpremote`のRubyGemと、`examples`の実機サンプルが含まれます。

## クイックスタート

公開されたgemをインストールし、このリポジトリをcloneしてから、既定のPicoRubyソースをダウンロードして準備します。

```sh
gem install rpremote
git clone https://github.com/ogom/rpremote.git
cd rpremote
rpremote setup
```

カスタムUF2をビルドします。プロジェクト直下の`Mrbgems`は自動検出されます。

```sh
rpremote build
```

既定では`firmware/picoruby-4.0.3/`にソース、`build/`に中間生成物、`firmware/picoruby-4.0.3-pico2.uf2`に完成UF2を保存します。

BOOTSELを押しながらPico 2を接続し、書き込み後にRubyプログラムを実行します。

```sh
rpremote flash --mount /Volumes/RP2350
rpremote run examples/picoruby/education/01_blink/main.rb
```

R2P2のシリアルポートは`rpremote ports`で確認できます。複数台を接続している場合は`--port`でCDC 0を指定してください。

## コードを実行してコンソールを使う

`rpremote run`と`rpremote exec`は一時実行コマンドです。Rubyコードを転送・実行して出力を表示し、一時リモートファイルを削除します。対応するR2P2ファームウェアがRuby例外を報告した場合は、非0で終了します。

```sh
rpremote run examples/picoruby/education/01_blink/main.rb
rpremote exec 'puts 1 + 2'
rpremote monitor
rpremote repl
rpremote reset
```

`monitor`と`repl`は`Ctrl-]`で終了します。`reset`はR2P2を再起動して再接続まで待ちます。

## リモートファイルを操作する

R2P2上のパスには`:`を付けます。`fs cp`では片方だけをリモートパスにします。`fs rm`は指定したリモートパスを完全に削除します。

```sh
rpremote fs ls :/
rpremote fs cp local.txt :/local.txt
rpremote fs cat :/local.txt
rpremote fs rm :/local.txt
```

## 実効設定を確認する

ビルドや書き込みの前に、適用される設定を確認します。このコマンドは、設定ファイル、コマンドライン指定、既定値を解決しますが、ボードへ接続しません。

```sh
rpremote config show --board pico2_w
```

## DFUアプリを更新する

`flash`はR2P2ファームウェアを永続的に置き換えます。一方、`dfu app`はRubyソースまたは対応するバイトコードのアプリを非アクティブDFUスロットへ登録します。次回の再起動でそのアプリを試行し、正常に起動したアプリは`DFU.confirm`を呼び出します。

```sh
rpremote dfu app examples/picoruby/education/07_dfu/main.rb
rpremote reset
```

## 必要環境

- macOSとRuby 4.0以降
- Git、GNU Make、CMake、Arm GNU Toolchain
- 選択したR2P2ビルド設定に対応するRaspberry Pi Picoボード
- R2P2ビルド設定を含むPicoRuby

シリアル通信にはmacOSの`stty`とRuby標準IOを使うため、サードパーティ製のシリアルポートgemは不要です。コマンド実行中はR2P2のCDC 0ポートを別のターミナルで開かないでください。サンプルを使う場合は、このリポジトリをcloneし、リポジトリのルートでコマンドを実行してください。

## mrbgemを追加する

ビルド時に組み込む公開gemとローカルgemを`Mrbgems`へ定義します。ローカルパスはこのファイルを基準に解決されます。

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

`Mrbgems.lock`はGitHubのコミットとローカルgemの内容ハッシュを固定します。`build`は既存のlockを再利用します。依存関係を更新するときだけ`rpremote mrbgems update`を実行してください。

## 対象を選択する

言語、言語バージョン、ボード、キャッシュ、ファームウェアのパスを指定できます。コマンドラインオプションは`config/setting.json`より優先されます。

```sh
rpremote setup --language picoruby --language-version 3.4.2
rpremote build --language picoruby --language-version 3.4.2 --board pico2
rpremote flash --language picoruby --language-version 3.4.2 --board pico2 --mount /Volumes/RP2350
```

現在実装されているのはPicoRubyです。将来のMicroPythonと追加ボード対応に備え、`language`と`board`はインターフェースに残しています。

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
| `rpremote flash` | ビルド済みUF2をRP2350 BOOTSELボリュームへ書き込みます。 |
| `rpremote config show` | 設定ファイルとコマンドラインオプションを反映した実効設定を表示します。 |
| `rpremote ports` | 検出したR2P2シリアルポートを表示します。 |
| `rpremote run FILE` | Rubyファイルを転送・実行し、出力をリアルタイム表示して終了後に削除します。Ruby例外時は非0で終了します。 |
| `rpremote exec CODE` | 短いRubyコードを実行します。Ruby例外時は非0で終了します。 |
| `rpremote monitor` | シリアルモニターを開きます。 |
| `rpremote repl` | PicoIRBを開きます。 |
| `rpremote reset` | R2P2を再起動し、再接続まで待ちます。 |
| `rpremote fs …` | リモートファイルの転送、表示、一覧、削除、作成を行います。 |

コマンド一覧は`rpremote --help`、コマンド固有の構文、既定値、影響は`rpremote <command> --help`で確認できます。

`run`と`exec`の例外終了コードには、Ruby例外ステータスに対応したR2P2ファームウェアが必要です。このリポジトリのPicoRubyソースから`rpremote build`で生成したUF2が対応しています。

## サンプル

- [01 blink](examples/picoruby/education/01_blink/README.ja.md): Pico 2のオンボードLEDとシリアル出力を確認します。
- [04 WS2812](examples/picoruby/education/04_ws2812/README.ja.md): カスタムファームウェアをビルドし、ボタンでWS2812Bを制御します。
- [07 PicoModem DFU](examples/picoruby/education/07_dfu/README.ja.md): 設置済みアプリを更新し、A/Bスロットのロールバックを確認します。
- [10 Wi-Fi](examples/picoruby/education/10_wifi/README.ja.md): Pico 2 WをWPA2-PSKアクセスポイントへ接続します。
- [サンプル一覧](examples/README.ja.md)

## ドキュメント

- [オプションと設定ファイル](docs/config.ja.md) / [English](docs/config.md)
- [04_ws2812用カスタムファームウェア](docs/firmware.ja.md) / [English](docs/firmware.md)
- [MrbgemsとMrbgems.lock](docs/mrbgems.ja.md) / [English](docs/mrbgems.md)
- [PicoModem DFUによるアプリケーション更新](docs/dfu.ja.md) / [English](docs/dfu.md)
- [CLIリファレンスとRubyGemパッケージガイド](packages/rpremote/README.ja.md)

## 開発

パッケージディレクトリで依存関係を導入し、検査を実行します。

```sh
cd packages/rpremote
bundle install
bundle exec rake
bundle exec rbs -I sig validate
```

公開前は`bundle exec rake release:check`を実行し、[リリース手順](packages/rpremote/RELEASING.md)に従ってください。この検査はgemの公開やGit tagのpushを行いません。

## 関連プロジェクト

- [mbremote](https://github.com/ogom/mbremote)は、BBC micro:bit向けのMicroPython／PicoRubyプロジェクトをビルド、書き込み、操作する、同じコンセプトのツールです。

## ライセンス

[MIT](LICENSE)です。外部ソフトウェアについては[第三者ソフトウェアに関する通知](packages/rpremote/THIRD_PARTY_NOTICES.md)を参照してください。
