/*
 * ESP32-CAM Exit Gate QR Scanner
 * 
 * This code runs on ESP32-CAM module at the parking exit gate.
 * It scans QR codes and verifies them with the backend server.
 * 
 * Hardware Requirements:
 * - ESP32-CAM module
 * - Servo motor (for gate control) connected to GPIO 12
 * - IR obstacle sensor connected to GPIO 14
 * 
 * Note: LCD display is shared with entry gate (connected to entry gate ESP32)
 * 
 * Libraries Required:
 * - ESP32QRCodeReader (install from Library Manager)
 * - WiFi (built-in)
 * - HTTPClient (built-in)
 * - ArduinoJson (install from Library Manager)
 * - ESP32Servo (install from Library Manager)
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include "esp_camera.h"
#include "ESP32QRCodeReader.h"

// ==================== CONFIGURATION ====================
// WiFi credentials - CHANGE THESE!
const char* WIFI_SSID = "TT_B7F6_2.4G";
const char* WIFI_PASSWORD = "XUDH9UD7Ac";

// Backend server URL - Cloud deployment (works 24/7!)
// Your backend is now hosted on Render.com
const char* SERVER_URL = "https://parking-intelligent-backend.onrender.com/api/parking/exit";

// For local testing, use your PC's IP:
// const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/exit";

// Hardware pins
const int SERVO_PIN = 12;      // Servo motor for gate
const int IR_SENSOR_PIN = 14;  // IR obstacle sensor for car detection

// Gate settings
const int GATE_CLOSED_ANGLE = 0;    // Servo angle when gate is closed
const int GATE_OPEN_ANGLE = 90;     // Servo angle when gate is open
const int GATE_TIMEOUT = 60000;     // Timeout if car doesn't pass (60 seconds)

// ==================== FUNCTION DECLARATIONS ====================
void onQrCodeFound(const char *qrCode);
void waitForCarToPass();

// ==================== GLOBALS ====================
Servo gateServo;
ESP32QRCodeReader qrReader(CAMERA_MODEL_AI_THINKER);
String lastScannedQR = "";
unsigned long lastScanTime = 0;
const unsigned long SCAN_COOLDOWN = 3000; // Prevent duplicate scans (ms)

// Parking status tracking
int availableSpots = 5;  // Initial available spots
int bookedSpots = 1;     // Initial booked spots

// Note: Camera pin definitions are handled by ESP32QRCodeReader library
// CAMERA_MODEL_AI_THINKER automatically configures all camera pins

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n=================================");
  Serial.println("ESP32-CAM Exit Gate Scanner");
  Serial.println("=================================\n");

  // Initialize pins
  Serial.println("[1/4] Initializing pins...");
  pinMode(IR_SENSOR_PIN, INPUT);
  Serial.println("✅ Pins initialized");

  // Initialize servo
  Serial.println("[2/4] Initializing servo...");
  gateServo.attach(SERVO_PIN);
  Serial.println("Closing gate...");
  closeGate();
  Serial.println("✅ Servo initialized");

  // Connect to WiFi
  Serial.println("[3/4] Connecting to WiFi...");
  connectWiFi();

  // Initialize QR reader (it will initialize the camera internally)
  Serial.println("[4/4] Initializing camera and QR reader...");
  Serial.println("   This may take 5-10 seconds...");
  Serial.flush(); // Make sure all output is sent before blocking operation
  
  unsigned long camStartTime = millis();
  qrReader.setup();
  qrReader.beginOnCore(1); // Start QR detection on core 1
  unsigned long camInitTime = millis() - camStartTime;
  
  Serial.print("✅ Camera initialized in ");
  Serial.print(camInitTime);
  Serial.println(" ms");

  Serial.println("\n=================================");
  Serial.println("✅ System ready!");
  Serial.println("=================================\n");
  Serial.println("Waiting for QR codes...\n");
}

// ==================== QR CODE CALLBACK ====================
void onQrCodeFound(const char *qrCode) {
  String qrData = String(qrCode);
  
  // Check cooldown to prevent duplicate scans
  if (qrData != lastScannedQR || (millis() - lastScanTime) > SCAN_COOLDOWN) {
    Serial.println("\n📷 QR Code detected!");
    Serial.print("Data: ");
    Serial.println(qrData);
    
    // Verify with backend
    verifyQRCode(qrData);
    
    lastScannedQR = qrData;
    lastScanTime = millis();
  }
}

// ==================== MAIN LOOP ====================
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

  // Check if QR code was detected
  struct QRCodeData qrCodeData;
  if (qrReader.receiveQrCode(&qrCodeData, 100)) {
    if (qrCodeData.valid) {
      onQrCodeFound((const char*)qrCodeData.payload);
    }
  }
  
  delay(100); // Small delay between scans
}

// ==================== FUNCTIONS ====================

void connectWiFi() {
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
  int maxAttempts = 30; // 30 attempts (15 seconds)
  
  while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    Serial.print("Status code: ");
    Serial.println(WiFi.status());
    Serial.println("Possible reasons:");
    Serial.println("  - Wrong SSID or password");
    Serial.println("  - WiFi router too far away");
    Serial.println("  - Router not broadcasting 2.4GHz network");
    Serial.println("  - Network not available");
  }
}


void verifyQRCode(String qrCode) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("❌ No WiFi connection!");
    showError("No WiFi");
    return;
  }

  HTTPClient http;
  http.begin(SERVER_URL);
  http.addHeader("Content-Type", "application/json");

  // Create JSON payload
  StaticJsonDocument<200> doc;
  doc["qrCode"] = qrCode;
  
  String jsonPayload;
  serializeJson(doc, jsonPayload);

  Serial.println("Sending exit verification to server...");
  Serial.println("URL: " + String(SERVER_URL));
  Serial.println("Payload: " + jsonPayload);
  
  int httpCode = http.POST(jsonPayload);
  String response = http.getString();
  
  Serial.print("Response code: ");
  Serial.println(httpCode);
  Serial.print("Response: ");
  Serial.println(response);

  if (httpCode > 0) {
    // Parse JSON response
    StaticJsonDocument<512> responseDoc;
    DeserializationError error = deserializeJson(responseDoc, response);

    if (!error) {
      bool valid = responseDoc["valid"];
      String message = responseDoc["message"];
      String slotId = responseDoc["slotId"];
      String action = responseDoc["action"];
      String actualDuration = responseDoc.containsKey("actualDuration") ? String(responseDoc["actualDuration"].as<const char*>()) : "";

      if (valid && action == "open_gate") {
        // SUCCESS - Open gate
        availableSpots++;
        if (bookedSpots > 0) bookedSpots--;
        
        Serial.println("\n✅ EXIT GRANTED!");
        Serial.println("=====================");
        Serial.print("Slot: ");
        Serial.println(slotId);
        if (actualDuration) {
          Serial.print("Parking duration: ");
          Serial.println(actualDuration);
        }
        Serial.print("Message: ");
        Serial.println(message);
        Serial.println("=====================\n");
        
        showSuccess(message);
        openGate();
        
        // Fetch updated stats from server
        // fetchParkingStats(); // Uncomment if you implement this function
      } else {
        // DENIED
        String reason = responseDoc["message"] ? responseDoc["message"].as<String>() : "Unknown error";
        
        Serial.println("\n❌ EXIT DENIED!");
        Serial.println("=====================");
        Serial.print("Reason: ");
        Serial.println(reason);
        if (responseDoc.containsKey("action") && responseDoc["action"] == "deny") {
          Serial.println("Action: Access Denied");
        }
        Serial.println("=====================\n");
        
        showError(reason);
      }
    } else {
      Serial.println("\n❌ JSON parse error!");
      Serial.println("=====================");
      Serial.print("Error: ");
      Serial.println(error.c_str());
      Serial.print("Response: ");
      Serial.println(response);
      Serial.println("=====================\n");
      
      showError("Server response error");
    }
  } else {
    Serial.println("\n❌ HTTP request failed!");
    Serial.println("=====================");
    Serial.print("Error code: ");
    Serial.println(httpCode);
    Serial.print("Error: ");
    Serial.println(http.errorToString(httpCode).c_str());
    Serial.println("=====================\n");
    
    showError("Server connection failed");
  }

  http.end();
}

void openGate() {
  Serial.println("🚪 Opening gate...");
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

void closeGate() {
  Serial.println("🚪 Closing gate...");
  gateServo.write(GATE_CLOSED_ANGLE);
}

void showSuccess(String message) {
  Serial.println("✅ SUCCESS: " + message);
  delay(1000);
}

void showError(String message) {
  Serial.println("❌ ERROR: " + message);
  delay(2000);
}

void blinkError() {
  Serial.println("❌ BLINKING ERROR");
  for (int i = 0; i < 5; i++) {
    Serial.println("Error blink " + String(i + 1));
    delay(200);
  }
}

// ==================== END OF FILE ====================
