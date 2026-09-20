# Mrbgems と Mrbgems.lock

`rpremote`は、PicoRubyの標準ビルド設定に含まれないmrbgemを、カスタムファームウェアへ追加できます。プロジェクト直下の`Mrbgems`に依存関係を定義し、`Mrbgems.lock`に解決済みのバージョンを記録します。

この仕組みではPicoRubyの展開済みソースや公式の`build_config`を直接編集しません。`rpremote build`が一時的なビルド設定を生成してgemを追加します。
R2P2のRuby例外ステータス用`PicoRubySourcePatch`だけは管理された例外としてソースへ適用します。詳細は[カスタムファームウェア](firmware.ja.md)を参照してください。

## 最初の手順

PicoRubyのソースを準備し、定義を検査してlockファイルを作成します。

```sh
rpremote setup
rpremote mrbgems check
rpremote mrbgems lock
```

続けてカスタムファームウェアをビルドします。

```sh
rpremote build --firmware firmware/r2p2-picoruby-latest-pico2.uf2
```

mrbgemを変更した後は、カスタムファームウェアを再ビルド・書き込みしてからサンプルを実行します。

```sh
rpremote build
rpremote bootsel
rpremote flash
rpremote run examples/picoruby/education/06_mpu6050/main.rb
```

`deploy PATH --build`は、このファームウェアのビルド、BOOTSEL移行、書き込みを自動で行います。`--build`を付けない`deploy PATH`は既存UF2を書き込みます。ボードの再接続後は、どちらも`PATH/lib/NAME`を`:/lib/NAME`へコピーし、`PATH/main.rb`を一時実行します。

buildと実行系コマンドは、プロジェクト直下の`Mrbgems.lock`を自動検出します。別のlockを使う場合は`--lockfile FILE`、lock済みgemを使わない場合は`--no-mrbgems`を指定します。`Mrbgems`があるのに`Mrbgems.lock`がない場合、buildはエラーになるため、先に`rpremote mrbgems lock`を明示的に実行してください。

## Mrbgems の書式

`Mrbgems`はRubyで記述します。先頭で対象VMを指定し、公開gemまたはローカルgemを追加します。

```ruby
# frozen_string_literal: true
vm :mrubyc
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
gem path: "../mrbgems/my-device"
```

### グループ

特定のファームウェア構成だけで必要なgemは、Bundler形式の`group`ブロックへまとめられます。グループ外のgemはすべての構成で共通です。

```ruby
gem path: "../mrbgems/device"

group :development, :test do
  gem path: "../mrbgems/debug-console"
end

group :production do
  gem github: "owner/telemetry", require: "telemetry"
end

gem path: "../mrbgems/test-helper", group: :test
```

`group:`オプションはgemをgroupブロックへ置く指定と同じで、配列も指定できます。グループはlock作成時に選択します。`--with`を省略すると、グループ外の共通gemだけをlockします。追加するグループは`--with`、除外するグループは`--without`へ指定し、どちらもカンマ区切りで複数指定できます。

```sh
rpremote mrbgems lock --with production
rpremote mrbgems lock --with production,test
rpremote mrbgems lock --with production --without test
```

lockにはグループ外の共通gemと、`--with`で指定したいずれかのグループに所属し、`--without`で指定したグループには所属しないgemだけを記録します。1つのgemが追加対象と除外対象の両方に所属する場合は、`--without`を優先します。`build`、`deploy`、`run`、`exec`はグループを再選択せず、lockに記録されたgemだけを使います。複数のfirmware構成を並行管理する場合はlockファイルを分けます。

### VMの指定

`vm`には`:mrubyc`または`:mruby`を一度だけ指定できます。指定に応じて、rpremoteはPicoRubyの版に適した公式ビルド設定を選びます。

| PicoRuby | `vm :mrubyc` | `vm :mruby` |
| -------- | ------------ | ----------- |
| 4系      | `femtoruby`  | `picoruby`  |
| 3系      | `picoruby`   | `microruby` |

たとえば`picoruby-ws2812-plus`はmruby/c向けのC拡張なので、`vm :mrubyc`を指定します。

### GitHubのgem

公開gemは`owner/repository`とbranchで指定します。

```ruby
gem github: "ksbmyk/picoruby-ws2812-plus", branch: "main"
```

明示的なcommitを指定することもできます。

```ruby
gem github: "owner/repository", commit: "40文字以上のコミットSHA"
```

branchを指定したgemは、初回の`lock`でGitHub上のコミットSHAへ解決されます。

### ローカルgem

ローカルgemは`Mrbgems`を基準とした相対パスで指定します。指定先には`mrbgem.rake`が必要です。

```ruby
gem path: "../mrbgems/my-device"
```

ローカルgemの内容はSHA-256で記録されます。`.git`、`build`、`tmp`配下のファイルはハッシュ計算から除外されます。

## requireの自動追加

ローカルgemの`mrbgem.rake`に`spec.require_name`がある場合、`lock`はその値を`require_name`として記録します。`rpremote run`、`exec`、`deploy`は記録済みの名前ごとに`require "名前"`を実行コードの先頭へ追加するため、アプリケーション側で同じ`require`を繰り返す必要はありません。

GitHub gemはlock作成時に`mrbgem.rake`を読めないため、名前を明示します。

```ruby
gem github: "owner/repository", branch: "main", require: "device_driver"
```

ファームウェアへ組み込むだけで、すべての`run`、`exec`、`deploy`に先行ロードしたくないgemには`auto_require: false`を指定します。アプリケーションは必要なときに明示的に`require`してください。複数のアプリケーションが同じファームウェアを共有する場合や、シンボル数・RAM使用量を抑えたい場合に使用します。

```ruby
gem path: "../mrbgems/my-application", auto_require: false
```

この設定でもgemはビルド対象になりますが、自動読み込みに使う`require_name`はlockへ記録しません。gem自体の`spec.require_name`は変わらないため、アプリケーションから明示的に読み込めます。省略時は従来どおり`auto_require: true`です。

## Mrbgems.lock

version 2の`Mrbgems.lock`はJSON形式で、選択したグループを`with`、除外したグループを`without`へ記録します。`gems`には共通gemと、`--with`で選択後に`--without`を適用したgemだけを保存します。GitHub gemは解決済みコミット、ローカルgemは内容のSHA-256と、取得できる場合は`require_name`を記録します。ローカルgemのchecksumはファイルを再帰的に対象とし、`.git`、`build`、`tmp`ディレクトリ以下は除外します。

```json
{
  "version": 2,
  "vm": "mrubyc",
  "with": ["production"],
  "without": ["test"],
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

`Mrbgems`と`Mrbgems.lock`は、カスタムファームウェアの構成として一緒にGitへコミットしてください。`rpremote build`はlockだけを読み、`Mrbgems`を評価せず、branchの先端を再解決せず、lockを書き換えません。ローカルgemはビルド前にlock済みSHA-256との一致も検証します。対応するcacheがない場合、PicoRubyのbuild toolが固定済みcommitのrepositoryを取得したりSDKを準備したりすることがあります。

## コマンド

```sh
# 定義とローカルgemの構成を検査する
rpremote mrbgems check
# 定義とlockに記録されている依存関係を表示する
rpremote mrbgems list
# 共通gemをlockする。既存のGitHub commitは再利用する
rpremote mrbgems lock
# 共通gemとproduction gemをlockする
rpremote mrbgems lock --with production --without test
# 選択したGitHub branchを再解決してlockを更新する
rpremote mrbgems update --with production --without test
```

選択した依存gemを最新版へ進めたいときだけ`rpremote mrbgems update`を実行し、変更された`Mrbgems.lock`を確認してコミットしてください。`lock`はそのlockへ収録するローカルgemを検証し、`check`は未選択groupを含む定義内の全ローカルgemを検証します。version 1のlockは利用前に再生成が必要です。

定義ファイルまたはlockファイルの場所を明示して検査・更新することもできます。

```sh
rpremote mrbgems check --file config/Mrbgems
rpremote mrbgems lock --file config/Mrbgems --lockfile config/production.lock --with production
rpremote build --lockfile config/production.lock
```

## Gemfile / Gemfile.lockとの仕様差

MrbgemsはBundlerのDSL表現を参考にしていますが、groupとlockの意味は同じではありません。Bundlerは原則として全groupを1つのlockへ解決するのに対し、Mrbgemsは`--with`で選択し、`--without`で除外したgroupだけをlockへ確定します。

| 観点                     | Gemfile / Gemfile.lock                                         | Mrbgems / Mrbgems.lock                                                               |
| ------------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 主な用途                 | CRubyなどで実行するgemの取得とインストール                     | PicoRuby firmwareへ組み込むmrbgemの選択と固定                                        |
| 定義ファイル             | gem名、version制約、source、platform、groupなどを記述          | GitHubまたはpath、branch、commit、VM、require、groupなどを記述                       |
| lockの対象               | Gemfileに由来する全groupと推移的依存関係                       | group未所属と`--with`で選択され、`--without`で除外されなかった直接指定mrbgem         |
| groupの役割              | install、setup、requireの対象を環境ごとに切り替える            | lockへ収録し、firmwareへ組み込むmrbgemを決定する                                     |
| group情報の保存          | Gemfile.lockには通常group構造を保存せず、Gemfile側に残す       | top-levelの`with`と`without`、各entryの`groups`へ保存する                            |
| version解決              | version制約からgem versionと推移的依存関係を解決する           | GitHub commitまたはpath内容のSHA-256を固定する                                       |
| platform情報             | Ruby platform、Ruby version、Bundler versionなどを扱う         | mrubyまたはmrubycのVMを扱う                                                          |
| lock利用時の定義ファイル | groupや`require`設定のためGemfileも利用する                    | buildはMrbgemsを評価せず、Mrbgems.lockだけを利用する                                 |
| lock不在時               | `bundle install`が通常は依存解決してGemfile.lockを生成する     | Mrbgemsが存在する場合、buildは失敗して明示的なlockを要求する                         |
| lock更新                 | installや`bundle lock --update`などで解決結果を更新できる      | `mrbgems lock`は既存commitを維持し、`mrbgems update`が再解決する                     |
| build/install時の通信    | 未取得gemのdownloadや再解決で通信する場合がある                | buildはbranchを再解決せずlockも変更しない。cacheがなければ固定済みrepositoryやSDKをbuild toolが取得する場合がある |
| local依存関係            | path gemのversionと依存関係を扱う                              | `.git`、`build`、`tmp`を除くpath内ファイルのSHA-256を検証する                       |
| 自動読み込み             | `require`指定はGemfile側にあり、`Bundler.require`がgroupを選ぶ | `require_name`と`auto_require`をlock entryへ保存し、lock済みgemだけを自動requireする |

### groupの違い

Gemfileでは、groupは依存関係をlockから除外する仕組みではありません。

```ruby
gem "rack"

group :development, :test do
  gem "rspec"
end
```

Bundlerは`without`などでインストール対象を除外しても、原則として`rack`と`rspec`を含む全依存関係を1つのGemfile.lockへ解決します。これにより、環境ごとに異なるversion解決が発生することを防ぎます。Gemfile.lock自体には「rspecがdevelopmentとtestに所属する」という情報を通常は保存しません。

Mrbgemsでは、groupをfirmware構成の選択単位として使用します。

```ruby
gem github: "example/common"
gem path: "mrbgems/production", group: :production
gem path: "mrbgems/debug", group: [:production, :test]
```

```sh
rpremote mrbgems lock --with production --without test
```

この操作では`common`と`production`だけをMrbgems.lockへ記録します。`debug`はproductionにも所属しますが、除外側のtestにも所属するため記録しません。`--with production`を付けずにlockした場合は`common`だけを記録します。したがって、Mrbgems.lockは「全候補の共通解決結果」ではなく「1つのfirmware構成として選択済みの入力」です。

### lock内容の違い

Gemfile.lockは、直接指定したgemだけでなく、そのgemが依存するgemも含む完全な依存グラフを記録します。各gemについて解決済みversionを保存し、source、platform、checksumなども必要に応じて保存します。

Mrbgems.lockは、Mrbgemsで直接指定された選択済みmrbgemを記録します。RubyGemsのversion制約や推移的依存グラフは解決せず、GitHub依存はcommit、path依存は内容のSHA-256で固定します。mrbgem内部のbuild依存関係をBundlerのように再帰的にlockすることは、この仕様の対象外です。

### 消費方法の違い

BundlerはGemfileとGemfile.lockを組み合わせて利用します。Gemfileからgroup、platform、`require`などの宣言を読み、Gemfile.lockから解決済みversionを得ます。通常の`bundle install`は、Gemfileの変更に応じてlockを更新することがあります。

`rpremote build`はMrbgemsを評価せず、Mrbgems.lockだけを入力にします。group選択、commit解決、require情報の取得、lock更新をbuild中に行いません。これにより、同じMrbgems.lockから同じbuild overlayを生成し、build時にDSLコードを実行しない構成にしています。

### コマンド対応

| Bundler                                    | rpremote                                 | 備考                                                           |
| ------------------------------------------ | ---------------------------------------- | -------------------------------------------------------------- |
| `bundle lock`                              | `rpremote mrbgems lock`                  | lockを作成するが、Mrbgems側はgroup未所属だけを既定で選ぶ       |
| `bundle config set --local with GROUPS`    | `rpremote mrbgems lock --with GROUPS`    | Mrbgems側はlock収録対象そのものを追加する                      |
| `bundle config set --local without GROUPS` | `rpremote mrbgems lock --without GROUPS` | Mrbgems側は一致するgemをlock収録対象から除外する               |
| `bundle lock --update`                     | `rpremote mrbgems update`                | 解決済みversionまたはcommitを更新する                          |
| `bundle install`                           | `rpremote build`                         | Bundlerはinstall、rpremoteはlock済みmrbgemをfirmwareへ組み込む |
| `Bundler.require(:group)`                  | lockに基づく自動require                  | rpremoteは実行時にgroupを再選択しない                          |

### 意図するトレードオフ

- Gemfile.lock方式は、1つのlockで複数環境を扱え、全group間でversion解決を統一できます。
- Mrbgems.lock方式は、firmwareへ入るものだけがlockに現れるため、組み込み内容を確認しやすく、buildをlockだけで再現できます。
- development用とproduction用のfirmware構成を同時に保持する場合は、それぞれの`--with`と`--without`で別のlockファイルを生成・管理する必要があります。
- group選択を変更して同じMrbgems.lockを上書きすると、以前の構成はそのlockから失われます。複数構成を並行管理する場合は`--lockfile`でファイルを分けてください。

## ビルド時に生成されるファイル

`rpremote build`と`rpremote deploy`のビルド段階は、次のような生成物をプロジェクト内に作ります。

- `build/mrbgems/<fingerprint>/build_config.rb`: 元の公式設定と依存gemを組み合わせた一時設定
- `build/`: CMakeなどの中間生成物
- `firmware/*.uf2`: `--firmware`で指定した完成UF2。未指定時は`{cache}/{language}-{language_version}-{board}.uf2`に保存します。

fingerprintには`Mrbgems.lock`と元のビルド設定の内容が反映されます。設定やlock済み依存関係を変更したビルドは、既存の中間生成物と区別されます。

中間生成物だけを削除するには、次を実行します。`firmware/`、`Mrbgems`、`Mrbgems.lock`は削除されません。

```sh
rpremote build clean
```
