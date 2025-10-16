# 🚗 ESP32-CAM Integration Guide

Complete guide for setting up your parking system with 2x ESP32-CAM modules for entry and exit gates.

---

## 📋 Table of Contents
1. [System Overview](#system-overview)
2. [Hardware Requirements](#hardware-requirements)
3. [Software Requirements](#software-requirements)
4. [Testing Before Hardware](#testing-before-hardware)
5. [ESP32-CAM Setup](#esp32-cam-setup)
6. [Backend API Reference](#backend-api-reference)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 System Overview

### Complete Flow:

```
USER ARRIVES
    ↓
Opens Flutter App → Shows QR Code
    ↓
ESP32-CAM #1 (Entry Gate) → Scans QR
    ↓
Backend API → Verifies QR Code
    ↓
✅ Valid → Gate Opens → Slot marked "occupied"
    ↓
USER PARKS
    ↓
USER LEAVES
    ↓
Shows Same QR Code
    ↓
ESP32-CAM #2 (Exit Gate) → Scans QR
    ↓
Backend API → Verifies QR Code
    ↓
✅ Valid → Gate Opens → Slot marked "available"
```

### Key Features:
- ✅ **Entry Gate**: Verifies booking, marks slot as occupied
- ✅ **Exit Gate**: Frees slot, calculates parking duration
- ✅ **Prevents duplicate entry/exit**
- ✅ **Checks expiration time**
- ✅ **Real-time slot status updates**

---

## 🛠️ Hardware Requirements

### For Each Gate (x2):

| Component | Quantity | Price (approx) | Purpose |
|-----------|----------|----------------|---------|
| ESP32-CAM | 1 | $10 | QR code scanning |
| Servo Motor (SG90) | 1 | $3 | Gate control |
| 5V Power Supply | 1 | $5 | Power ESP32-CAM |
| Green LED | 1 | $0.10 | Success indicator |
| Red LED | 1 | $0.10 | Error indicator |
| Buzzer (optional) | 1 | $1 | Audio feedback |
| Resistors (220Ω) | 2 | $0.10 | LED current limiting |
| Jumper Wires | 10 | $2 | Connections |

**Total per gate: ~$21**
**Total for both gates: ~$42**

### Wiring Diagram:

```
ESP32-CAM Connections:
├── GPIO 12 → Servo Signal (Orange wire)
├── GPIO 2  → Green LED (+ 220Ω resistor)
├── GPIO 4  → Red LED (+ 220Ω resistor)
├── GPIO 13 → Buzzer (optional)
├── 5V      → Servo VCC (Red wire) + Power Supply
└── GND     → Servo GND (Brown wire) + LEDs + Power Supply
```

---

## 💻 Software Requirements

### 1. Arduino IDE Setup

**Install Arduino IDE:**
- Download from: https://www.arduino.cc/en/software
- Version 2.0+ recommended

**Add ESP32 Board Support:**
1. Open Arduino IDE
2. Go to `File → Preferences`
3. Add to "Additional Board Manager URLs":
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Go to `Tools → Board → Boards Manager`
5. Search "ESP32" and install "esp32 by Espressif Systems"

### 2. Required Libraries

Install these from `Tools → Manage Libraries`:

| Library | Version | Purpose |
|---------|---------|---------|
| ESP32QRCodeReader | Latest | QR code detection |
| ArduinoJson | 6.x | JSON parsing |
| ESP32Servo | Latest | Servo control |

**Note:** WiFi and HTTPClient are built-in, no installation needed.

---

## 🧪 Testing Before Hardware

### Step 1: Start Backend Server

```bash
cd backend
node server.js
```

You should see:
```
🚗 Smart Car Parking API Server
📡 Server running on http://localhost:3000
🅿️  Parking: 1 floor, 5 slots (A1-A5)
```

### Step 2: Test with Web Scanner

1. Open `backend/qr-scanner-test.html` in your browser
2. Click "Start Camera Scanner" (or use manual input)
3. Test the flow:

**Test Entry Gate:**
1. Book a slot in your Flutter app
2. Get the QR code (e.g., `PARKING-abc123-def456`)
3. In web scanner, select "ENTRY GATE"
4. Scan or manually enter the QR code
5. ✅ Should show: "Access granted - Welcome!"

**Test Exit Gate:**
1. Use the same QR code
2. In web scanner, select "EXIT GATE"
3. Scan or manually enter the QR code
4. ✅ Should show: "Exit granted - Thank you!"
5. Slot should now be available again

### Step 3: Test API Directly (Optional)

**Test Entry:**
```bash
curl -X POST http://localhost:3000/api/parking/entry \
  -H "Content-Type: application/json" \
  -d "{\"qrCode\":\"PARKING-abc123-def456\"}"
```

**Test Exit:**
```bash
curl -X POST http://localhost:3000/api/parking/exit \
  -H "Content-Type: application/json" \
  -d "{\"qrCode\":\"PARKING-abc123-def456\"}"
```

---

## 🔧 ESP32-CAM Setup

### Step 1: Configure WiFi and Server

**Edit both `.ino` files:**

```cpp
// Change these lines:
const char* WIFI_SSID = "YOUR_WIFI_SSID";        // Your WiFi name
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD"; // Your WiFi password

// For entry gate:
const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/entry";

// For exit gate:
const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/exit";
```

**Find Your Computer's IP:**
- Windows: Open CMD and run `ipconfig`, look for "IPv4 Address"
- Example: `192.168.1.100`

### Step 2: Upload to ESP32-CAM

**Hardware Connection for Programming:**
1. Connect FTDI programmer to ESP32-CAM:
   - FTDI TX → ESP32 RX
   - FTDI RX → ESP32 TX
   - FTDI GND → ESP32 GND
   - FTDI 5V → ESP32 5V
2. Connect GPIO 0 to GND (programming mode)

**Upload Process:**
1. Open `esp32cam_entry_gate.ino` in Arduino IDE
2. Select `Tools → Board → ESP32 Arduino → AI Thinker ESP32-CAM`
3. Select correct COM port
4. Click Upload
5. Wait for "Hard resetting via RTS pin..."
6. Disconnect GPIO 0 from GND
7. Press RESET button on ESP32-CAM

**Repeat for exit gate** with `esp32cam_exit_gate.ino`

### Step 3: Test ESP32-CAM

**Open Serial Monitor** (`Tools → Serial Monitor`, 115200 baud):

You should see:
```
=================================
ESP32-CAM Entry Gate Scanner
=================================

Connecting to WiFi: YourWiFi
✅ WiFi connected!
IP Address: 192.168.1.101
✅ Camera initialized
✅ System ready!
Waiting for QR codes...
```

**Test scanning:**
1. Open your Flutter app
2. Show QR code on phone screen
3. Hold phone in front of ESP32-CAM
4. Serial monitor should show:
```
📷 QR Code detected!
Data: PARKING-abc123-def456
Sending to server...
Response code: 200
✅ ACCESS GRANTED!
Slot: A1
🚪 Opening gate...
```

---

## 📡 Backend API Reference

### Entry Gate Endpoint

**POST** `/api/parking/entry`

**Request:**
```json
{
  "qrCode": "PARKING-abc123-def456"
}
```

**Success Response (200):**
```json
{
  "valid": true,
  "message": "Access granted - Welcome!",
  "action": "open_gate",
  "slotId": "A1",
  "slotName": "A1",
  "expiresAt": "2025-10-16T02:30:00.000Z",
  "duration": 2
}
```

**Error Responses:**

| Code | Reason | Message |
|------|--------|---------|
| 404 | Invalid QR | "Invalid QR code or booking not found" |
| 409 | Already entered | "Already entered. Use this QR code at exit." |
| 403 | Expired | "QR code expired" |

### Exit Gate Endpoint

**POST** `/api/parking/exit`

**Request:**
```json
{
  "qrCode": "PARKING-abc123-def456"
}
```

**Success Response (200):**
```json
{
  "valid": true,
  "message": "Exit granted - Thank you!",
  "action": "open_gate",
  "slotId": "A1",
  "slotName": "A1",
  "enteredAt": "2025-10-16T00:30:00.000Z",
  "exitedAt": "2025-10-16T02:15:00.000Z",
  "actualDuration": "105 minutes",
  "bookedDuration": "2 hours"
}
```

**Error Responses:**

| Code | Reason | Message |
|------|--------|---------|
| 404 | Invalid QR | "Invalid QR code" |
| 400 | Not entered yet | "Please use entry gate first" |
| 409 | Already exited | "Already exited" |

---

## 🐛 Troubleshooting

### ESP32-CAM Issues

**Problem: Camera init failed**
- Check camera ribbon cable is properly connected
- Try different power supply (needs stable 5V, 2A)
- Reset ESP32-CAM and try again

**Problem: WiFi not connecting**
- Double-check SSID and password
- Ensure 2.4GHz WiFi (ESP32 doesn't support 5GHz)
- Check WiFi signal strength
- Try moving closer to router

**Problem: QR code not detected**
- Ensure good lighting
- Hold QR code 10-20cm from camera
- Make sure QR code is clear and not blurry
- Try increasing QR code size on phone

**Problem: HTTP error / Server not responding**
- Verify backend server is running
- Check IP address in code matches your computer
- Ensure ESP32-CAM and computer on same network
- Try pinging the server IP from another device
- Disable firewall temporarily

### Backend Issues

**Problem: "CORS error"**
- Backend already has CORS enabled
- Restart backend server
- Clear browser cache

**Problem: "Booking not found"**
- Make sure you created a booking first in Flutter app
- Check QR code matches exactly (case-sensitive)
- Verify backend server has the booking (check `/api/stats`)

**Problem: "Already entered"**
- This QR was already used at entry
- Use exit gate instead
- Or cancel booking and create new one

### Hardware Issues

**Problem: Servo not moving**
- Check servo is connected to GPIO 12
- Verify servo has separate 5V power
- Test servo with simple sketch first
- Check servo isn't mechanically stuck

**Problem: LEDs not lighting**
- Check polarity (long leg = positive)
- Verify 220Ω resistors are in series
- Test LEDs with multimeter
- Check GPIO pins (2 for green, 4 for red)

---

## 📊 System Status Check

### Check Backend Status:
```bash
curl http://localhost:3000/api/stats
```

Response shows:
- Total users
- Active bookings
- Slot availability

### Check ESP32-CAM Status:
- Open Serial Monitor
- Should show "Waiting for QR codes..."
- If errors, check WiFi/camera initialization

### Check Flutter App:
- Login and book a slot
- Verify QR code is displayed
- Check slot shows as "BOOKED"

---

## 🎓 Quick Start Checklist

### Before Buying Hardware:
- [ ] Backend server running
- [ ] Flutter app working
- [ ] Can book slots and see QR codes
- [ ] Tested with web scanner (`qr-scanner-test.html`)
- [ ] Verified entry/exit flow works

### After Buying Hardware:
- [ ] Arduino IDE installed
- [ ] ESP32 board support added
- [ ] Libraries installed
- [ ] WiFi credentials configured
- [ ] Server IP address updated
- [ ] Code uploaded to both ESP32-CAMs
- [ ] Servo motors connected and tested
- [ ] LEDs working
- [ ] Full system test completed

---

## 🚀 Next Steps

1. **Test everything with web scanner first**
2. **Buy hardware only after testing**
3. **Set up one gate at a time** (start with entry)
4. **Test thoroughly before deploying**
5. **Consider adding:**
   - Display screen for messages
   - Better enclosure for weather protection
   - Battery backup
   - Admin override button

---

## 📞 Support

If you encounter issues:
1. Check Serial Monitor output
2. Verify network connectivity
3. Test API endpoints manually
4. Review this guide's troubleshooting section

---

**Your system is ready for ESP32-CAM integration! 🎉**

Test with the web scanner first, then proceed with hardware setup when ready.
