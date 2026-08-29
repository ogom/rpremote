# オプションと設定ファイル

`rpremote`はコマンドラインオプションとプロジェクト設定ファイルで動作を指定します。コマンドラインオプションが設定ファイルより優先されます。

## 設定ファイル

既定の設定ファイルはプロジェクト直下の`config/setting.json`です。初回は次のコマンドで空の設定ファイルを作成できます。既存の内容は上書きしません。

```sh
rpremote setup
```

別の設定ファイルを使う場合は、すべてのコマンドで`--config FILE`を指定できます。

```sh
rpremote build --config config/pico2.json
```

設定ファイルはJSONオブジェクトです。キーはスネークケース、対応するCLIオプションはハイフン区切りです。

```json
{
  "port": "/dev/cu.usbmodem101",
  "baud": 115200,
  "timeout": 20,
  "language": "picoruby",
  "cache": "firmware",
  "language_version": "4.0.3",
  "board": "pico2",
  "firmware": "firmware/picoruby-4.0.3-pico2.uf2",
  "mount": "/Volumes/RP2350",
  "mrbgems": "Mrbgems"
}
```

設定ファイル内のすべてのキーは、実行するコマンドで使われないものも含めて検証されます。未知のキー、空文字列、型が違う値、0以下の`baud`または`timeout`はエラーになります。

## 優先順位

| 優先順位 | 設定元 | 動作 |
| --- | --- | --- |
| 1 | コマンドラインオプション | 選択したコマンドの設定ファイル値を上書きします。 |
| 2 | `--config FILE`、または省略時は`config/setting.json` | プロジェクトの既定値を設定します。 |
| 3 | 組み込みの既定値 | コマンドラインと設定ファイルのどちらにも値がない場合に使います。 |

## 実効設定を表示する

`rpremote config show`は、ボードへ接続したりプロジェクトの状態を変更したりせずに、設定ファイル、既定値、コマンドラインオプションを解決します。選択された言語、言語バージョン、ボード、キャッシュ、ファームウェアパス、mrbgem設定、マウント先、ポート、ボーレート、タイムアウトを表示します。

```sh
rpremote config show --config config/pico2.json --board pico2_w
```

たとえば、`--no-mrbgems`はMrbgemsの自動検出を無効にします。`cache`内の`{version}`は選択した言語バージョンへ展開され、既定のファームウェアパスは解決後のキャッシュ、言語、言語バージョン、ボードから展開されます。

```text
language=picoruby
language_version=4.0.3
board=pico2_w
cache=firmware
firmware=firmware/picoruby-4.0.3-pico2_w.uf2
mrbgems=false
mount=auto
port=auto
baud=115200
timeout=20.0
```

## 設定キー

| キー               | 対応するオプション   | 既定値                                                | 用途                                                                       |
| ------------------ | -------------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- |
| `language`         | `--language`         | `picoruby`                                            | `setup`、`build`、`deploy`、`flash`、実行系コマンドの言語指定（現在は`picoruby`のみ） |
| `language_version` | `--language-version` | `4.0.3`                                               | `setup`、`build`、`deploy`、`flash`で使うPicoRuby/R2P2版                    |
| `cache`            | `--cache`            | `firmware`                                            | PicoRubyソースとカスタムUF2の保存先。`{version}`を言語版へ展開              |
| `board`            | `--board`            | `pico2`                                             | `build`、`deploy`、`flash`の対象ボード（`pico2`、`pico2_w`）                 |
| `firmware`         | `--firmware`       | `{cache}/{language}-{language_version}-{board}.uf2` | `build`の出力先と`deploy`、`flash`で書き込むUF2です                           |
| `mrbgems`          | `--mrbgems`          | 自動検出                                              | `build`、`deploy`で使うMrbgems定義ファイル。`false`で無効化                   |
| `mount`            | `--mount`            | 自動検出                                              | `bootsel`、`deploy`、`flash`時のRP2350 BOOTSELボリューム                      |
| `port`             | `--port`             | CDC 0を自動選択                                       | R2P2シリアルポート                                                         |
| `baud`             | `--baud`             | `115200`                                              | シリアル通信速度                                                           |
| `timeout`          | `--timeout`          | コマンドごと                                          | 接続・通信のタイムアウト秒数。`run`と`exec`では無出力が続けられる最大秒数 |

`language_version`はCLI自身の`rpremote --version`と区別するため、`--version`ではなく`--language-version`を使います。

## 共通オプション

| オプション        | 用途                                                  |
| ----------------- | ----------------------------------------------------- |
| `--config FILE`   | 既定の`config/setting.json`以外の設定ファイルを使います。 |
| `-h`、`--help`    | コマンド一覧とオプションを表示します。                |
| `-V`、`--version` | rpremote自身のバージョンを表示します。                |

## コマンドごとのオプション

| コマンド                         | オプション                                                                                            |
| -------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `setup`                          | `--language`、`--language-version`、`--cache`、`--force`                                              |
| `build`                          | `--language`、`--language-version`、`--board`、`--cache`、`--firmware`、`--mrbgems`、`--no-mrbgems` |
| `build clean`                    | なし。プロジェクトの`build/`だけを削除します。                                                        |
| `deploy PATH`                    | `--language`、`--language-version`、`--board`、`--cache`、`--firmware`、`--mrbgems`、`--no-mrbgems`、`--mount`、`--port`、`--baud`、`--timeout` |
| `bootsel`                        | `--mount`、`--port`、`--baud`、`--timeout` |
| `dfu app FILE`                   | `--type ruby\|rite`、`--port`、`--baud`、`--timeout`                                                  |
| `dfu compile FILE`               | `--output`、`--language`、`--language-version`、`--cache`                                              |
| `dfu status`                     | `--port`、`--baud`、`--timeout`                                                                         |
| `mrbgems check/list/lock/update` | `--file`、`--lockfile`                                                                                |
| `flash`                          | `--language`、`--language-version`、`--board`、`--cache`、`--firmware`、`--mount`、`--port`、`--timeout` |
| `config show`                    | `--language`、`--language-version`、`--board`、`--cache`、`--firmware`、`--mrbgems`、`--no-mrbgems`、`--mount`、`--port`、`--baud`、`--timeout` |
| `ports`                          | なし                                                                                                  |
| `run`、`exec`                    | `--port`、`--baud`、`--timeout`、`--language`                                                         |
| `monitor`、`repl`、`reset`       | `--port`、`--baud`、`--timeout`                                                                       |
| `fs cp/push/cat/ls/rm/mkdir`     | `--port`、`--baud`、`--timeout`。`fs cp`は`--recursive`にも対応します。                                |

すべてのコマンドの既定タイムアウトは20秒です。`run`と`exec`では実行中のプログラムから出力を受信するとタイムアウトを更新します。`flash`は`build`済みのカスタムUF2を使用し、`deploy`は書き込み前にそのUF2をビルドします。`--firmware`を省略した場合は、どちらも`{cache}/{language}-{language-version}-{board}.uf2`を使用します。

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
rpremote run examples/picoruby/education/01_blink/main.rb
```

PicoRubyのバージョンだけ一度変更する場合は、設定を変えずにCLIで上書きします。

```sh
rpremote setup --language-version 3.4.2
rpremote build --language-version 3.4.2 --firmware firmware/r2p2-picoruby-3.4.2-pico2.uf2
```
