#include <Wire.h>

void setup() {
  Wire.begin(15, 16); // SDA=15, SCL=16 for ESP32-CAM
  Serial.begin(115200);
  Serial.println("🔍 Scanning I2C devices...");
}

void loop() {
  byte error, address;
  int nDevices = 0;

  Serial.println("Scanning...");

  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();

    if (error == 0) {
      Serial.print("✅ Found device at address 0x");
      if (address < 16) Serial.print("0");
      Serial.println(address, HEX);
      nDevices++;
    } else if (error == 4) {
      Serial.print("❌ Unknown error at address 0x");
      if (address < 16) Serial.print("0");
      Serial.println(address, HEX);
    }
  }

  if (nDevices == 0) {
    Serial.println("❌ No I2C devices found");
  } else {
    Serial.print("✅ Found ");
    Serial.print(nDevices);
    Serial.println(" device(s)");
  }

  delay(5000); // Wait 5 seconds before next scan
}
