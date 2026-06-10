#include <Wire.h>
#include <Adafruit_NeoPixel.h>
#include "MAX30105.h"

#define MUX_ADDR 0x70 
#define NUM_SENSORS 4
#define LED_PIN 6         
#define NUMPIXELS 64  
#define POT_PIN A0    

Adafruit_NeoPixel matrix = Adafruit_NeoPixel(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);
MAX30105 particleSensors[NUM_SENSORS];
byte rgbBuffer[192]; 

void tcaselect(uint8_t bus) {
  if (bus > 7) return;
  Wire.beginTransmission(MUX_ADDR);
  Wire.write(1 << bus);
  Wire.endTransmission();
}

void setup() {
  Serial.begin(115200); 
  Wire.begin();

  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    tcaselect(i);
    delay(20);
    if (!particleSensors[i].begin(Wire, I2C_SPEED_FAST)) while (1); 
    particleSensors[i].setup();
    particleSensors[i].setPulseAmplitudeRed(0x1F); 
    particleSensors[i].setPulseAmplitudeIR(0x1F);  
  }

  matrix.begin();
  matrix.show();  
}

void loop() {
  // 1. Envia os dados puros dos Sensores e o valor BRUTO do potenciómetro (0-1023)
  Serial.print("S:");
  for (uint8_t i = 0; i < NUM_SENSORS; i++) {
    tcaselect(i);
    Serial.print(particleSensors[i].getIR());
    Serial.print(",");
  }
  Serial.println(analogRead(POT_PIN)); // Envia o pot no fim. Ex: "S:84120,83500,600,590,512"

  // 2. Recebe a imagem RGB total vinda do Processing e põe na matriz
  if (Serial.available() >= 192) {
    Serial.readBytes(rgbBuffer, 192);
    
    for (int i = 0; i < 64; i++) {
      int row = i / 8;
      int col = i % 8;
      int pixelIndex = (row % 2 == 0) ? (row * 8 + col) : (row * 8 + (7 - col));
      matrix.setPixelColor(pixelIndex, matrix.Color(rgbBuffer[i*3], rgbBuffer[i*3+1], rgbBuffer[i*3+2]));
    }
    matrix.show();  
  }

  delay(15); 
}