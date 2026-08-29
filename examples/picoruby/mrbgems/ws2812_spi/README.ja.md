# picoruby-ws2812_spi

[English](README.md)

`picoruby-ws2812_spi`は、SPIのCOPIピンを使ってWS2812互換のアドレス指定RGB LEDを制御するmrbgemです。画素管理とSPI送信はRuby、RGBから参照実装と同じGRB波形バイトへの変換はC拡張で実装します。

クラス名は`WS2812SPI`です。リポジトリのPIO/RMT版`WS2812` gemと同時に組み込んでも、クラス名が衝突しません。

## mrbgemを追加する

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/ws2812_spi"
```

```sh
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
```

## 使い方

```ruby
require "spi"
require "ws2812_spi"

spi = SPI.new(
  unit: :RP2040_SPI0,
  frequency: WS2812SPI::FREQUENCY,
  sck_pin: 2,
  copi_pin: 3,
  mode: WS2812SPI::MODE
)
leds = WS2812SPI.new(spi: spi, count: 8)
leds.set_rgb(0, 255, 0, 0)
leds.set_hex(1, 0x00FF00)
leds.show

# 最後のLEDだけを点灯します。
leds.one(7)
```

LEDのDIN信号をSPIのCOPIピンへ接続します。この例ではGP3です。GP2はSPIのSCKとして設定しますが、LEDストリップへは接続しません。チップセレクトとCIPOは使用しません。

タイミングは、正確な8 MHz、モード3、MSB firstのSPI設定を前提にします。WS2812の1ビットをSPIの1バイトに変換し、0には`0x60`、1には`0x7c`を使用します。送信フレームの先頭と末尾には、それぞれ80バイト（80 us）の0を置いてリセットとラッチを確保します。エンコード済みフレームは再利用されるため、`show`ではメモリを割り当てず、固定の待ち時間もありません。

1フレームのSPI送信時間は`160 + 24 * LED数` usです。例えば8個では352 us、64個では1,696 usです。

## API

| メソッド | 説明 |
| --- | --- |
| `WS2812SPI.new(spi:, count:)` | 全画素が消灯したストリップを作成します。 |
| `set_rgb(index, red, green, blue)` | 0〜255のRGB値で1画素を設定します。 |
| `set_hex(index, rgb)` | `0xRRGGBB`形式で1画素を設定します。 |
| `get_rgb(index)` | 1画素を`[red, green, blue]`で返します。 |
| `fill(red, green, blue)` | 全画素を設定します。まだ送信しません。 |
| `show` | 現在の画素を変換して送信します。 |
| `clear` | 全画素を消灯して送信します。 |
| `one(index, rgb = 0xFFFFFF)` | 全LEDを消灯後、0始まりの指定LEDだけを点灯して送信します。 |

## 電気的な注意

LED数に合った電源を使用し、LEDとPicoのGNDを共通にしてください。GPIOピンからLEDストリップへ給電しないでください。LEDを5 Vで駆動する場合は、3.3 Vから5 Vへのロジックレベル変換を推奨します。明るさと消費電流の制限はアプリケーション側で行います。

## ライセンス

MIT Licenseです。詳細は[LICENSE](LICENSE)を参照してください。
