#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// LCD configuration
const int LCD_ADDR = 0x27;
const int LCD_COLS = 16;
const int LCD_ROWS = 2;

LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);

void setup() {
  Serial.begin(115200);
  Serial.println("🔧 LCD Contrast Test");
  
  // Initialize I2C
  Wire.begin(15, 16);
  
  // Initialize LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  
  // Test different display modes
  lcd.setCursor(0, 0);
  lcd.print("CONTRAST TEST");
  lcd.setCursor(0, 1);
  lcd.print("1234567890123456");
  
  Serial.println("✅ Contrast test running");
  Serial.println("Look at LCD - you should see text");
}

void loop() {
  // Cycle through different display modes
  static unsigned long lastChange = 0;
  static int mode = 0;
  
  if (millis() - lastChange > 3000) {
    lcd.clear();
    
    switch(mode) {
      case 0:
        lcd.print("MODE 1: NORMAL");
        lcd.setCursor(0, 1);
        lcd.print("ABCDEFGHIJKLMNOP");
        break;
      case 1:
        lcd.print("MODE 2: BLOCK");
        lcd.setCursor(0, 1);
        lcd.print("################");
        break;
      case 2:
        lcd.print("MODE 3: NUMBERS");
        lcd.setCursor(0, 1);
        lcd.print("0123456789ABCDEF");
        break;
    }
    
    mode = (mode + 1) % 3;
    lastChange = millis();
    Serial.println("🔄 Display mode changed to: " + String(mode + 1));
  }
}
