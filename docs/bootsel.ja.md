# BOOTSELモードへ移行する

`rpremote bootsel`は、実行中のR2P2ファームウェアへRaspberry Pi Pico 2をUSB BOOTSELモードへ再起動するよう要求し、`RP2350`ボリュームの出現を待ちます。ファームウェアを書き換える前に使います。

## 準備

ボード上で実行するファームウェアには、プロジェクトルートの`Mrbgems`にあるローカル`picoruby-bootsel` mrbgemを組み込む必要があります。初回は物理BOOTSELボタンを押しながら、次の手順でビルドと書き込みを行ってください。

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

初回のインストール時と、R2P2が利用できない場合の復旧時は、物理BOOTSELボタンが必要です。

## BOOTSELモードへ移行する

```sh
rpremote bootsel
```

このコマンドは、PicoModem経由で一時Rubyスクリプトを転送し、R2P2シェルから起動します。スクリプトは`bootsel`を`require`して`Machine.enter_bootsel`を呼び出します。シリアルデバイスが切断され、たとえば次のようにマウントされたBOOTSELボリュームを表示します。

```text
BOOTSEL ready: /Volumes/RP2350
```

続けて、対象のUF2を書き込んでください。

```sh
rpremote flash --firmware firmware/picoruby-latest-pico2.uf2
```

PicoRubyソースのパッチや、R2P2に組み込みの`/bin/bootsel`コマンドは使用しません。

## `rpremote exec`から呼び出す

このプロジェクトの`Mrbgems`でビルドしたファームウェアでは、`rpremote exec`が渡されたコードの前に`bootsel`を自動で`require`します。APIを直接呼び出してください。

```sh
rpremote exec 'Machine.enter_bootsel'
```

依存関係を明示する場合は、次のように実行します。

```sh
rpremote exec 'require "bootsel"; Machine.enter_bootsel'
```

`Machine.enter_bootsel`はR2P2シェルがプロンプトを返す前にシリアルデバイスを切断します。そのため、リセット要求後に`rpremote exec`が接続切断エラーを表示することは正常です。BOOTSELボリュームの出現まで待つ場合は、`rpremote bootsel`を使用してください。

## 外部フラッシュメモリをリセットする

```sh
rpremote bootsel --reset-flash-memory
```

このコマンドはBOOTSELモードへの移行後、ユニバーサルリセットUF2を書き込みます。Pico 2の外部フラッシュメモリ全体が永続的に消去され、R2P2ファームウェアと保存済みデータも失われます。完了後は`rpremote flash`でR2P2を再インストールしてください。

## トラブルシューティング

`rpremote bootsel`でBOOTSELモードへ移行できない場合は、物理BOOTSELボタンを押しながらボードを接続し、現在の`Mrbgems`でビルドしたUF2を書き込んでください。R2P2ボードが複数接続されている場合は、`rpremote ports`で確認し、`--port`を指定してください。
