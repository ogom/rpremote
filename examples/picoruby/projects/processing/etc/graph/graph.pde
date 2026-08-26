import processing.serial.*;
import java.util.ArrayList;

final String DATA_PREFIX = "IMU_DATA,";
// R2P2 routes this Ruby stream to its Application CDC on the current
// firmware. Do not open this port with rpremote while Processing owns it.
final String PREFERRED_PORT = "/dev/cu.usbmodem101";
final int BAUD_RATE = 115200;
final int HISTORY_LIMIT = 300;
final int CALIBRATION_SAMPLES = 100;
final int CONSOLE_LOG_INTERVAL_MS = 1000;

Serial serialPort;
String activePort = "";
String statusText = "No serial port";
ArrayList<ImuSample> history = new ArrayList<ImuSample>();
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
  size(1280, 860);
  surface.setTitle("PicoRuby IMU orientation graph");
  frameRate(30);
  textFont(createFont("SansSerif", 12));
  openSerial();
}

void openSerial() {
  String[] ports = Serial.list();
  println("Serial ports:");
  for (int i = 0; i < ports.length; i++) {
    println(i + ": " + ports[i]);
  }

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
    println(statusText);
    println(e.getMessage());
  }
}

String choosePort(String[] ports) {
  for (String port : ports) {
    if (port.equals(PREFERRED_PORT)) return port;
  }
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
  history.add(sample);
  while (history.size() > HISTORY_LIMIT) {
    history.remove(0);
  }
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
  clean = clean.substring(marker);

  String[] values = split(clean, ',');
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
    println("Invalid IMU data: " + clean);
    return null;
  }
}

void draw() {
  background(244);
  drawHeader();
  drawValues(24, 54, width - 48, 74);
  drawChart("Acceleration [g]", 24, 150, width - 48, 200, -2.0, 2.0,
            "ax", "ay", "az");
  drawChart("Gyroscope [deg/s]", 24, 374, width - 48, 200, -250.0, 250.0,
            "gx", "gy", "gz");
  drawChart("Orientation [deg]", 24, 598, width - 48, 220, -180.0, 180.0,
            "roll", "pitch", "yaw");
}

void drawHeader() {
  fill(25);
  textAlign(LEFT, TOP);
  textSize(18);
  text("PicoRuby " + latest.sensor + " orientation graph", 24, 16);
  fill(85);
  textSize(12);
  String calibration = estimator.calibrated()
                       ? "calibrated"
                       : "keep still: calibrating " + estimator.calibrationCount + "/" + CALIBRATION_SAMPLES;
  text(statusText + "  samples=" + history.size() + "  " + calibration + "  [R] recalibrate", 390, 21);
}

void drawValues(float x, float y, float w, float h) {
  noStroke();
  fill(255);
  rect(x, y, w, h, 8);
  fill(35);
  textAlign(LEFT, TOP);
  textSize(13);
  text("accel  " + vectorText(latest.ax, latest.ay, latest.az, "g"), x + 16, y + 13);
  text("gyro  " + vectorText(latest.gx, latest.gy, latest.gz, "deg/s"), x + 410, y + 13);
  text("orientation  roll=" + nf(latest.roll, 0, 1) + "  pitch=" + nf(latest.pitch, 0, 1)
       + "  yaw=" + nf(latest.yaw, 0, 1) + " deg", x + 16, y + 42);
  text("temp=" + nf(latest.temperature, 0, 2) + " C", x + 840, y + 42);
}

String vectorText(float x, float y, float z, String unit) {
  return "x=" + nf(x, 0, 3) + "  y=" + nf(y, 0, 3) + "  z=" + nf(z, 0, 3) + " " + unit;
}

void drawChart(String title, float x, float y, float w, float h,
               float minValue, float maxValue, String a, String b, String c) {
  fill(255);
  stroke(210);
  strokeWeight(1);
  rect(x, y, w, h, 8);
  drawGrid(x, y, w, h, minValue, maxValue);

  fill(35);
  textAlign(LEFT, TOP);
  textSize(14);
  text(title, x + 14, y + 10);
  drawLegend(x + w - 250, y + 12, a, color(220, 55, 50),
             b, color(45, 150, 75), c, color(55, 95, 210));

  if (history.size() < 2) {
    fill(110);
    textAlign(CENTER, CENTER);
    text("Waiting for IMU_DATA...", x + w / 2, y + h / 2);
    return;
  }

  drawSeries(x, y, w, h, minValue, maxValue, a, color(220, 55, 50));
  drawSeries(x, y, w, h, minValue, maxValue, b, color(45, 150, 75));
  drawSeries(x, y, w, h, minValue, maxValue, c, color(55, 95, 210));
}

void drawGrid(float x, float y, float w, float h, float minValue, float maxValue) {
  stroke(232);
  for (int i = 1; i < 5; i++) {
    float gridY = y + 34 + (h - 52) * i / 5.0;
    line(x + 12, gridY, x + w - 12, gridY);
  }
  float zeroY = map(0.0, minValue, maxValue, y + h - 18, y + 34);
  stroke(180);
  line(x + 12, zeroY, x + w - 12, zeroY);

  fill(115);
  textAlign(RIGHT, CENTER);
  textSize(10);
  text(nf(maxValue, 0, 1), x + w - 14, y + 34);
  text("0", x + w - 14, zeroY);
  text(nf(minValue, 0, 1), x + w - 14, y + h - 18);
}

void drawSeries(float x, float y, float w, float h, float minValue, float maxValue,
                String field, int seriesColor) {
  noFill();
  stroke(seriesColor);
  strokeWeight(2);
  beginShape();
  for (int i = 0; i < history.size(); i++) {
    ImuSample sample = history.get(i);
    float px = map(i, 0, HISTORY_LIMIT - 1, x + 14, x + w - 14);
    float py = map(valueOf(sample, field), minValue, maxValue, y + h - 18, y + 34);
    vertex(px, constrain(py, y + 34, y + h - 18));
  }
  endShape();
  strokeWeight(1);
}

float valueOf(ImuSample sample, String field) {
  if (field.equals("ax")) return sample.ax;
  if (field.equals("ay")) return sample.ay;
  if (field.equals("az")) return sample.az;
  if (field.equals("gx")) return sample.gx;
  if (field.equals("gy")) return sample.gy;
  if (field.equals("gz")) return sample.gz;
  if (field.equals("roll")) return sample.roll;
  if (field.equals("pitch")) return sample.pitch;
  if (field.equals("yaw")) return sample.yaw;
  return 0.0;
}

void drawLegend(float x, float y, String a, int ca, String b, int cb, String c, int cc) {
  drawLegendItem(x, y, a, ca);
  drawLegendItem(x + 80, y, b, cb);
  drawLegendItem(x + 160, y, c, cc);
}

void drawLegendItem(float x, float y, String label, int itemColor) {
  stroke(itemColor);
  strokeWeight(3);
  line(x, y + 7, x + 22, y + 7);
  strokeWeight(1);
  fill(70);
  textAlign(LEFT, CENTER);
  textSize(11);
  text(label, x + 28, y + 7);
}

float wrapDegrees(float angle) {
  while (angle > 180.0) angle -= 360.0;
  while (angle < -180.0) angle += 360.0;
  return angle;
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    estimator.reset();
    history.clear();
  }
}
