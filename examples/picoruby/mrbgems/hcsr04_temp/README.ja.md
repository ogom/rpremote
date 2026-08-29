# picoruby-hcsr04_temp

`picoruby-hcsr04_temp` は、HC-SR04 超音波距離センサーで距離を計測する `HCSR04Temp` C 拡張 mrbgem です。時間精度が必要なトリガ生成、ECHO 監視、距離計算は C で実行します。

## 安全上の注意

Raspberry Pi Pico 2 の GPIO は 3.3 V ロジックです。HC-SR04 の ECHO は 5 V の信号を出力するため、Pico の GPIO に直接接続しないでください。抵抗分圧回路またはレベル変換回路を使い、ECHO の信号を 3.3 V に下げます。

Pico とセンサーの GND は共通にします。センサーには、使用する HC-SR04 モジュールの仕様に合う電圧を供給してください。

## 配線

次の例では、TRIG に GP16、ECHO に GP17 を使います。

| HC-SR04 | 接続先 |
| --- | --- |
| VCC | モジュールの仕様に合う電源 |
| GND | Pico と電源の GND |
| TRIG | Pico の GP16 |
| ECHO | 抵抗分圧回路またはレベル変換回路 -> Pico の GP17 |

## 使い方

`Mrbgems` に mrbgem を追加します。

```ruby
gem path: "examples/picoruby/mrbgems/hcsr04_temp"
```

GPIO オブジェクトを作成し、`HCSR04Temp` に渡します。

```ruby
require "gpio"
require "hcsr04_temp"

trigger = GPIO.new(16, GPIO::OUT)
echo = GPIO.new(17, GPIO::IN)
sensor = HCSR04Temp.new(trigger: trigger, echo: echo, temperature_c: 20.0)

loop do
  result = sensor.read
  puts "Distance: #{result[:distance_cm].round(1)} cm"
  sleep 1
end
```

`read` は 1 回計測し、パルス幅と距離を返します。

```ruby
{
  pulse_width_us: 1_000,
  distance_cm: 17.175,
  distance_mm: 171.75
}
```

`temperature_c` には気温を摂氏で指定します。音速を `331.5 + 0.6 × temperature_c` m/s として距離を補正します。デフォルトは 20 ℃です。

最初の計測では、TRIG を Low にしてから 20 ms 待機します。2 回目以降のトリガーパルスの間隔は、最低 60 ms です。ECHO のタイムアウトはデフォルトで 30 ms です。センサーから ECHO パルスが返らない場合は、`HCSR04Temp::TimeoutError` が発生します。

気温、対象物の材質や角度、配線、センサーモジュールによって計測結果は変わります。精度が必要な場合は、アプリケーション側で値を補正してください。

## ライセンス

[MIT License](LICENSE)
