# オプションと設定ファイル

`rpremote` はコマンドラインオプションとプロジェクト設定ファイルで動作を指定します。
コマンドラインオプションが設定ファイルより優先されます。

## 設定ファイル

既定の設定ファイルはプロジェクト直下の `config/setting.json` です。初回は次の
コマンドで空の設定ファイルを作成できます。既存の内容は上書きしません。

```sh
rpremote setup
```

別の設定ファイルを使う場合は、すべてのコマンドで `--config FILE` を指定できます。

```sh
rpremote build --config config/pico2.json
```

設定ファイルはJSONオブジェクトです。キーはスネークケース、対応するCLIオプションは
ハイフン区切りです。

```json
{
  "port": "/dev/cu.usbmodem101",
  "baud": 115200,
  "timeout": 10,
  "language": "picoruby",
  "cache": "firmware",
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/picoruby-4.0.3-pico2.uf2",
  "mount": "/Volumes/RP2350",
  "mrbgems": "Mrbgems"
}
```

設定ファイル内のすべてのキーは、実行するコマンドで使われないものも含めて検証されます。
未知のキー、空文字列、型が違う値、0以下の `baud` または `timeout` はエラーになります。

## 設定キー

| キー               | 対応するオプション   | 既定値                                                | 用途                                                                       |
| ------------------ | -------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- |
| `language`         | `--language`         | `picoruby`                                            | `setup`、`build`、`flash`、実行系コマンドの言語指定（現在は`picoruby`のみ） |
| `language_version` | `--language-version` | `4.0.3`                                               | `setup`、`build`、`flash`で使うPicoRuby/R2P2版                             |
| `cache`            | `--cache`            | `firmware`                                            | PicoRubyソースとカスタムUF2の保存先。`{version}`を言語版へ展開              |
| `board`            | `--board`            | `pico2`                                             | `build`と`flash`の対象ボード（`pico2`、`pico2_w`）                          |
| `firmware`         | `--firmware`       | `{cache}/{language}-{language_version}-{board}.uf2` | buildの出力先とflashするUF2                                                 |
| `mrbgems`          | `--mrbgems`          | 自動検出                                              | `build`で使うMrbgems定義ファイル。`false`で無効化                           |
| `mount`            | `--mount`            | 自動検出                                              | `flash`時のRP2350 BOOTSELボリューム                                        |
| `port`             | `--port`             | CDC 0を自動選択                                       | R2P2シリアルポート                                                         |
| `baud`             | `--baud`             | `115200`                                              | シリアル通信速度                                                           |
| `timeout`          | `--timeout`          | コマンドごと                                          | 接続・通信のタイムアウト秒数                                               |

`language_version` はCLI自身の `rpremote --version` と区別するため、`--version` ではなく
`--language-version` を使います。

## 共通オプション

| オプション        | 用途                                                  |
| ----------------- | ----------------------------------------------------- |
| `--config FILE`   | 既定の `config/setting.json` 以外の設定ファイルを使う |
| `-h`、`--help`    | コマンド一覧とオプションを表示する                    |
| `-V`、`--version` | rpremote自身のバージョンを表示する                    |

## コマンドごとのオプション

| コマンド                         | オプション                                                                                            |
| -------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `setup`                          | `--language`、`--language-version`、`--cache`、`--force`                                              |
| `build`                          | `--language`、`--language-version`、`--board`、`--cache`、`--firmware`、`--mrbgems`、`--no-mrbgems` |
| `build clean`                    | なし。プロジェクトの `build/` だけを削除                                                              |
| `dfu app FILE`                   | `--type ruby\|rite`、`--port`、`--baud`、`--timeout`                                                  |
| `dfu compile FILE`               | `--output`、`--language`、`--language-version`、`--cache`                                              |
| `dfu status`                     | `--port`、`--baud`、`--timeout`                                                                         |
| `mrbgems check/list/lock/update` | `--file`、`--lockfile`                                                                                |
| `flash`                          | `--language`、`--language-version`、`--board`、`--cache`、`--firmware`、`--mount`、`--port`、`--timeout` |
| `ports`                          | なし                                                                                                  |
| `run`、`exec`                    | `--port`、`--baud`、`--timeout`、`--language`                                                         |
| `monitor`、`repl`、`reset`       | `--port`、`--baud`、`--timeout`                                                                       |
| `fs cp/cat/ls/rm/mkdir`          | `--port`、`--baud`、`--timeout`                                                                       |

すべてのコマンドの既定タイムアウトは10秒です。
`flash` は `build` 済みのカスタムUF2を使用します。`--firmware`を省略した場合は
`{cache}/{language}-{language-version}-{board}.uf2` を書き込みます。

## よく使う設定例

Pico 2のポートとビルド先を固定する例です。

```json
{
  "port": "/dev/cu.usbmodem101",
  "cache": "firmware",
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/r2p2-picoruby-4.0.3-pico2.uf2"
}
```

`firmware`を指定すると、ビルドと書き込みの両方でオプションを省略できます。

```sh
rpremote setup
rpremote build
rpremote flash --mount /Volumes/RP2350
rpremote run examples/education/01_blink/main.rb
```

PicoRubyのバージョンだけ一度変更する場合は、設定を変えずにCLIで上書きします。

```sh
rpremote setup --language-version 3.4.2
rpremote build --language-version 3.4.2 \
  --firmware firmware/r2p2-picoruby-3.4.2-pico2.uf2
```
