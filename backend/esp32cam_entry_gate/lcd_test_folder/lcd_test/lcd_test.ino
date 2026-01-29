#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// LCD configuration
const int LCD_ADDR = 0x27;     // Try 0x27, 0x3F, 0x20, or 0x38
const int LCD_COLS = 16;
const int LCD_ROWS = 2;

LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);

void setup() {
  Serial.begin(115200);
  Serial.println("🖥️ Testing LCD...");
  
  // Initialize I2C
  Wire.begin(15, 16); // SDA=15, SCL=16
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  ESP.restart();

  
  // Test display
  lcd.setCursor(0, 0);
  lcd.print("Hello World!");
  lcd.setCursor(0, 1);
  lcd.print("LCD Test OK");
  
  Serial.println("✅ LCD test complete");
}

void loop() {
  // Blink backlight every 2 seconds
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink > 2000) {
    lcd.noBacklight();
    delay(100);
    lcd.backlight();
    lastBlink = millis();
    Serial.println("💡 LCD backlight blinked");
  }
}
