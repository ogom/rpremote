# ハードウェアと安全上の注意

[English](hardware.md)

## 安全上の注意

572個のLEDには、LEDの仕様と配線に合う外部電源を使用してください。Raspberry Pi Pico 2（以降、Pico 2）のGPIO、`3V3(OUT)`、`VBUS`からLEDへ給電しないでください。Pico 2とLED用電源のGNDは共通にし、配線を変更する前に両方の電源を切ってください。

輝度は[`config.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/config.rb)の`BRIGHTNESS_PERCENT`で設定します。輝度を上げる前に、電源容量、電圧降下、配線、コネクター、温度を確認してください。

## 配線

### 572個のイルミネーションLED

| WS2812B | 接続先 |
| --- | --- |
| DIN | Pico 2のGP14（物理19番） |
| GND | Pico 2とLED用外部電源の共通GND |
| VDD | LEDの仕様に合う外部電源 |

5 V動作のLEDが3.3 VのDIN信号を安定して認識しない場合は、適切なレベルシフターを使用してください。

### MAX30102

MAX30102はI2Cで接続します。

| MAX30102 | Raspberry Pi Pico 2 |
| --- | --- |
| VIN | 使用するブレークアウトボードの対応電圧 |
| GND | GND |
| SDA | GP16 |
| SCL | GP17 |

ブレークアウトボードの対応入力電圧と、I2Cレベル変換の有無を確認してください。

### 8個の状態表示LED

Oximeterの状態表示用WS2812/NeoPixelはSPIで接続します。

| WS2812/NeoPixel | Raspberry Pi Pico 2 |
| --- | --- |
| DIN | GP3（`RP2040_SPI0`のCOPI） |
| GND | Pico 2とLED用外部電源の共通GND |
| LED電源 | 8個のLEDに対応できる外部電源 |

GP2はSPI SCKとして設定されますが、LEDには接続しません。GPIOからLEDへ給電しないでください。
