import processing.serial.*;

final String DATA_PREFIX = "IMU_DATA,";
// R2P2 routes this Ruby stream to its Application CDC on the current
// firmware. Do not open this port with rpremote while Processing owns it.
final String PREFERRED_PORT = "/dev/cu.usbmodem101";
final int BAUD_RATE = 115200;
final int CALIBRATION_SAMPLES = 100;
final int CONSOLE_LOG_INTERVAL_MS = 1000;

Serial serialPort;
String activePort = "";
String statusText = "No serial port";
ImuSample latest = new ImuSample();
OrientationEstimator estimator = new OrientationEstimator();
int lastConsoleLogAt = -CONSOLE_LOG_INTERVAL_MS;

class ImuSample {
  String sensor = "IMU";
  float timestampMs;
  float temperature;
  float ax;
  float ay;
  float az;
  float gx;
  float gy;
  float gz;
  float roll;
  float pitch;
  float yaw;
  boolean embeddedOrientation;
}

class OrientationEstimator {
  final float alpha = 0.98;
  int calibrationCount = 0;
  float gxSum = 0.0;
  float gySum = 0.0;
  float gzSum = 0.0;
  float gxBias = 0.0;
  float gyBias = 0.0;
  float gzBias = 0.0;
  float lastTimestampMs = -1.0;
  float roll = 0.0;
  float pitch = 0.0;
  float yaw = 0.0;

  boolean calibrated() {
    return calibrationCount >= CALIBRATION_SAMPLES;
  }

  void reset() {
    calibrationCount = 0;
    gxSum = gySum = gzSum = 0.0;
    gxBias = gyBias = gzBias = 0.0;
    lastTimestampMs = -1.0;
    roll = pitch = yaw = 0.0;
  }

  void update(ImuSample sample) {
    float accelRoll = degrees(atan2(sample.ay, sample.az));
    float accelPitch = degrees(atan2(-sample.ax,
                                    sqrt(sample.ay * sample.ay + sample.az * sample.az)));

    if (!calibrated()) {
      gxSum += sample.gx;
      gySum += sample.gy;
      gzSum += sample.gz;
      calibrationCount++;
      roll = accelRoll;
      pitch = accelPitch;
      yaw = 0.0;
      lastTimestampMs = sample.timestampMs;
      if (calibrated()) {
        gxBias = gxSum / CALIBRATION_SAMPLES;
        gyBias = gySum / CALIBRATION_SAMPLES;
        gzBias = gzSum / CALIBRATION_SAMPLES;
      }
    } else {
      float dt = (sample.timestampMs - lastTimestampMs) / 1000.0;
      lastTimestampMs = sample.timestampMs;
      if (dt > 0.0 && dt < 0.25) {
        roll = alpha * (roll + (sample.gx - gxBias) * dt) + (1.0 - alpha) * accelRoll;
        pitch = alpha * (pitch + (sample.gy - gyBias) * dt) + (1.0 - alpha) * accelPitch;
        yaw = wrapDegrees(yaw + (sample.gz - gzBias) * dt);
      }
    }

    sample.roll = roll;
    sample.pitch = pitch;
    sample.yaw = yaw;
  }
}

void setup() {
  size(800, 620, P3D);
  surface.setTitle("PicoRuby IMU orientation model");
  textFont(createFont("SansSerif", 13));
  openSerial();
}

void openSerial() {
  String[] ports = Serial.list();
  if (ports.length == 0) {
    statusText = "No serial ports found";
    return;
  }

  activePort = choosePort(ports);
  try {
    serialPort = new Serial(this, activePort, BAUD_RATE);
    serialPort.clear();
    serialPort.bufferUntil('\n');
    statusText = "Connected: " + activePort + " @ " + BAUD_RATE;
  } catch (Exception e) {
    statusText = "Serial open failed: " + activePort;
    println(statusText + ": " + e.getMessage());
  }
}

String choosePort(String[] ports) {
  for (String port : ports) if (port.equals(PREFERRED_PORT)) return port;
  for (String port : ports) {
    if (port.startsWith("/dev/cu.usbmodem")) return port;
  }
  return ports[0];
}

void serialEvent(Serial port) {
  String line = port.readStringUntil('\n');
  if (line == null) return;

  ImuSample sample = parseSample(line);
  if (sample == null) return;
  if (!sample.embeddedOrientation) estimator.update(sample);
  latest = sample;
  logSample(sample);
}

void logSample(ImuSample sample) {
  int now = millis();
  if (now - lastConsoleLogAt < CONSOLE_LOG_INTERVAL_MS) return;

  lastConsoleLogAt = now;
  println(
    "IMU received on " + activePort
    + ": sensor=" + sample.sensor
    + " time_ms=" + nf(sample.timestampMs, 0, 0)
    + " accel_g=[" + nf(sample.ax, 0, 3) + ", " + nf(sample.ay, 0, 3) + ", " + nf(sample.az, 0, 3) + "]"
    + " gyro_dps=[" + nf(sample.gx, 0, 2) + ", " + nf(sample.gy, 0, 2) + ", " + nf(sample.gz, 0, 2) + "]"
    + " rpy_deg=[" + nf(sample.roll, 0, 1) + ", " + nf(sample.pitch, 0, 1) + ", " + nf(sample.yaw, 0, 1) + "]"
  );
}

ImuSample parseSample(String line) {
  String clean = trim(line);
  int marker = clean.indexOf(DATA_PREFIX);
  if (marker < 0) return null;
  String[] values = split(clean.substring(marker), ',');
  if (values.length < 10 || !trim(values[0]).equals("IMU_DATA")) return null;

  try {
    ImuSample sample = new ImuSample();
    sample.sensor = trim(values[1]);
    sample.timestampMs = Float.parseFloat(trim(values[2]));
    sample.temperature = Float.parseFloat(trim(values[3]));
    sample.ax = Float.parseFloat(trim(values[4]));
    sample.ay = Float.parseFloat(trim(values[5]));
    sample.az = Float.parseFloat(trim(values[6]));
    sample.gx = Float.parseFloat(trim(values[7]));
    sample.gy = Float.parseFloat(trim(values[8]));
    sample.gz = Float.parseFloat(trim(values[9]));
    if (values.length >= 17) {
      sample.roll = Float.parseFloat(trim(values[14]));
      sample.pitch = Float.parseFloat(trim(values[15]));
      sample.yaw = Float.parseFloat(trim(values[16]));
      sample.embeddedOrientation = true;
    }
    return sample;
  } catch (Exception e) {
    return null;
  }
}

void draw() {
  background(245);
  lights();
  translate(width * 0.58, height * 0.54, 0);
  // Map the sensor's right-handed Z-up coordinates into Processing's view:
  // sensor +X -> screen +X, sensor +Y -> depth +Z, sensor +Z -> screen -Y.
  rotate(radians(latest.yaw), 0, -1, 0);
  rotate(radians(latest.pitch), 0, 0, 1);
  rotate(radians(latest.roll), 1, 0, 0);
  drawBoard();
  drawWorldAxes();
  drawHud();
}

void drawBoard() {
  stroke(100);
  strokeWeight(1.5);
  fill(40, 135, 205);
  box(110, 16, 170);

  noStroke();
  fill(245, 190, 35);
  box(30, 18, 45);

  drawAxis(color(230, 65, 55), new PVector(115, 0, 0), "X");
  drawAxis(color(55, 170, 85), new PVector(0, 0, 115), "Y");
  drawAxis(color(65, 90, 225), new PVector(0, -115, 0), "Z");
}

void drawAxis(int axisColor, PVector endpoint, String label) {
  stroke(axisColor);
  strokeWeight(4);
  line(0, 0, 0, endpoint.x, endpoint.y, endpoint.z);
  pushMatrix();
  translate(endpoint.x, endpoint.y, endpoint.z);
  fill(axisColor);
  noStroke();
  sphere(7);
  popMatrix();
}

void drawWorldAxes() {
  pushMatrix();
  resetMatrix();
  translate(width - 100, 95, 0);
  strokeWeight(4);
  stroke(230, 65, 55);
  line(0, 0, 0, 50, 0, 0);
  stroke(55, 170, 85);
  line(0, 0, 0, 0, 0, 50);
  stroke(65, 90, 225);
  line(0, 0, 0, 0, -50, 0);
  popMatrix();
}

void drawHud() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  fill(25);
  textAlign(LEFT, TOP);
  textSize(17);
  text("PicoRuby " + latest.sensor + " orientation model", 22, 18);
  textSize(13);
  String calibration = estimator.calibrated()
                     ? "calibrated"
                     : "keep still: calibrating " + estimator.calibrationCount + "/" + CALIBRATION_SAMPLES;
  text(statusText, 22, 48);
  text(calibration + "  [R] recalibrate", 22, 68);
  text("roll  " + nf(latest.roll, 0, 1) + " deg", 22, 105);
  text("pitch " + nf(latest.pitch, 0, 1) + " deg", 22, 126);
  text("yaw   " + nf(latest.yaw, 0, 1) + " deg", 22, 147);
  text("accel  x=" + nf(latest.ax, 0, 3) + " y=" + nf(latest.ay, 0, 3) + " z=" + nf(latest.az, 0, 3) + " g", 22, 181);
  text("gyro   x=" + nf(latest.gx, 0, 1) + " y=" + nf(latest.gy, 0, 1) + " z=" + nf(latest.gz, 0, 1) + " deg/s", 22, 202);
  text("temp " + nf(latest.temperature, 0, 2) + " C", 22, 223);
  drawLegend(22, 265);
  hint(ENABLE_DEPTH_TEST);
}

void drawLegend(float x, float y) {
  fill(25);
  textAlign(LEFT, TOP);
  textSize(13);
  text("Legend", x, y);
  drawLegendItem(x, y + 27, color(230, 65, 55), "X axis / roll");
  drawLegendItem(x, y + 51, color(55, 170, 85), "Y axis / pitch");
  drawLegendItem(x, y + 75, color(65, 90, 225), "Z axis / yaw");
}

void drawLegendItem(float x, float y, int itemColor, String label) {
  stroke(itemColor);
  strokeWeight(4);
  line(x, y + 7, x + 28, y + 7);
  strokeWeight(1);
  fill(45);
  textAlign(LEFT, TOP);
  textSize(12);
  text(label, x + 38, y);
}

float wrapDegrees(float angle) {
  while (angle > 180.0) angle -= 360.0;
  while (angle < -180.0) angle += 360.0;
  return angle;
}

void keyPressed() {
  if (key == 'r' || key == 'R') estimator.reset();
}
