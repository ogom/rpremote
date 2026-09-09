# ハードウェアと安全上の注意

[English](hardware.md)

## 安全上の注意

572個のLEDには、LEDの仕様と配線に合う外部電源を使用してください。Raspberry Pi Pico 2（以降、Pico 2）のGPIO、`3V3(OUT)`、`VBUS`からLEDへ給電しないでください。Pico 2とLED用電源のGNDは共通にし、配線を変更する前に両方の電源を切ってください。

572個のLEDの輝度はイルミネーションの[`config.rb`](../mrbgems/daisenkofun-illumination/mrblib/daisenkofun-illumination/config.rb)にある`BRIGHTNESS_PERCENT`で10%に設定しています。8個の状態LEDは`Oximeter::Config::LED_BRIGHTNESS`（12）を使います。どちらの値も、上げる前に電源容量、電圧降下、配線、コネクター、温度を確認してください。

## 配線

### 572個のイルミネーションLED

| WS2812B | 接続先 |
| --- | --- |
| DIN | Pico 2のGP14（物理19番、`ws2812_pin`） |
| GND | Pico 2とLED用外部電源の共通GND |
| VDD | LEDの仕様に合う外部電源 |

5 V動作のLEDが3.3 VのDIN信号を安定して認識しない場合は、適切なレベルシフターを使用してください。

### MAX30102

MAX30102はI2Cで接続します。

| MAX30102 | Raspberry Pi Pico 2／`Application::Config` |
| --- | --- |
| VIN | 使用するブレークアウトボードの対応電圧 |
| GND | GND |
| SDA | GP16／`i2c_sda_pin` |
| SCL | GP17／`i2c_scl_pin` |

ブレークアウトボードの対応入力電圧と、I2Cレベル変換の有無を確認してください。

### PWMブザー

WS2812、I2C、SPI、ブザーのPINは[`main.rb`](../main.rb)の`Daisenkofun::Application::Config`で設定します。`:combined`の音楽出力は、教材03_speakerと同じPWMブザーの信号線をGP18（`buzzer_pin`）、GNDを共通GNDへ接続します。既定のdutyは3%です。`buzzer_pin`で信号ピンを変更でき、`nil`で無音になります。

### 8個の状態表示LED

Oximeterの状態表示用WS2812/NeoPixelはSPIで接続します。

| WS2812/NeoPixel | Raspberry Pi Pico 2／`Application::Config` |
| --- | --- |
| DIN | GP3（`RP2040_SPI0`のCOPI、`spi_copi_pin`） |
| GND | Pico 2とLED用外部電源の共通GND |
| LED電源 | 8個のLEDに対応できる外部電源 |

GP2（`spi_sck_pin`）はSPI SCKとして設定されますが、LEDには接続しません。GPIOからLEDへ給電しないでください。SPI unitは`RP2040_SPI0`のままで、`Application::Config`が変更するのはSCK/COPIのPINです。
