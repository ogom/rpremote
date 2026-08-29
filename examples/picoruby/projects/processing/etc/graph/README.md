# IMU orientation graph

[日本語](README.ja.md)

[`graph.pde`](graph.pde) plots acceleration, angular velocity, and estimated orientation received from Pico 2. Current values appear at the top, followed by three history charts.

## Displayed values

| Chart | Values | Unit | Meaning |
| --- | --- | --- | --- |
| Acceleration | `ax`, `ay`, `az` | g | Acceleration along each sensor axis. At rest, gravity makes the three-axis magnitude approximately 1 g. |
| Gyroscope | `gx`, `gy`, `gz` | degree/s | Angular velocity around each sensor axis. Positive rotation follows the right-hand rule for that axis. |
| Orientation | `roll`, `pitch`, `yaw` | degree | Orientation estimated from acceleration and angular velocity on Pico 2. |
| Temperature | `temp` | °C | Internal IMU temperature, which does not exactly equal ambient temperature. |

Each chart uses red for the X axis or roll, green for the Y axis or pitch, and blue for the Z axis or yaw. Samples progress from old on the left to new on the right. The current stream sends at 20 Hz and the chart retains 300 samples, so the full width represents approximately 15 seconds.

The display ranges are -2 to +2 g for acceleration, -250 to +250 degree/s for angular velocity, and -180 to +180 degree for orientation. Values outside a chart range are clamped to its top or bottom edge, while the current-value area still shows the actual number.

## Sensor axes and mounting direction

The graph displays the BMI270 or MPU6050 sensor coordinates directly. It does not detect mounting direction or remap axes automatically.

- With +Z pointing up at rest, the usual values are `ax ≈ 0`, `ay ≈ 0`, and `az ≈ +1`.
- With +Y pointing up at rest, the usual values are `ax ≈ 0`, `ay ≈ +1`, and `az ≈ 0`.
- With -Y pointing up, `ay ≈ -1`.

The current orientation estimator treats Z-up as level. A Y-up mounting therefore shows approximately 90 degree of roll or pitch even when the sensor readings are correct. Treating Y-up as level requires an axis transformation on the PicoRuby side.

## Roll, pitch, and yaw

- `roll` is rotation around the X axis.
- `pitch` is rotation around the Y axis.
- `yaw` is rotation around the Z axis.

Using an aircraft as an example:

| Orientation | Aircraft axis | Motion |
| --- | --- | --- |
| roll | Longitudinal axis from nose to tail | Banks the left and right wings. |
| pitch | Lateral axis from the left wing to the right wing | Raises or lowers the nose. |
| yaw | Vertical axis through the aircraft | Turns the nose left or right. |

This correspondence assumes that sensor +X points toward the nose, +Y follows the wing direction, and +Z points upward from the aircraft. A different sensor mounting changes how displayed roll, pitch, and yaw correspond to physical motion.

Gravity corrects roll and pitch. The BMI270 and MPU6050 have no magnetometer, so yaw is relative to startup. It drifts over time and is not an absolute compass heading.

## Input fields

The current stream sends this CSV record at 20 Hz:

```text
IMU_DATA,sensor,timestamp_ms,temperature_c,ax_g,ay_g,az_g,gx_dps,gy_dps,gz_dps,q0,q1,q2,q3,roll_deg,pitch_deg,yaw_relative_deg,posture,gesture
```

`graph.pde` uses the sensor name, timestamp, temperature, acceleration, angular velocity, roll, pitch, and yaw. It receives but does not plot `q0` through `q3`, `posture`, or `gesture`.

Only when PicoRuby sends a shorter record without orientation fields does Processing estimate roll, pitch, and yaw with its complementary filter and calculate gyroscope bias from the first 100 samples. The current stream includes orientation fields, so the Pico 2 estimate takes precedence.

## Run and verify

Open and run [`graph.pde`](graph.pde) in Processing 4. The sketch prefers `/dev/cu.usbmodem101`; if it is unavailable, it selects the first `/dev/cu.usbmodem*` port.

The Processing Console prints the received sensor name, timestamp, acceleration, angular velocity, and orientation once per second. If the charts stay empty, check the selected port and the `IMU received` message in the Console. Processing and `rpremote monitor` cannot open the same port at the same time.

The `R` key clears Processing's history and resets the fallback complementary filter used for short input records. It does not repeat the current PicoRuby stream's two-second gyroscope calibration. To recalibrate on Pico 2, restart the stream and keep the sensor still for two seconds.
