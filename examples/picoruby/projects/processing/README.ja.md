# Processing用IMU姿勢モニター

[English](README.md)

このプロジェクトは、6軸IMUを読み取り、共通のCSVプロトコルでProcessingへ送信します。ローカルの[`picoruby-mpu6050`](../../mrbgems/mpu6050/README.ja.md)と[`picoruby-bmi270`](../../mrbgems/bmi270/README.ja.md)のI2C gemに対応します。姿勢推定とジェスチャー判定は、センサー固有のAPIに依存しません。

- [`etc/graph/graph.pde`](etc/graph/graph.pde)は、加速度、角速度、推定姿勢をグラフ表示します。値の意味は[グラフのREADME](etc/graph/README.ja.md)で説明します。
- [`etc/model/model.pde`](etc/model/model.pde)は、推定姿勢をPico 2の3Dモデルへ反映します。モデルの見方は[3DモデルのREADME](etc/model/README.ja.md)で説明します。

## IMUを選択する

[`lib/processing/config.rb`](lib/processing/config.rb)の`Processing::Config::IMU_TYPE`を変更します。

```ruby
IMU_TYPE = :mpu6050 # または :bmi270
IMU_ADDRESS = 0x68 # または 0x69
```

`Processing::Unit.build`が`Processing::Units::Mpu6050`または`Processing::Units::Bmi270`を選択します。どちらも加速度をg、角速度を度毎秒、温度を摂氏で返します。別のIMUを追加するときは、同じ`name`と`read`の仕様を実装するUnitを`lib/processing/units`へ追加します。

BMI270には120 HzのODRがないため、200 Hzに設定し、アプリケーション側で120 Hz間隔に読み取ります。

## 配線

対応するIMUは、どちらも400 kHzのI2Cで接続します。

- VCC -> Pico 2の3V3(OUT)
- GND -> Pico 2のGND
- SDA -> Pico 2のGP16
- SCL -> Pico 2のGP17
- アドレス選択端子 -> I2Cアドレス`0x68`になる論理レベル

GPIOとI2C信号は3.3 V専用です。回路を変更する前にUSBを外してください。

## 準備して登録する

プロジェクトルートの`Mrbgems`には、両方のローカルIMU gemが定義されています。PicoRuby 4.0.3をビルドして書き込み、設定、Unit、ストリームの順に転送してからランチャーを登録します。

```sh
rpremote mrbgems check
rpremote build
rpremote bootsel
rpremote flash
rpremote fs push examples/picoruby/projects/processing/lib/processing :/lib/processing
rpremote dfu app examples/picoruby/projects/processing/main.rb
rpremote reset
```

`lib/processing/`には、`Processing`モジュール配下の設定、IMU Unit、ストリームのコードを置きます。ランチャーを登録する前に、R2P2の`/lib/processing`へコピーしてください。

`main.rb`は選択したIMUを確認し、`DFU.confirm`の前にストリームをバックグラウンドのSandboxタスクとして起動します。このため、R2P2シェルは引き続き利用できます。

Unitは静止状態のジャイロを2秒間平均し、3軸のバイアスを保存して以後の読み取り値から差し引きます。ストリームは120 Hzで取得し、Pico 2側でIMU専用クォータニオンを推定して、20 Hzで表示用データを送信します。

各クラスは、クラス名に対応するsnake_caseのファイルへ分割しています。`Processing::Unit`が設定されたUnitを選択し、`Processing::Units::Base`が共通のキャリブレーションとバイアス補正を担当します。`Processing::Units`配下の残りのクラスは、センサー固有の生成だけを担当します。`Processing::Orientation`と`Processing::GestureDetector`は、サンプリングとテレメトリーを実行する`Processing::Stream`から独立しています。

一時実行の`rpremote run`を使う開発へ戻る場合は、ログが重ならないよう永続起動アプリを削除し、R2P2をリセットして実行中のアプリを停止します。

```sh
rpremote dfu remove
rpremote reset
```

```text
IMU_DATA,sensor,timestamp_ms,temperature_c,ax_g,ay_g,az_g,gx_dps,gy_dps,gz_dps,q0,q1,q2,q3,roll_deg,pitch_deg,yaw_relative_deg,posture,gesture
```

## Processingで表示する

Processing 4とSerialライブラリをインストールし、いずれかのスケッチを実行します。両方のスケッチが共通の`IMU_DATA`を受信し、Unitから送られたセンサー名を表示します。

各スケッチは、現在のR2P2ファームウェアでIMUストリームを受信できる`/dev/cu.usbmodem101`を優先します。このポートは同時に1つのプログラムだけが開けるため、Processingで表示する間は`rpremote monitor`を終了し、別の`rpremote`コマンドを実行しないでください。

Processing Consoleには、受信したセンサー名、加速度、角速度、姿勢を1秒ごとに表示します。選択したポートでIMUデータを受信できていることを確認できます。`R`キーを押すと、姿勢推定をリセットして再キャリブレーションします。

現在のR2P2ファームウェアはApplication、Debug、MIDIのCDCポートを公開し、通常は`/dev/cu.usbmodem101`、`103`、`105`になります。実機で確認したRubyのIMUストリームはApplication CDC（`101`）へ出力されるため、両方のスケッチの`PREFERRED_PORT`もこちらを既定値にしています。Mac上のパスが異なる場合は、`PREFERRED_PORT`を変更してください。

## 姿勢推定の制約

MPU6050とBMI270は磁気センサーを持たない6軸IMUです。rollとpitchは重力方向で補正しますが、`yaw_relative_deg`はキャリブレーション時を基準とする相対角度で、時間とともにずれます。絶対yawではありません。ジェスチャー判定は、傾き姿勢とデバウンスした`TAP`/`SHAKE`イベントを出力します。
