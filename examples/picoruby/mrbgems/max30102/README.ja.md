# picoruby-max30102

[English](README.md)

`picoruby-max30102`はMAX30102をI2Cで設定し、FIFOから赤色光と赤外光の18ビット値を同時に読み取るmrbgemです。デバイス設定とレジスター操作はRuby、6バイトのFIFOフレームの復号はC拡張で実装します。

## mrbgemを追加する

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/max30102"
```

```sh
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
```

## 使い方

```ruby
require "i2c"
require "max30102"

i2c = I2C.new(unit: :RP2040_I2C0, sda_pin: 16, scl_pin: 17, frequency: 400_000)
sensor = MAX30102.new(i2c: i2c)

if sensor.sample_available?
  sample = sensor.read
  puts "red=#{sample[:red]}, ir=#{sample[:ir]}"
end
```

既定値は参照実装と同じ、FIFOの4サンプル平均、ロールオーバー無効、SpO2モード、ADCレンジ4096 nA、毎秒100サンプル、パルス幅411 us、赤色・赤外LED振幅`0x24`です。初期化時にFIFOを空にします。

## 配線

- VIN -> 使用するMAX30102ブレークアウトボードの対応電圧
- GND -> GND
- SDA -> GP16
- SCL -> GP17

MAX30102 IC本体は低電圧で動作します。Picoへ接続する前に、ブレークアウトボードに必要な電源回路とI2Cレベル変換が実装されていることを確認してください。

## API

| メソッド                                 | 説明                                                           |
| ---------------------------------------- | -------------------------------------------------------------- |
| `MAX30102.new(i2c:, ...)`                | センサーを確認し、リセットして設定します。                     |
| `connected?`、`part_id`、`revision_id`   | デバイス識別情報を確認します。                                 |
| `available_samples`、`sample_available?` | FIFOの未読データを確認します。                                 |
| `read`、`read_fifo`                      | 1回分の18ビット値を`{ red:, ir: }`で返します。                 |
| `clear_fifo`                             | FIFOの書込み、オーバーフロー、読取りポインターを初期化します。 |
| `temperature`                            | センサー内部温度を℃で返します。                                |
| `shutdown`、`wake`、`reset`              | センサーの電源状態を操作します。                               |

コンストラクターでは`fifo_average:`、`sample_rate:`、`pulse_width:`、`adc_range:`、`red_led_amplitude:`、`ir_led_amplitude:`を指定できます。

## 対象範囲と安全性

このドライバーは光学センサーの生値を返します。心拍数やSpO2の算出、指の装着判定、体動ノイズ除去、医療用途の測定には対応しません。心拍数の推定には、装着方法と用途に合わせた信号のフィルタリング、ピーク検出、時間計測、検証が必要です。

レジスター定義と既定の設定は、公式の[MAX30102データシート](https://www.analog.com/media/en/technical-documentation/data-sheets/max30102.pdf)に基づきます。

## ライセンス

MIT Licenseです。詳細は[LICENSE](LICENSE)を参照してください。
