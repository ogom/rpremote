# IMU orientation 3D model

[日本語](README.ja.md)

[`model.pde`](model.pde) applies roll, pitch, and yaw received from Pico 2 to a 3D board model. The blue cuboid represents the board, the HUD on the left shows current values, and the short axes at the upper right form a fixed world coordinate frame.

## Reading the model

The model uses these colors for axes and orientation values. The legend on the left shows the same mapping:

| Color | Axis | Orientation |
| --- | --- | --- |
| Red | X | roll |
| Green | Y | pitch |
| Blue | Z | yaw |

The long axes extending from the board are local coordinates that rotate with the sensor. The short axes at the upper right are fixed world coordinates, making it possible to compare the board rotation with its reference orientation.

To display the sensor's Z-up coordinates in Processing, sensor +X maps to screen right, +Y maps into the view depth, and +Z maps to screen up. In the reference orientation, the blue Z-axis endpoint appears above the model.

Following this mapping, the code applies yaw around the displayed Z axis, pitch around Y, and roll around X. The HUD also displays acceleration, angular velocity, and internal IMU temperature. Acceleration and angular velocity do not move the model position directly; roll, pitch, and yaw estimated on Pico 2 determine its orientation.

## Roll, pitch, and yaw as aircraft motion

Using an aircraft as an example:

| Orientation | Aircraft axis | 3D model motion |
| --- | --- | --- |
| roll | Longitudinal axis from nose to tail | Banks the left and right wings. |
| pitch | Lateral axis from the left wing to the right wing | Raises or lowers the nose. |
| yaw | Vertical axis through the aircraft | Turns the nose left or right. |

This correspondence assumes that sensor +X points toward the nose, +Y follows the wing direction, and +Z points upward from the aircraft. If the physical sensor mounting differs, transform the axes and signs on the PicoRuby side to make the model match the device.

The current orientation estimator treats Z-up as level. A Y-up mounting therefore produces a model tilted by approximately 90 degree even when the sensor is operating correctly.

### Difference from Unity

Unity also displays X in red, Y in green, and Z in blue, so its axis colors match this Processing model. However, Unity commonly uses +Y as up and +Z as forward, which changes the aircraft-style rotation associated with each axis.

| Color and axis | This Processing model (Z-up) | Common Unity interpretation (Y-up, Z-forward) |
| --- | --- | --- |
| Red X | roll | pitch |
| Green Y | pitch | yaw |
| Blue Z | yaw | roll |

Unity `Transform` represents rotations as X, Y, and Z; roll, pitch, and yaw are not formal property names. The Unity column shows the common interpretation when treating a Unity model as an aircraft. This Processing model retains the aircraft/IMU Z-up terminology that matches the sensor.

## Properties of the orientation values

Roll and pitch use the Gyroscope to follow short-term rotation and the gravity direction from Acceleration to correct long-term error.

The BMI270 and MPU6050 have no magnetometer, so yaw is relative to startup. It drifts over time and cannot provide an absolute heading referenced to north.

## Input fields

The current PicoRuby stream sends this CSV record at 20 Hz:

```text
IMU_DATA,sensor,timestamp_ms,temperature_c,ax_g,ay_g,az_g,gx_dps,gy_dps,gz_dps,q0,q1,q2,q3,roll_deg,pitch_deg,yaw_relative_deg,posture,gesture
```

The model rotation uses `roll_deg`, `pitch_deg`, and `yaw_relative_deg`. The HUD and Processing Console also show the sensor name, timestamp, temperature, acceleration, and angular velocity. The sketch receives but does not display `q0` through `q3`, `posture`, or `gesture`.

Only when PicoRuby sends a shorter record without orientation fields does Processing estimate orientation with its complementary filter and calculate gyroscope bias from the first 100 samples. The current stream includes orientation fields, so the Pico 2 estimate takes precedence.

## Run and verify

Open and run [`model.pde`](model.pde) in Processing 4. The sketch prefers `/dev/cu.usbmodem101`; if it is unavailable, it selects the first `/dev/cu.usbmodem*` port.

The Processing Console prints the received sensor name, timestamp, acceleration, angular velocity, and orientation once per second. If the model does not move, check the selected port and the `IMU received` message in the Console. Processing and `rpremote monitor` cannot open the same port at the same time.

The `R` key resets Processing's fallback complementary filter for short input records. It does not repeat the current PicoRuby stream's two-second gyroscope calibration or reset its orientation estimate. To restart both, restart the stream and keep the sensor still for two seconds.
