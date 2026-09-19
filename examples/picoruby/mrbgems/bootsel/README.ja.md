# picoruby-bootsel

[English](README.md)

`picoruby-bootsel`は、RP2040およびRP2350向けPicoRubyファームウェアへ`Machine.enter_bootsel`を追加するmrbgemです。呼び出すと、ボードをROMのUSB BOOTSELモードへ直ちに再起動します。

## ファームウェアへ組み込む

ファームウェアで使うPicoRubyのビルド設定へ、このmrbgemを追加します。

```ruby
vm :mrubyc
gem path: "path/to/picoruby-bootsel"
```

このgemはファームウェアへの組み込みが必要です。実装はネイティブコードからPico SDKのブートROMを呼び出すため、ボードのファイルシステムから`bootsel.rb`を読み込むだけでは動作しません。

## 使い方

```ruby
require "bootsel"

Machine.enter_bootsel
```

この呼び出しからは戻りません。シリアル接続が切断され、ボードは`RPI-RP2`または`RP2350`のUSB BOOTSELボリュームとして再認識されます。

## API

| メソッド | 説明 |
| --- | --- |
| `Machine.enter_bootsel` | RP2040またはRP2350ボードをUSB BOOTSELモードへ再起動します。引数はなく、呼び出しからは戻りません。 |

## 安全上の注意と制限

- `Machine.enter_bootsel`はボードを直ちにリセットします。呼び出す前に、ファイルシステムへの書き込みなどの永続化処理を完了してください。
- BOOTSELモードでは、接続したホストからファームウェアを書き換えられます。信頼できるアプリケーションからのみ呼び出してください。
- RP2040およびRP2350向けファームウェアを対象とします。POSIXビルドでは`NotImplementedError`を発生させます。

## ライセンス

MIT Licenseです。詳細は[LICENSE](LICENSE)を参照してください。
