#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <ESP32QRCodeReader.h>
#include <LiquidCrystal_I2C.h>
#include <Wire.h>

// I2C pins for LCD
#define I2C_SDA 14
#define I2C_SCL 2

// WiFi credentials
const char* WIFI_SSID = "TT_B7F6_2.4G";
const char* WIFI_PASSWORD = "XUDH9UD7Ac";

// Backend server URL
const char* SERVER_URL = "https://parking-intelligent-backend.onrender.com/api/parking/entry";

// Hardware pins
const int SERVO_PIN = 12;       // Servo motor for gate
const int IR_SENSOR_PIN = 13
;   // IR obstacle sensor for car detection

// Gate settings
const int GATE_CLOSED_ANGLE = 0;     // Servo angle when gate is closed
const int GATE_OPEN_ANGLE = 90;     // Servo angle when gate is open
const int GATE_OPEN_DURATION = 60000; // Max time gate stays open (60 seconds)
const int GATE_TIMEOUT = 60000;      // Timeout if car doesn't pass (60 seconds)
const int SCAN_COOLDOWN = 3000;      // Prevent duplicate scans (ms)

// Note: Camera pin definitions are handled by ESP32QRCodeReader library
// CAMERA_MODEL_AI_THINKER automatically configures all camera pins

// Function prototypes
void connectWiFi();
void onQrCodeFound(const char *qrCode);
void verifyQRCode(String qrCode);
void openGate();
void waitForCarToPass();
void closeGate();
void showSuccess(String message);
void showError(String message);
void fetchParkingStats();
void updateLCD();
void checkForExitEvents();

// Global objects
Servo gateServo;
LiquidCrystal_I2C lcd(0x27, 16, 2);  // Default address 0x27, 16 columns, 2 rows
ESP32QRCodeReader qrReader(CAMERA_MODEL_AI_THINKER);

// LCD status flag
bool lcdAvailable = false;

// Global variables
String lastScannedQR = "";
unsigned long lastScanTime = 0;
int availableSpots = 0;
int bookedSpots = 0;
const int totalSpots = 6;
int scanCount = 0; // Track number of scans
unsigned long lastMemoryCheck = 0;

void setup() {
  Serial.begin(115200);
  delay(1000); // Wait for Serial to be ready
  
  // Disable brownout detector to prevent reboots during power spikes
  // WARNING: Only disable if you have stable power supply
  // WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); // Uncomment if needed
  
  Serial.println("\n\n========================================");
  Serial.println("ESP32-CAM Entry Gate System");
  Serial.println("========================================\n");
  
  // Note: Watchdog is handled automatically by ESP32
  
  // Initialize pins
  Serial.println("[1/6] Initializing pins...");
  pinMode(IR_SENSOR_PIN, INPUT);
  Serial.println("✅ Pins initialized");
  
  // Initialize servo
  Serial.println("[2/6] Initializing servo...");
  gateServo.attach(SERVO_PIN);
  Serial.println("Closing gate...");
  closeGate();
  Serial.println("✅ Servo initialized");
  
  // Initialize I2C for LCD
  Serial.println("[3/6] Initializing I2C and LCD...");
  Wire.begin(I2C_SDA, I2C_SCL);
  delay(200); // Give I2C time to initialize
  
  // Test I2C connection
  Wire.beginTransmission(0x27);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    Serial.println("✅ LCD found at address 0x27");
  } else {
    Serial.print("⚠️ LCD not found at 0x27 (error: ");
    Serial.print(error);
    Serial.println(")");
    Serial.println("   Common addresses: 0x3F, 0x20, 0x38");
    Serial.println("   System will continue without LCD");
  }
  
  // Initialize LCD (with error handling to prevent crashes)
  Serial.println("   Initializing LCD (this may cause reboot if power is low)...");
  Serial.flush();
  
  bool lcdInitialized = false;
  unsigned long lcdStartTime = millis();
  
  // Try to initialize LCD with timeout
  for (int attempt = 0; attempt < 3; attempt++) {
    Serial.print("   LCD init attempt ");
    Serial.print(attempt + 1);
    Serial.println("/3...");
    
    // Feed watchdog
    yield();
    delay(50);
    
    // Try initialization
    lcd.init();
    delay(200);
    
    // Test if LCD responds
    lcd.backlight();
    delay(100);
    lcd.clear();
    
    // If we got here without crashing, LCD is working
    lcdInitialized = true;
    Serial.println("   ✅ LCD init successful!");
    break;
  }
  
  if (lcdInitialized) {
    lcd.setCursor(0, 0);
    lcd.print("Initializing...");
    lcdAvailable = true;
    unsigned long totalTime = millis() - lcdStartTime;
    Serial.print("✅ LCD initialized in ");
    Serial.print(totalTime);
    Serial.println(" ms");
  } else {
    lcdAvailable = false;
    Serial.println("⚠️ LCD initialization failed or skipped");
    Serial.println("   System will continue without LCD display");
  }
  
  // Connect to WiFi
  Serial.println("[4/6] Connecting to WiFi...");
  connectWiFi();
  
  // Initialize QR reader (this also initializes the camera automatically)
  Serial.println("[5/6] Initializing camera and QR reader...");
  Serial.println("   This may take 5-10 seconds...");
  Serial.flush(); // Make sure all output is sent before blocking operation
  
  unsigned long camStartTime = millis();
  
  // Initialize QR reader (this also initializes the camera)
  bool cameraInitSuccess = qrReader.setup();
  if (!cameraInitSuccess) {
    Serial.println("❌ Camera initialization FAILED!");
    Serial.println("   Check camera connections and power supply");
  } else {
    Serial.println("✅ Camera setup successful");
  }
  
  qrReader.beginOnCore(1); // Run on core 1
  unsigned long camInitTime = millis() - camStartTime;
  
  Serial.print("✅ Camera initialized in ");
  Serial.print(camInitTime);
  Serial.println(" ms");
  Serial.println("📷 QR Code scanner is now active");
  Serial.println("   Point QR code at camera and wait for detection...");
  
  Serial.println("[6/6] System initialization complete!");
  
  // Display memory information
  Serial.println("\n========================================");
  Serial.println("💾 MEMORY STATUS");
  Serial.println("========================================");
  Serial.print("Free Heap: ");
  Serial.print(ESP.getFreeHeap());
  Serial.println(" bytes");
  Serial.print("Min Free Heap: ");
  Serial.print(ESP.getMinFreeHeap());
  Serial.println(" bytes");
  Serial.print("Total Heap: ");
  Serial.print(ESP.getHeapSize());
  Serial.println(" bytes");
  Serial.print("Largest Free Block: ");
  Serial.print(ESP.getMaxAllocHeap());
  Serial.println(" bytes");
  Serial.println("========================================\n");
  
  // Fetch initial stats and update LCD
  Serial.println("\n========================================");
  Serial.println("✅ System ready!");
  Serial.println("========================================\n");
  
  // Fetch stats immediately after WiFi connection
  if (WiFi.status() == WL_CONNECTED) {
    fetchParkingStats();
  } else {
    // If WiFi not connected, still update LCD with default values
    updateLCD();
  }
  
  Serial.println("Waiting for QR codes...");
  Serial.println("Monitor this output for debugging\n");
}

void loop() {
  // Check WiFi connection (only retry every 30 seconds if disconnected)
  static unsigned long lastWiFiCheck = 0;
  if (WiFi.status() != WL_CONNECTED) {
    if (millis() - lastWiFiCheck > 30000) { // Retry every 30 seconds
      Serial.println("WiFi disconnected, attempting reconnect...");
      connectWiFi();
      lastWiFiCheck = millis();
    }
  } else {
    lastWiFiCheck = 0; // Reset if connected
  }
  
  // Check for QR codes
  struct QRCodeData qrCodeData;
  if (qrReader.receiveQrCode(&qrCodeData, 100)) {
    // Debug: Always print QR detection attempts
    Serial.print("🔍 QR Detection - Valid: ");
    Serial.print(qrCodeData.valid ? "YES" : "NO");
    if (qrCodeData.valid) {
      Serial.print(" | Payload: ");
      Serial.println((const char*)qrCodeData.payload);
      onQrCodeFound((const char*)qrCodeData.payload);
    } else {
      Serial.print(" | Payload length: ");
      Serial.println(qrCodeData.payloadLen);
      Serial.println("⚠️ Invalid QR code detected - check camera focus/lighting");
    }
  }
  
  // Periodic camera status check (every 10 seconds)
  static unsigned long lastCameraCheck = 0;
  if (millis() - lastCameraCheck > 10000) {
    Serial.println("📷 Camera/QR Reader: Active and scanning...");
    lastCameraCheck = millis();
  }
  
  // Check for exit events
  static unsigned long lastExitCheck = 0;
  if (millis() - lastExitCheck > 2000) {
    checkForExitEvents();
    lastExitCheck = millis();
  }
  
  // Update stats periodically
  static unsigned long lastStatsUpdate = 0;
  if (millis() - lastStatsUpdate > 5000) {
    fetchParkingStats();
    lastStatsUpdate = millis();
  }
  
  // Monitor memory every 30 seconds
  if (millis() - lastMemoryCheck > 30000) {
    size_t freeHeap = ESP.getFreeHeap();
    size_t minFreeHeap = ESP.getMinFreeHeap();
    Serial.print("\n💾 Memory Status - Free: ");
    Serial.print(freeHeap);
    Serial.print(" bytes | Min Free: ");
    Serial.print(minFreeHeap);
    Serial.print(" bytes | Scans: ");
    Serial.println(scanCount);
    
    if (freeHeap < 30000) { // Critical: less than 30KB
      Serial.println("🚨 CRITICAL: Very low memory! System may need reboot.");
    }
    
    lastMemoryCheck = millis();
  }
  
  delay(100);
}

// Connect to WiFi
void connectWiFi() {
  if (lcdAvailable) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Connecting to");
    lcd.setCursor(0, 1);
    lcd.print("WiFi...");
  }
  
  Serial.println("\n=== WiFi Connection ===");
  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);
  
  // Disconnect and set mode before connecting
  WiFi.disconnect(true);
  delay(100);
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  
  Serial.print("Connecting to WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  int maxAttempts = 30; // Increased to 30 attempts (15 seconds)
  
  while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
    delay(500);
    Serial.print(".");
    
    // Update LCD every 2 seconds to show it's still trying
    if (lcdAvailable && attempts % 4 == 0) {
      lcd.setCursor(0, 1);
      lcd.print("WiFi...");
      String dots = "";
      for (int i = 0; i < (attempts / 4) % 4; i++) {
        dots += ".";
      }
      lcd.print(dots);
    }
    
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    
    if (lcdAvailable) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("WiFi Connected!");
      lcd.setCursor(0, 1);
      String ipStr = WiFi.localIP().toString();
      if (ipStr.length() > 16) {
        ipStr = ipStr.substring(0, 13) + "...";
      }
      lcd.print(ipStr);
      delay(2000);
      // Fetch stats immediately after WiFi connects
      fetchParkingStats();
    } else {
      // Even without LCD, fetch stats
      fetchParkingStats();
    }
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    Serial.print("Status code: ");
    Serial.println(WiFi.status());
    Serial.println("Possible reasons:");
    Serial.println("  - Wrong SSID or password");
    Serial.println("  - WiFi router too far away");
    Serial.println("  - Router not broadcasting 2.4GHz network");
    Serial.println("  - Network not available");
    
    if (lcdAvailable) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("WiFi Failed!");
      lcd.setCursor(0, 1);
      lcd.print("Check Serial");
      delay(3000);
      
      // Continue anyway - system can still work if WiFi reconnects later
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("System Running");
      lcd.setCursor(0, 1);
      lcd.print("WiFi: Retrying...");
      delay(2000);
      updateLCD();
    }
  }
}

// Handle QR code detection
void onQrCodeFound(const char *qrCode) {
  unsigned long qrDetectTime = millis(); // Time when QR was detected
  String qrData = String(qrCode);
  
  // Check cooldown to prevent duplicate scans
  if (qrData != lastScannedQR || (millis() - lastScanTime) > SCAN_COOLDOWN) {
    scanCount++; // Increment scan counter
    
    Serial.println("\n========================================");
    Serial.println("📷 QR CODE DETECTED!");
    Serial.println("========================================");
    Serial.print("Scan #");
    Serial.println(scanCount);
    Serial.println("QR Data: " + qrData);
    Serial.print("Detection Time: ");
    Serial.print(qrDetectTime);
    Serial.println(" ms");
    
    // Check memory before processing
    size_t freeHeap = ESP.getFreeHeap();
    size_t minFreeHeap = ESP.getMinFreeHeap();
    Serial.print("💾 Free Heap: ");
    Serial.print(freeHeap);
    Serial.print(" bytes | Min Free: ");
    Serial.print(minFreeHeap);
    Serial.println(" bytes");
    
    if (freeHeap < 50000) { // Warning if less than 50KB free
      Serial.println("⚠️ WARNING: Low memory! Consider rebooting soon.");
    }
    
    Serial.println("Starting verification...\n");
    
    verifyQRCode(qrData);
    
    // Check memory after processing
    size_t freeHeapAfter = ESP.getFreeHeap();
    Serial.print("💾 Free Heap After: ");
    Serial.print(freeHeapAfter);
    Serial.print(" bytes | Memory Used: ");
    Serial.print(freeHeap - freeHeapAfter);
    Serial.println(" bytes");
    
    lastScannedQR = qrData;
    lastScanTime = millis();
  } else {
    Serial.println("⚠️ Duplicate scan ignored (cooldown active)");
  }
}

// Verify QR code with backend
void verifyQRCode(String qrCode) {
  unsigned long scanStartTime = millis(); // Start timing
  
  if (WiFi.status() != WL_CONNECTED) {
    showError("No WiFi");
    return;
  }
  
  HTTPClient http;
  http.begin(SERVER_URL);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(10000); // 10 second timeout for HTTP request
  
  // Create JSON payload (use reserve to prevent fragmentation)
  StaticJsonDocument<200> doc;
  doc["qrCode"] = qrCode;
  String jsonPayload;
  jsonPayload.reserve(100); // Reserve memory to prevent fragmentation
  serializeJson(doc, jsonPayload);
  
  Serial.println("Sending to server: " + jsonPayload);
  unsigned long httpStartTime = millis();
  int httpCode = http.POST(jsonPayload);
  unsigned long httpDuration = millis() - httpStartTime;
  
  Serial.print("⏱️ HTTP request took: ");
  Serial.print(httpDuration);
  Serial.println(" ms");
  
  if (httpCode > 0) {
    String response;
    response.reserve(600); // Reserve memory for response
    response = http.getString();
    Serial.println("Response code: " + String(httpCode));
    Serial.println("Response: " + response);
    
    StaticJsonDocument<512> responseDoc;
    DeserializationError error = deserializeJson(responseDoc, response);
    
    // Clear response string to free memory immediately
    response = "";
    
    if (!error) {
      bool valid = responseDoc["valid"];
      String message = responseDoc["message"];
      
      if (valid) {
        unsigned long beforeSuccessTime = millis();
        showSuccess(message);
        unsigned long successDuration = millis() - beforeSuccessTime;
        
        unsigned long beforeGateTime = millis();
        openGate();
        unsigned long gateOpenDuration = millis() - beforeGateTime;
        
        unsigned long totalTime = millis() - scanStartTime;
        
        Serial.println("\n⏱️ TIMING BREAKDOWN:");
        Serial.print("   HTTP Request: ");
        Serial.print(httpDuration);
        Serial.println(" ms");
        Serial.print("   Success Display: ");
        Serial.print(successDuration);
        Serial.println(" ms");
        Serial.print("   Gate Opening: ");
        Serial.print(gateOpenDuration);
        Serial.println(" ms");
        Serial.print("   ⏱️ TOTAL TIME (Scan → Gate Open): ");
        Serial.print(totalTime);
        Serial.println(" ms\n");
        
        fetchParkingStats(); // Update stats after successful entry
      } else {
        showError(message);
      }
    } else {
      showError("Invalid response");
    }
  } else {
    showError("Server error");
    Serial.println("HTTP Error: " + String(http.errorToString(httpCode).c_str()));
  }
  
  // Properly close HTTP connection and free resources
  http.end();
  
  // Force garbage collection by clearing any remaining strings
  yield(); // Give ESP32 time to clean up
}

// Open the gate and wait for car to pass
void openGate() {
  Serial.println("Opening gate...");
  if (lcdAvailable) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Gate Opening");
    lcd.setCursor(0, 1);
    lcd.print("Please proceed");
  }
  
  gateServo.write(GATE_OPEN_ANGLE);
  waitForCarToPass();
  closeGate();
}

// Wait for car to pass through the gate
void waitForCarToPass() {
  Serial.println("Waiting for car to pass...");
  unsigned long startTime = millis();
  bool carDetected = false;
  
  while (millis() - startTime < GATE_TIMEOUT) {
    int sensorValue = digitalRead(IR_SENSOR_PIN);
    
    // IR sensor outputs LOW when object is detected
    if (sensorValue == LOW) {
      if (!carDetected) {
        Serial.println("Car detected passing through...");
        carDetected = true;
      }
    } else if (carDetected) {
      // Car has passed
      Serial.println("Car passed through gate");
      delay(500); // Small delay to ensure car is clear
      return;
    }
    
    delay(50);
  }
  
  if (!carDetected) {
    Serial.println("Timeout: No car detected");
  } else {
    Serial.println("Timeout: Car still in gate area");
  }
}

// Close the gate
void closeGate() {
  Serial.println("Closing gate...");
  gateServo.write(GATE_CLOSED_ANGLE);
  if (lcdAvailable) {
    updateLCD();
  }
}

// Show success message on LCD
void showSuccess(String message) {
  Serial.println("SUCCESS: " + message);
  if (lcdAvailable) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("ACCESS GRANTED");
    lcd.setCursor(0, 1);
    lcd.print(message.substring(0, 16));
    delay(2000);
    updateLCD();
  }
}

// Show error message on LCD
void showError(String message) {
  Serial.println("ERROR: " + message);
  if (lcdAvailable) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("ACCESS DENIED");
    lcd.setCursor(0, 1);
    lcd.print(message.substring(0, 16));
    delay(2000);
    updateLCD();
  }
}

// Fetch parking statistics from backend
void fetchParkingStats() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️ Cannot fetch stats: WiFi not connected");
    return;
  }
  
  HTTPClient http;
  String statsUrl = "https://parking-intelligent-backend.onrender.com/api/stats";
  http.begin(statsUrl);
  http.setTimeout(5000); // 5 second timeout
  
  Serial.println("📊 Fetching parking stats...");
  int httpCode = http.GET();
  
  if (httpCode > 0) {
    Serial.print("✅ Stats response code: ");
    Serial.println(httpCode);
    
    String response = http.getString();
    Serial.print("Response: ");
    Serial.println(response);
    
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, response);
    
    if (error) {
      Serial.print("❌ JSON parse error: ");
      Serial.println(error.c_str());
    } else if (doc.containsKey("slots")) {
      // Backend returns stats in slots object
      if (doc["slots"].containsKey("available") && doc["slots"].containsKey("booked")) {
        availableSpots = doc["slots"]["available"];
        bookedSpots = doc["slots"]["booked"];
        
        Serial.print("📊 Available spots: ");
        Serial.print(availableSpots);
        Serial.print(" / Booked spots: ");
        Serial.println(bookedSpots);
        
        updateLCD();
      } else {
        Serial.println("⚠️ Stats response missing 'available' or 'booked' fields");
      }
    } else {
      Serial.println("⚠️ Stats response missing 'slots' object");
    }
  } else {
    Serial.print("❌ HTTP request failed! Error code: ");
    Serial.println(httpCode);
    Serial.print("Error: ");
    Serial.println(http.errorToString(httpCode).c_str());
  }
  
  http.end();
}

// Update LCD with current status
void updateLCD() {
  if (!lcdAvailable) {
    return; // Skip if LCD not available
  }
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Available: ");
  lcd.print(availableSpots);
  lcd.print("/");
  lcd.print(totalSpots);
  
  lcd.setCursor(0, 1);
  lcd.print("Booked: ");
  lcd.print(bookedSpots);
  
  // Debug: Print to serial as well
  Serial.print("📺 LCD Updated - Available: ");
  Serial.print(availableSpots);
  Serial.print("/");
  Serial.print(totalSpots);
  Serial.print(" | Booked: ");
  Serial.println(bookedSpots);
}

// Check for exit events (periodically refresh stats to stay in sync)
void checkForExitEvents() {
  // Simply refresh stats periodically to keep LCD updated
  // Exit gate handles exit verification, entry gate just needs current stats
  fetchParkingStats();
}