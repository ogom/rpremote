# コマンドリファレンス

[English](command.md)

このページは`rpremote`のコマンド一覧です。完全なコマンド一覧は`rpremote --help`、個別コマンドの現在の構文、既定値、影響は`rpremote <command> --help`で確認します。

## 1. プロジェクトを準備する

| コマンド | 説明 |
| --- | --- |
| `rpremote setup` | プロジェクト設定を作成し、言語ソースを準備します。 |
| `rpremote config show` | 設定ファイルとコマンドラインオプションを反映した実効設定を表示します。 |

## 2. mrbgemを組み込み、ファームウェアをビルドする

| コマンド | 説明 |
| --- | --- |
| `rpremote mrbgems …` | mrbgem依存関係を検査、表示、固定、更新します。 |
| `rpremote build` | mrbgemを含むカスタムUF2をビルドします。 |
| `rpremote build clean` | 生成された中間ビルドファイルを削除します。 |

## 3. 初回の書き込みと復旧を行う

| コマンド | 説明 |
| --- | --- |
| `rpremote flash` | ビルド済みUF2をRP2350 BOOTSELボリュームへ書き込みます。 |
| `rpremote bootsel` | 実行中のR2P2へBOOTSEL移行を要求し、USBボリュームの出現を待ちます。初回は物理BOOTSELを使います。 |
| `rpremote bootsel --reset-flash-memory` | BOOTSELへ移行し、Pico 2の外部フラッシュメモリ全体を消去します。消去後は`rpremote flash`でR2P2を再インストールします。 |

## 4. 日常の開発と操作を行う

| コマンド | 説明 |
| --- | --- |
| `rpremote ports` | 書き込み後に検出したR2P2シリアルポートを表示します。 |
| `rpremote deploy PATH` | ファームウェアをビルドして書き込み、`PATH/lib/NAME`を`:/lib/NAME`へコピーしてから`PATH/main.rb`を一時実行します。 |
| `rpremote fs cp SOURCE DESTINATION [--recursive]` | ローカルPCとR2P2の間で1ファイルを転送します。片方のパスだけにリモートパスの接頭辞`:`を付けます。`--recursive`を付けると不足しているリモートディレクトリを作成し、ローカルのディレクトリツリーを一括転送します。 |
| `rpremote fs push LOCAL_DIR :/REMOTE_DIR` | `fs cp --recursive`の別名です。ローカルのディレクトリツリーを一括転送し、リモートにだけ存在するファイルは削除しません。 |
| `rpremote fs cat/ls/rm/mkdir` | リモートファイルとディレクトリの表示、一覧、完全削除、作成を行います。 |
| `rpremote run FILE` | Rubyファイルを転送・実行し、出力をリアルタイム表示して終了後に削除します。Ruby例外時は非0で終了します。`--reset-on-timeout`を指定すると実行タイムアウト後にR2P2をリセットします。 |
| `rpremote exec CODE` | 短いRubyコードを実行します。Ruby例外時は非0で終了します。 |
| `rpremote monitor` | シリアルモニターを開きます。 |
| `rpremote repl` | PicoIRBを開きます。 |
| `rpremote reset` | R2P2を再起動し、再接続まで待ちます。 |

## 5. DFU起動アプリを更新する

| コマンド | 説明 |
| --- | --- |
| `rpremote dfu compile FILE` | DFU用にPicoRuby版と一致する`.mrb`を生成します。 |
| `rpremote dfu app FILE` | PicoModem DFUでRubyまたは版を照合したバイトコードのアプリを更新します。更新後は`rpremote reset`で起動します。 |
| `rpremote dfu status` | DFUのアクティブおよび起動候補スロットを表示します。 |
| `rpremote dfu remove` | DFU起動アプリを両スロットから削除します。実行中のアプリを停止するには`rpremote reset`を使います。 |

`run`と`exec`の例外終了コードには、Ruby例外ステータスに対応したR2P2ファームウェアが必要です。このリポジトリのPicoRubyソースから`rpremote build`で生成したUF2が対応しています。
