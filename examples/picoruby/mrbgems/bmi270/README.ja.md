# picoruby-bmi270

[English](README.md)

Bosch BMI270をI2Cで初期化し、3軸加速度と3軸ジャイロを同じフレームとして読み取るmrbgemです。Rubyが初期化、レジスター操作、単位変換を担当し、C拡張がBosch設定データの提供と12バイトのリトルエンディアンデータの復号を担当します。

## 初期化

BMI270の初期化にはBoschの8192バイト設定ファイルが必要です。このgemには、リポジトリのSpresense実装で使っている設定データをBoschのBSD-3-Clause Licenseに基づいて組み込んでいます。組み込みデータを差し替える場合に限り、8192バイトのStringを`configuration:`へ渡します。

```ruby
require "bmi270"
require "i2c"

i2c = I2C.new(unit: :RP2040_I2C0, frequency: 400_000, sda_pin: 16, scl_pin: 17)
sensor = BMI270.new(i2c: i2c, address: 0x68, accel_range: :g2, gyro_range: :dps2000, odr: :hz100)
sample = sensor.read
```

上の例では、SDAをGP16、SCLをGP17へ接続します。400 kHzで、BMI270のプライマリーアドレス`0x68`とセカンダリーアドレス`0x69`に対応します。

加速度レンジは±2/4/8/16 g、ジャイロレンジは±125/250/500/1000/2000 degree/sに対応します。ODRは`:hz25`から`:hz1600`まで指定できます。既定値は参照実装と同じ±2 g、±2000 degree/s、100 Hzです。`read`は加速度をg、ジャイロをdegree/s、温度を摂氏で返します。ジャイロのraw X値には、BMI270のZX軸交差感度係数による補正を適用します。

FIFO、割り込み、歩数・活動認識、補助磁気センサー、CRTキャリブレーションは未対応です。絶対yawには磁気センサーと、この6軸ドライバーの外側でのセンサーフュージョンが必要です。

## ライセンス

mrbgemコードはMIT Licenseです。組み込んだBosch設定データには[LICENSE-BOSCH](LICENSE-BOSCH)（BSD-3-Clause License）が適用されます。設定データは公式の[Bosch BMI270 SensorAPI](https://github.com/boschsensortec/BMI270_SensorAPI)に基づきます。
