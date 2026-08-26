# picoruby-mpu6050

[English](README.md)

`picoruby-mpu6050`は、MPU6050の3軸加速度と3軸角速度を1回のI2Cバーストで読み取ります。
公開API、レジスタ設定、単位変換はRubyで実装し、14バイトのセンサーフレームから符号付き16ビット値への変換はC拡張で実装します。

## mrbgemを追加する

プロジェクトの`Mrbgems`へローカルgemを追加します。このリポジトリには、次の定義が含まれています。

```ruby
vm :mrubyc
gem path: "examples/picoruby/mrbgems/mpu6050"
```

gemを変更した後は、lockを更新してカスタムファームウェアをビルドします。

```sh
rpremote mrbgems lock
rpremote build --language picoruby --language-version 4.0.3 --board pico2
```

## 使い方

```ruby
require "i2c"
require "mpu6050"

i2c = I2C.new(
  unit: :RP2040_I2C0,
  sda_pin: 16,
  scl_pin: 17,
  frequency: 400_000
)
sensor = MPU6050.new(i2c: i2c)

sample = sensor.read
ax, ay, az = sample[:acceleration] # g
gx, gy, gz = sample[:gyroscope]    # 度/秒
temperature = sample[:temperature] # ℃
```

`read`は`ACCEL_XOUT_H`（`0x3B`）から14バイトを、repeated startを使う1回のI2Cトランザクションで読み取ります。加速度、温度、角速度は同じセンサーフレームの値です。

## 配線

- VCC -> 3V3(OUT)
- GND -> GND
- SDA -> GP16
- SCL -> GP17
- AD0 -> GNDでアドレス`0x68`、3V3で`0x69`

GPIOとI2C信号は3.3 V専用です。

## API

| メソッド                                                                  | 説明                                              |
| ------------------------------------------------------------------------- | ------------------------------------------------- |
| `MPU6050.new(i2c:, address: 0x68, accel_range: :g2, gyro_range: :dps250)` | センサーを確認し、起動して設定します。            |
| `connected?`                                                              | `WHO_AM_I`がMPU6050を示すか返します。             |
| `who_am_i`                                                                | `WHO_AM_I`レジスタの生値を返します。              |
| `read`                                                                    | 単位変換した加速度、温度、角速度を1回分返します。 |
| `read_raw`                                                                | 同じサンプルを符号付きレジスタ値で返します。      |
| `motion6`                                                                 | `[ax, ay, az, gx, gy, gz]`をgと度/秒で返します。  |
| `motion6_raw`                                                             | 同じ6軸を符号付きレジスタ値で返します。           |
| `acceleration`                                                            | `[ax, ay, az]`をgで読み取ります。                 |
| `gyroscope`                                                               | `[gx, gy, gz]`を度/秒で読み取ります。             |
| `temperature`                                                             | 温度を℃で読み取ります。                           |

加速度と角速度を同じ時点の値として使う場合は`read`を使用してください。単独のアクセサーは、呼び出すたびに新しい読み取りを開始します。

加速度レンジは`:g2`、`:g4`、`:g8`、`:g16`、角速度レンジは`:dps250`、`:dps500`、`:dps1000`、`:dps2000`に対応します。既定値はElectronicCatsの初期化と同じ±2 g、±250度/秒、X軸ジャイロPLLクロックです。

## 対象範囲

このサンプルgemは、6軸の直接読み取り、温度、レンジ選択、2つのI2Cアドレス、デバイス識別に対応します。DMP、FIFO、割り込み、オフセット、キャリブレーションは対象外です。

このセンサーをWS2812Bとブザーに組み合わせる有限回の実機サンプルは[06_mpu6050](../../education/06_mpu6050/README.ja.md)を参照してください。

## ライセンス

MIT Licenseです。詳細は[LICENSE](LICENSE)を参照してください。
