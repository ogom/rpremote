# 09 ローカルmrbgemとPicoModem DFU

[English](README.md)

ローカルmrbgemを組み込んだR2P2ファームウェアを一度書き込み、そのmrbgemを利用するアプリだけをPicoModem DFUで更新する例です。
mrbgemとアプリを分けることで、共通処理はファームウェアへ組み込み、動作や設定はBOOTSELボタンを押さずに短いサイクルで更新できます。

## 仕組み

- `MyGems`はファームウェアへ組み込まれ、オンボードLEDのGPIO操作を提供します。
- `app_v1.rb`と`app_v2.rb`はDFUのA/Bスロットへ保存され、組み込み済みの`MyGems`を呼び出します。
- アプリだけを変更した場合は、ファームウェアの再ビルドやUF2の再書き込みは不要です。
- `MyGems`自体を変更した場合は、mrbgemのlock、ファームウェアの再ビルド、UF2の再書き込みが必要です。

## 1. mrbgemを組み込む

プロジェクト直下の`Mrbgems`には、ローカルmrbgemとして`examples/picoruby/mrbgems/my_gems`が定義されています。
`08_my_gems`で同じファームウェアを書き込み済みの場合、この手順は不要です。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
rpremote flash --mount /Volumes/RP2350
```

## 2. v1をDFUで配備する

v1を非アクティブ側のDFUスロットへ転送します。この操作だけではアプリは起動しません。

```sh
rpremote dfu app examples/picoruby/education/09_my_gems_dfu/app_v1.rb
```

次にR2P2を再起動します。`MyGems`がGPIOを初期化し、オンボードLEDをゆっくり3回点滅させます。

```sh
rpremote reset
rpremote dfu status
```

`rpremote dfu status`に`confirmed rb`と`boot_count=0/3`が表示されれば、v1の起動確認は成功です。

## 3. アプリだけをv2へ更新する

`MyGems`は変更せず、短い2回点滅を3セット繰り返すv2へ更新します。mrbgemのlock、ファームウェアの再ビルド、UF2の再書き込みは不要です。

```sh
rpremote dfu app examples/picoruby/education/09_my_gems_dfu/app_v2.rb
```

次にR2P2を再起動し、更新後の動作と状態を確認します。

```sh
rpremote reset
rpremote dfu status
```

LEDが2回ずつ点滅し、`confirmed rb`と`boot_count=0/3`が表示されれば更新成功です。

## 開発サイクル

- `app_v1.rb`や`app_v2.rb`の変更: `rpremote dfu app`と`rpremote reset`で更新します。
- `examples/picoruby/mrbgems/my_gems`の変更: `rpremote mrbgems lock`、`rpremote build`、`rpremote flash`でファームウェアを更新します。

DFUのA/Bスロットとロールバックは[07 PicoModem DFU](../07_dfu/README.ja.md)を、ローカルmrbgemの基本は[08 ローカルmrbgem](../08_my_gems/README.ja.md)を参照してください。
