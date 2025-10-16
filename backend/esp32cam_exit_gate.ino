/*
 * ESP32-CAM Exit Gate QR Scanner
 * 
 * This code runs on ESP32-CAM module at the parking exit gate.
 * It scans QR codes and verifies them with the backend server.
 * 
 * Hardware Requirements:
 * - ESP32-CAM module
 * - Servo motor (for gate control) connected to GPIO 12
 * - LED indicators (optional):
 *   - Green LED on GPIO 2 (success)
 *   - Red LED on GPIO 4 (error)
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
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Backend server URL - CHANGE THIS!
// Use your computer's IP address (find with ipconfig on Windows)
// Example: "http://192.168.1.100:3000"
const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/exit";

// Hardware pins
const int SERVO_PIN = 12;      // Servo motor for gate
const int GREEN_LED = 2;       // Success indicator
const int RED_LED = 4;         // Error indicator
const int BUZZER_PIN = 13;     // Optional buzzer

// Gate settings
const int GATE_CLOSED_ANGLE = 0;    // Servo angle when gate is closed
const int GATE_OPEN_ANGLE = 90;     // Servo angle when gate is open
const int GATE_OPEN_DURATION = 5000; // How long gate stays open (ms)

// ==================== GLOBALS ====================
Servo gateServo;
ESP32QRCodeReader qrReader;
String lastScannedQR = "";
unsigned long lastScanTime = 0;
const unsigned long SCAN_COOLDOWN = 3000; // Prevent duplicate scans (ms)

// ==================== CAMERA CONFIGURATION ====================
// ESP32-CAM AI-Thinker model pin definitions
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n=================================");
  Serial.println("ESP32-CAM Exit Gate Scanner");
  Serial.println("=================================\n");

  // Initialize pins
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(RED_LED, LOW);
  digitalWrite(BUZZER_PIN, LOW);

  // Initialize servo
  gateServo.attach(SERVO_PIN);
  closeGate();

  // Connect to WiFi
  connectWiFi();

  // Initialize camera
  if (!initCamera()) {
    Serial.println("❌ Camera initialization failed!");
    blinkError();
    while (1) delay(1000); // Halt
  }

  // Initialize QR reader
  qrReader.setup();
  qrReader.beginOnCore(1); // Run QR detection on core 1

  Serial.println("✅ System ready!");
  Serial.println("Waiting for QR codes...\n");
  
  // Success beep
  beep(2);
}

// ==================== MAIN LOOP ====================
void loop() {
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected! Reconnecting...");
    connectWiFi();
  }

  // Capture and process QR code
  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    delay(100);
    return;
  }

  // Try to read QR code from image
  qrReader.setFrameBuffer(fb->buf, fb->width, fb->height, fb->format);
  
  if (qrReader.decodeQRCode()) {
    String qrData = qrReader.getQRCodeText();
    
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

  esp_camera_fb_return(fb);
  delay(100); // Small delay between scans
}

// ==================== FUNCTIONS ====================

void connectWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi connection failed!");
  }
}

bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_GRAYSCALE; // QR codes work better in grayscale
  config.frame_size = FRAMESIZE_QVGA; // 320x240
  config.jpeg_quality = 12;
  config.fb_count = 1;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x\n", err);
    return false;
  }
  
  Serial.println("✅ Camera initialized");
  return true;
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

  Serial.println("Sending to server...");
  int httpCode = http.POST(jsonPayload);

  if (httpCode > 0) {
    String response = http.getString();
    Serial.print("Response code: ");
    Serial.println(httpCode);
    Serial.print("Response: ");
    Serial.println(response);

    // Parse JSON response
    StaticJsonDocument<512> responseDoc;
    DeserializationError error = deserializeJson(responseDoc, response);

    if (!error) {
      bool valid = responseDoc["valid"];
      String message = responseDoc["message"];
      String slotId = responseDoc["slotId"];
      String actualDuration = responseDoc["actualDuration"];

      if (valid) {
        // SUCCESS - Open gate
        Serial.println("✅ EXIT GRANTED!");
        Serial.print("Slot freed: ");
        Serial.println(slotId);
        Serial.print("Parking duration: ");
        Serial.println(actualDuration);
        Serial.print("Message: ");
        Serial.println(message);
        
        showSuccess(message);
        openGate();
      } else {
        // DENIED
        Serial.println("❌ EXIT DENIED!");
        Serial.print("Reason: ");
        Serial.println(message);
        
        showError(message);
      }
    } else {
      Serial.println("❌ JSON parse error!");
      showError("Parse error");
    }
  } else {
    Serial.print("❌ HTTP error: ");
    Serial.println(httpCode);
    showError("Server error");
  }

  http.end();
}

void openGate() {
  Serial.println("🚪 Opening gate...");
  gateServo.write(GATE_OPEN_ANGLE);
  digitalWrite(GREEN_LED, HIGH);
  beep(1);
  
  delay(GATE_OPEN_DURATION);
  
  closeGate();
}

void closeGate() {
  Serial.println("🚪 Closing gate...");
  gateServo.write(GATE_CLOSED_ANGLE);
  digitalWrite(GREEN_LED, LOW);
}

void showSuccess(String message) {
  digitalWrite(GREEN_LED, HIGH);
  beep(3); // Three short beeps for exit
  delay(1000);
  digitalWrite(GREEN_LED, LOW);
}

void showError(String message) {
  digitalWrite(RED_LED, HIGH);
  beep(1, 500); // One long beep
  delay(2000);
  digitalWrite(RED_LED, LOW);
}

void blinkError() {
  for (int i = 0; i < 5; i++) {
    digitalWrite(RED_LED, HIGH);
    delay(200);
    digitalWrite(RED_LED, LOW);
    delay(200);
  }
}

void beep(int times, int duration = 100) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(duration);
    digitalWrite(BUZZER_PIN, LOW);
    if (i < times - 1) delay(100);
  }
}
