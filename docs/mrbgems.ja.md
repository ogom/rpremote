# Mrbgems と Mrbgems.lock

`rpremote` は、PicoRubyの標準ビルド設定に含まれないmrbgemを、
カスタムファームウェアへ追加できます。プロジェクト直下の `Mrbgems` に依存関係を
定義し、`Mrbgems.lock` に解決済みのバージョンを記録します。

この仕組みではPicoRubyの展開済みソースや公式の `build_config` を直接編集しません。
`rpremote build` が一時的なビルド設定を生成してgemを追加します。

## 最初の手順

PicoRubyのソースを準備し、定義を検査してlockファイルを作成します。

```sh
rpremote setup --language picoruby --language-version 4.0.3 --cache firmware
rpremote mrbgems check
rpremote mrbgems lock
```

続けてカスタムファームウェアをビルドします。

```sh
rpremote build \
  --language picoruby \
  --language-version 4.0.3 \
  --board pico2 \
  --firmware firmware/r2p2-picoruby-4.0.3-pico2.uf2
```

プロジェクト直下の `Mrbgems` は自動検出されます。別の定義ファイルを使う場合は
`--mrbgems FILE`、追加gemを使わずにビルドする場合は `--no-mrbgems` を指定します。

## Mrbgems の書式

`Mrbgems` はRubyで記述します。先頭で対象VMを指定し、公開gemまたはローカルgemを
追加します。

```ruby
# frozen_string_literal: true

vm :mrubyc

gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

### VMの指定

`vm` には `:mrubyc` または `:mruby` を一度だけ指定できます。指定に応じて、
rpremoteはPicoRubyの版に適した公式ビルド設定を選びます。

| PicoRuby | `vm :mrubyc` | `vm :mruby` |
| -------- | ------------ | ----------- |
| 4系      | `femtoruby`  | `picoruby`  |
| 3系      | `picoruby`   | `microruby` |

たとえば `picoruby-ws2812-plus` はmruby/c向けのC拡張なので、
`vm :mrubyc` を指定します。

### GitHubのgem

公開gemは `owner/repository` とbranchで指定します。

```ruby
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
```

明示的なcommitを指定することもできます。

```ruby
gem github: "owner/repository", commit: "40文字以上のコミットSHA"
```

branchを指定したgemは、初回の `lock` でGitHub上のcommit SHAへ解決されます。

### ローカルgem

ローカルgemは `Mrbgems` を基準とした相対パスで指定します。指定先には
`mrbgem.rake` が必要です。

```ruby
gem path: "../mrbgems/my-device"
```

ローカルgemの内容はSHA-256で記録されます。`.git`、`build`、`tmp` 配下のファイルは
ハッシュ計算から除外されます。

## Mrbgems.lock

`Mrbgems.lock` はJSON形式です。GitHub gemは解決済みcommit、ローカルgemは内容の
SHA-256を記録します。

```json
{
  "version": 1,
  "vm": "mrubyc",
  "gems": [
    {
      "type": "github",
      "source": "ksbmyk/picoruby-ws2812-plus",
      "branch": "main",
      "commit": "16699f8eb163df3fad86cfe826590bf890d0bb58"
    }
  ]
}
```

`Mrbgems` と `Mrbgems.lock` は、カスタムファームウェアの構成として一緒にGitへ
コミットしてください。これにより、branchの先頭が変わっても同じGitHub gemのcommitを
使ってビルドできます。

## コマンド

```sh
# 定義とローカルgemの構成を検査する
rpremote mrbgems check

# 定義とlockに記録されている依存関係を表示する
rpremote mrbgems list

# lockを作成または更新する。既存のGitHub commitは再利用する
rpremote mrbgems lock

# GitHubのbranchを再解決してlockを更新する
rpremote mrbgems update
```

`build` は既存の `Mrbgems.lock` に記録されたGitHub commitを再利用します。
依存gemを最新版へ進めたいときだけ `rpremote mrbgems update` を実行し、変更された
`Mrbgems.lock` を確認してコミットしてください。

定義ファイルまたはlockファイルの場所を明示して検査・更新することもできます。

```sh
rpremote mrbgems check --file config/Mrbgems
rpremote mrbgems lock --file config/Mrbgems --lockfile config/Mrbgems.lock
```

## ビルド時に生成されるファイル

`rpremote build` は、次のような生成物をプロジェクト内に作ります。

- `build/mrbgems/<fingerprint>/build_config.rb`: 元の公式設定と依存gemを組み合わせた一時設定
- `build/`: CMakeなどの中間生成物
- `firmware/*.uf2`: `--firmware` で指定した完成UF2。未指定時は
  `{cache}/{language}-{language_version}-{board}.uf2` に保存

fingerprintには `Mrbgems`、`Mrbgems.lock`、元のビルド設定の内容が反映されます。設定や
依存関係を変更したビルドは、既存の中間生成物と区別されます。

中間生成物だけを削除するには、次を実行します。`firmware/`、`Mrbgems`、
`Mrbgems.lock` は削除されません。

```sh
rpremote build clean
```
