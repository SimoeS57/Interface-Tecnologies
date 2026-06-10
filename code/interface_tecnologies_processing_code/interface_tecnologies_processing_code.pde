import processing.serial.*;

Serial port;
float cellSize;
int lastResponseTime = 0;
float[] sensorValues = new float[4];
float potRaw = 0;
float hueValue = 0;
color[][] pixelColors = new color[8][8];
float[] sideIntensities = new float[4];
float[] pulseTimer = new float[4];
float[] interactionAge = new float[4];
color baseColor;
int systemState = 0;
float noiseTime = 0.0;

//int[] sensorMap = {0, 1, 2, 3};
int[] sensorMap = {1, 0, 3, 2};
float standByMaxB = 80;
float standByMaxS = 150;
float standByContrast = 3.0;
float standByWhitenessA = 135.0;
float standByWhitenessB = 75.0;
float standBySpeed = 0.003;
float standByZoom = 0.3;

float fadeInSpeed = 0.002;
float fadeOutSpeed = 0.012;

float sensorThreshold = 40000.0;
float interactionIncrease = 0.001;
float interactionFocusSize = 0.5;
float interactionWaterLine = 5.0;
float pumpingSpeed = 0.12;
float pumpingMinB = 80.0;

float focusTopX = 3.5;
float focusTopY = 0.0;
float focusRightX = 7.0;
float focusRightY = 3.5;
float focusBottomX = 3.5;
float focusBottomY = 7.0;
float focusLeftX = 0.0;
float focusLeftY = 3.5;

float syncFactor = 0.0;
float syncSpeed = 0.005;

float sensorReadingMin = 40000.0;
float sensorReadingMax = 130000.0;

float minPumpingSpeed = 0.03;
float maxPumpingSpeed = 0.07;
float sensorMaxRead = 130000.0;

float standbyFade = 1.0;
float standbyFadeSpeed = 0.01;
int lastReleaseTime = 0;
int standbyDelayTime = 8000;

void setup() {
  size(400, 400);
  colorMode(HSB, 360, 255, 255);
  cellSize = width / 8.0;
  port = new Serial(this, "COM3", 115200);
  port.bufferUntil('\n');
  delay(2000);
  sendRGBToArduino();
  lastResponseTime = millis();
  lastReleaseTime = -20000;
}

void draw() {
  background(0);
  hueValue = map(potRaw, 0, 1023, 0, 360);

  updateSync();
  handleStandbyTimer();

  for (int i = 0; i < 4; i++) {
    updateSensors(i);
  }

  clearToBlack();
  standByNoise();
  interactionPulse();
  drawSimulation();


  lastResponseTime = millis();
}

void updateSync() {
  int activeCount = 0;
  int collidingWaves = 0;
  for (int i = 0; i < 4; i++) {
    int realSensorIndex = sensorMap[i];
    if (sensorValues[realSensorIndex] > sensorThreshold) {
      activeCount++;
    }
    if (interactionAge[i] >= 0.95) {
      collidingWaves++;
    }
  }

  if (collidingWaves >= 2) {
    syncFactor += syncSpeed;
    if (syncFactor > 1.0) syncFactor = 1.0;
  } else {
    if (activeCount == 0 && syncFactor >= 0.95) {
    } else {
      syncFactor -= syncSpeed * 2.0;
      if (syncFactor < 0.0) syncFactor = 0.0;
    }
  }
}

void handleStandbyTimer() {
  int activeCount = 0;
  for (int i = 0; i < 4; i++) {
    int realSensorIndex = sensorMap[i];
    if (sensorValues[realSensorIndex] > sensorThreshold) {
      activeCount++;
    }
  }

  if (activeCount > 0) {
    standbyFade -= standbyFadeSpeed;
    if (standbyFade < 0.0) standbyFade = 0.0;
    lastReleaseTime = millis();
  } else {
    if (millis() - lastReleaseTime > standbyDelayTime) {
      standbyFade += standbyFadeSpeed;
      if (standbyFade > 1.0) standbyFade = 1.0;
    } else {
      standbyFade = 0.0;
    }
  }
}

void standByNoise() {
  noiseTime += standBySpeed;
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      float n = noise(col * standByZoom, row * standByZoom, noiseTime);
      n = pow(n, standByContrast);
      float standbyB = (standByMaxB * n) * standbyFade;
      float standbyS = map(n, 0.0, 1.0, standByMaxS, standByMaxS - standByWhitenessA);

      if (standbyFade > 0.0) {
        pixelColors[row][col] = color(hueValue, standbyS, standbyB);
      }
    }
  }
}

void clearToBlack() {
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      pixelColors[row][col] = color(0, 0, 0);
    }
  }
}

void interactionPulse() {
  float currentHue = hueValue;
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      float totalEffect = 0.0;
      float blendedBrightness = 0.0;
      for (int i = 0; i < 4; i++) {
        float interactionEffect = getInteractionFactor(row, col, i);
        if (interactionEffect > 0.0) {
          float pulseWave = map(sin(pulseTimer[i]), -1.0, 1.0, pumpingMinB, 255.0);
          blendedBrightness += (pulseWave * interactionEffect);
          totalEffect += interactionEffect;
        }
      }
      if (totalEffect > 0.0) {
        if (totalEffect > 1.0) totalEffect = 1.0;
        color currentPixel = pixelColors[row][col];
        float standbyB = brightness(currentPixel);
        float standbyS = saturation(currentPixel);
        float targetBrightness = blendedBrightness / (totalEffect > 0 ? totalEffect : 1.0);
        float finalBrightness = lerp(standbyB, targetBrightness, totalEffect);
        float finalSaturation = lerp(standbyS, 255.0, totalEffect);
        pixelColors[row][col] = color(currentHue, finalSaturation, finalBrightness);
      }
    }
  }
}

void updateSensors(int i) {
  int realSensorIndex = sensorMap[i];
  if (sensorValues[realSensorIndex] > sensorThreshold) {
    sideIntensities[i] += fadeInSpeed;
    if (sideIntensities[i] > 1.0) sideIntensities[i] = 1.0;

    interactionAge[i] += interactionIncrease;
    if (interactionAge[i] > 1.0) interactionAge[i] = 1.0;

    float dynamicPumpingSpeed = map(sensorValues[realSensorIndex], sensorReadingMin, sensorReadingMax, minPumpingSpeed, maxPumpingSpeed);
    dynamicPumpingSpeed = constrain(dynamicPumpingSpeed, minPumpingSpeed, maxPumpingSpeed);
    pulseTimer[i] += dynamicPumpingSpeed;

    if (syncFactor > 0.0) {
      for (int k = 0; k < 4; k++) {
        if (k != i && sideIntensities[k] > 0.5) {
          float diff = pulseTimer[k] - pulseTimer[i];
          diff = atan2(sin(diff), cos(diff));
          pulseTimer[i] += diff * (syncFactor * 0.03);
          break;
        }
      }
    }
  } else {
    sideIntensities[i] -= fadeOutSpeed;
    if (sideIntensities[i] < 0.0) sideIntensities[i] = 0.0;

    interactionAge[i] -= fadeOutSpeed;
    if (interactionAge[i] < 0.0) interactionAge[i] = 0.0;

    pulseTimer[i] += minPumpingSpeed;
  }
}

float getInteractionFactor(int row, int col, int i) {
  float focusX = 3.5;
  float focusY = 3.5;
  if (i == 0) {
    focusX = focusTopX;
    focusY = focusTopY;
  } else if (i == 1) {
    focusX = focusRightX;
    focusY = focusRightY;
  } else if (i == 2) {
    focusX = focusBottomX;
    focusY = focusBottomY;
  } else if (i == 3) {
    focusX = focusLeftX;
    focusY = focusLeftY;
  }
  if (i == 0 && row > 4) return 0.0;
  if (i == 2 && row < 3) return 0.0;
  if (i == 1 && col < 3) return 0.0;
  if (i == 3 && col > 4) return 0.0;
  float distanceToFocus = dist(col, row, focusX, focusY);

  float pulseModulation = map(sin(pulseTimer[i]), -1.0, 1.0, 0.85, 1.0);
  float dynamicWaterLine = interactionFocusSize + ((interactionWaterLine - interactionFocusSize) * interactionAge[i] * pulseModulation);

  if (distanceToFocus <= interactionFocusSize) {
    return sideIntensities[i];
  } else if (distanceToFocus <= dynamicWaterLine) {
    float range = dynamicWaterLine - interactionFocusSize;
    float fadeDistance = distanceToFocus - interactionFocusSize;
    float distanceFactor = (range > 0) ? map(fadeDistance, 0.0, range, 1.0, 0.0) : 0.0;
    return sideIntensities[i] * distanceFactor;
  }
  return 0.0;
}

void drawSimulation() {
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      fill(pixelColors[row][col]);
      rect(col * cellSize, row * cellSize, cellSize, cellSize);
    }
  }
  fill(0, 0, 255);
  textSize(14);
  text("Potenciometro (Hue): " + int(hueValue), 20, 30);
  text("T: " + int(sensorValues[sensorMap[0]]) + " | R: " + int(sensorValues[sensorMap[1]]), 20, 60);
  text("B: " + int(sensorValues[sensorMap[2]]) + " | L: " + int(sensorValues[sensorMap[3]]), 20, 80);
  text("Sincronia Atual: " + int(syncFactor * 100) + "%", 20, 110);
}

void sendRGBToArduino() {
  byte[] packet = new byte[192];
  int index = 0;
  for (int row = 0; row < 8; row++) {
    if (row % 2 == 0) {
      for (int col = 0; col < 8; col++) {
        int c = pixelColors[row][col];
        packet[index++] = (byte)((c >> 16) & 0xFF);
        packet[index++] = (byte)((c >> 8) & 0xFF);
        packet[index++] = (byte)(c & 0xFF);
      }
    } else {
      for (int col = 7; col >= 0; col--) {
        int c = pixelColors[row][col];
        packet[index++] = (byte)((c >> 16) & 0xFF);
        packet[index++] = (byte)((c >> 8) & 0xFF);
        packet[index++] = (byte)(c & 0xFF);
      }
    }
  }
  port.write('M');
  port.write(packet);
}

void serialEvent(Serial port) {
  try {
    String line = port.readStringUntil('\n');
    if (line == null) return;
    line = trim(line);
    if (line.startsWith("S:")) {
      String[] values = split(line.substring(2), ',');
      if (values.length >= 5) {
        sensorValues[0] = parseFloat(values[0]);
        sensorValues[1] = parseFloat(values[1]);
        sensorValues[2] = parseFloat(values[2]);
        sensorValues[3] = parseFloat(values[3]);
        potRaw = parseFloat(values[4]);
        lastResponseTime = millis();
        sendRGBToArduino();
      }
    }
  }
  catch (Exception e) {
  }
}
