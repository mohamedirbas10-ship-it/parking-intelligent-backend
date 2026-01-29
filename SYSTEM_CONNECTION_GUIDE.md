# 🚗 Smart Parking System - Complete Connection Guide

## 📋 System Overview

Your parking system consists of 3 main components:
1. **ESP32-CAM Entry Gate** (QR Scanner + LCD Display)
2. **ESP32-CAM Exit Gate** (QR Scanner)
3. **Backend Server** (Node.js API)
4. **Flutter Mobile App** (User Interface)

---

## 🔌 ESP32-CAM Entry Gate Hardware Connections

### **Required Components:**
- ESP32-CAM module
- **I2C LCD Display (16x2) - SHARED DISPLAY**
- Servo Motor (SG90)
- IR Obstacle Sensor
- Breadboard & Jumper Wires

### **Pin Connections:**

| Component | ESP32-CAM Pin | Notes |
|-----------|---------------|-------|
| **LCD Display (I2C) - SHARED** | | |
| LCD SDA | GPIO 15 | I2C Data |
| LCD SCL | GPIO 16 | I2C Clock |
| LCD VCC | 3.3V | Power |
| LCD GND | GND | Ground |
| **Servo Motor** | | |
| Servo Signal | GPIO 12 | PWM Control |
| Servo VCC | 5V | Power (use external supply) |
| Servo GND | GND | Ground |
| **IR Sensor** | | |
| IR Signal | GPIO 14 | Digital Input |
| IR VCC | 5V | Power |
| IR GND | GND | Ground |

### **Power Supply:**
- **ESP32-CAM**: 5V via USB or external supply
- **Servo Motor**: Separate 5V supply (high current)
- **LCD & Sensors**: Can use ESP32's 3.3V/5V pins

---

## 🔌 ESP32-CAM Exit Gate Hardware Connections

### **Required Components:**
- ESP32-CAM module
- Servo Motor (SG90)
- IR Obstacle Sensor
- Breadboard & Jumper Wires

### **Pin Connections:**
**Note: LCD display is shared with entry gate (connected only to entry gate ESP32)**

| Component | ESP32-CAM Pin | Notes |
|-----------|---------------|-------|
| Servo Signal | GPIO 12 | PWM Control |
| IR Signal | GPIO 14 | Digital Input |

---

## 🌐 Backend Server Setup

### **1. Local Development Setup:**

```bash
# Navigate to backend folder
cd backend

# Install dependencies
npm install

# Start server
npm start
```

### **2. Cloud Deployment (Render.com):**

Your backend is already deployed at:
```
https://parking-intelligent-backend.onrender.com
```

### **3. API Endpoints:**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/stats` | GET | Get parking statistics |
| `/api/parking/entry` | POST | Verify QR at entry |
| `/api/parking/exit` | POST | Verify QR at exit |
| `/api/bookings` | POST | Create booking |
| `/api/parking/slots` | GET | Get all slots |

---

## 📱 Flutter App Configuration

### **1. Update API URLs:**

In `lib/services/api_service.dart`, ensure URLs point to your backend:

```dart
// For production (cloud)
static const String baseUrl = 'https://parking-intelligent-backend.onrender.com';

// For local testing
// static const String baseUrl = 'http://192.168.1.100:3000';
```

### **2. Run Flutter App:**

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run
```

---

## 🔧 ESP32-CAM Configuration

### **1. WiFi Setup:**

In both entry and exit gate codes, update WiFi credentials:

```cpp
const char* WIFI_SSID = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
```

### **2. Server URLs:**

**Entry Gate** (`esp32cam_entry_gate.ino`):
```cpp
const char* SERVER_URL = "https://parking-intelligent-backend.onrender.com/api/parking/entry";
String statsUrl = "https://parking-intelligent-backend.onrender.com/api/stats";
```

**Exit Gate** (`esp32cam_exit_gate.ino`):
```cpp
const char* SERVER_URL = "https://parking-intelligent-backend.onrender.com/api/parking/exit";
```

### **3. LCD Address:**

If LCD doesn't work, scan for I2C address:

```cpp
// Try these common addresses:
const int LCD_ADDR = 0x27;  // Most common
// const int LCD_ADDR = 0x3F;  // Alternative
```

---

## 🔄 System Flow

### **Complete Parking Process:**

1. **📱 User Books Slot** (Flutter App)
   - User selects parking slot
   - App creates booking via backend API
   - User receives QR code

2. **🚗 Entry Process** (ESP32-CAM Entry Gate)
   - User scans QR code
   - ESP32 sends QR to backend for verification
   - If valid: Gate opens, LCD updates, slot becomes occupied
   - If invalid: Access denied, error message

3. **🚗 Exit Process** (ESP32-CAM Exit Gate)
   - User scans same QR code
   - ESP32 sends QR to backend for verification
   - If valid: Gate opens, slot becomes available
   - If invalid: Access denied

4. **📊 Real-time Updates**
   - LCD display updates every 5-10 seconds
   - Flutter app refreshes slot status
   - Backend maintains accurate counts

---

## 🧪 Testing Your System

### **1. Test Backend Server:**

```bash
# Test health endpoint
curl https://parking-intelligent-backend.onrender.com/

# Test stats endpoint
curl https://parking-intelligent-backend.onrender.com/api/stats
```

### **2. Test ESP32-CAM Entry Gate:**

1. **Upload code** to ESP32-CAM
2. **Open Serial Monitor** (115200 baud)
3. **Check for these messages:**
   ```
   ✅ WiFi connected!
   ✅ LCD initialized successfully
   📊 Fetching parking stats...
   ✅ Stats updated: Available: 4, Occupied: 1, Booked: 2
   📱 LCD Updated - Available: 4, Booked: 2
   ```

4. **Test QR scanning** with a valid booking QR code

### **3. Test Flutter App:**

1. **Create a booking** in the app
2. **Note the QR code** generated
3. **Use that QR code** at the ESP32-CAM entry gate

---

## 🔧 Troubleshooting

### **Common Issues:**

#### **LCD Display Not Working:**
- Check I2C wiring (SDA=15, SCL=16)
- Scan for correct I2C address (0x27 or 0x3F)
- Verify power supply (3.3V or 5V)
- Check Serial Monitor for "LCD initialization failed"

#### **WiFi Connection Issues:**
- Verify WiFi credentials in code
- Check WiFi signal strength
- Ensure 2.4GHz network (ESP32 doesn't support 5GHz)

#### **Servo Motor Not Moving:**
- Check power supply (servo needs 5V, high current)
- Verify PWM pin connection (GPIO 12)
- Test servo with simple sweep code

#### **QR Code Not Detected:**
- Ensure good lighting
- Hold QR code steady in front of camera
- Check camera initialization in Serial Monitor

#### **Backend Connection Failed:**
- Verify server URL in ESP32 code
- Check if backend server is running
- Test API endpoints with curl/Postman

### **Debug Commands:**

```bash
# Check ESP32 serial output
# Open Arduino IDE Serial Monitor at 115200 baud

# Test backend API
curl -X POST https://parking-intelligent-backend.onrender.com/api/parking/entry \
  -H "Content-Type: application/json" \
  -d '{"qrCode":"test-qr-code"}'

# Check Flutter app logs
flutter logs
```

---

## 📋 Pre-Deployment Checklist

### **Hardware:**
- [ ] ESP32-CAM Entry Gate wired correctly
- [ ] ESP32-CAM Exit Gate wired correctly
- [ ] LCD display working and showing stats
- [ ] Servo motors responding to commands
- [ ] IR sensors detecting objects
- [ ] LEDs and buzzer functioning

### **Software:**
- [ ] WiFi credentials updated in both ESP32 codes
- [ ] Server URLs pointing to correct backend
- [ ] Backend server deployed and accessible
- [ ] Flutter app connecting to backend
- [ ] QR code generation and scanning working

### **Integration:**
- [ ] Entry gate opens on valid QR scan
- [ ] Exit gate opens on valid QR scan
- [ ] LCD updates with real-time stats
- [ ] Flutter app shows correct slot status
- [ ] Backend maintains accurate booking data

---

## 🚀 Next Steps

1. **Upload updated ESP32 codes** with LCD improvements
2. **Test the complete flow** from booking to exit
3. **Monitor LCD display** for real-time updates
4. **Fine-tune timing** and sensor sensitivity
5. **Deploy to production** environment

Your smart parking system is now ready to connect all components together! 🎉
