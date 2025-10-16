# 🔗 Update URLs After Render Deployment

After deploying to Render, you'll get a URL like: `https://parking-backend-xxxx.onrender.com`

You need to update this URL in 3 places:

---

## 1️⃣ Flutter App - API Service

**File:** `lib/services/api_service.dart`

**Find this section (around line 11-23):**
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  } else if (Platform.isAndroid) {
    return 'http://192.168.1.11:3000';
  } else if (Platform.isIOS) {
    return 'http://192.168.1.11:3000';
  } else {
    return 'http://localhost:3000';
  }
}
```

**Replace with:**
```dart
static String get baseUrl {
  // Use your Render URL here
  return 'https://parking-backend-xxxx.onrender.com';
  
  // For local testing, uncomment this:
  // if (kIsWeb) return 'http://localhost:3000';
  // if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Emulator
  // return 'http://localhost:3000';
}
```

**Replace `parking-backend-xxxx.onrender.com` with your actual Render URL!**

---

## 2️⃣ ESP32-CAM Entry Gate

**File:** `backend/esp32cam_entry_gate.ino`

**Find this line (around line 37):**
```cpp
const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/entry";
```

**Replace with:**
```cpp
const char* SERVER_URL = "https://parking-backend-xxxx.onrender.com/api/parking/entry";
```

**Replace `parking-backend-xxxx.onrender.com` with your actual Render URL!**

---

## 3️⃣ ESP32-CAM Exit Gate

**File:** `backend/esp32cam_exit_gate.ino`

**Find this line (around line 37):**
```cpp
const char* SERVER_URL = "http://192.168.1.100:3000/api/parking/exit";
```

**Replace with:**
```cpp
const char* SERVER_URL = "https://parking-backend-xxxx.onrender.com/api/parking/exit";
```

**Replace `parking-backend-xxxx.onrender.com` with your actual Render URL!**

---

## ✅ After Updating

### For Flutter App:
```bash
# Rebuild and run your app
flutter clean
flutter pub get
flutter run
```

### For ESP32-CAM:
1. Open the `.ino` files in Arduino IDE
2. Upload to your ESP32-CAM boards
3. Open Serial Monitor to verify connection

---

## 🧪 Test Your Setup

### Test Backend:
Visit: `https://parking-backend-xxxx.onrender.com`

Should show:
```json
{
  "message": "Smart Car Parking API is running",
  "version": "1.0.0"
}
```

### Test Flutter App:
1. Open the app
2. Try to book a parking slot
3. Check if QR code is generated
4. View "My QR Codes" to see your booking

### Test ESP32-CAM:
1. Open Serial Monitor in Arduino IDE
2. Should see: "Connected to backend"
3. Scan a QR code
4. Gate should open if valid

---

## 🎯 Quick Reference

| Component | File | Line | What to Change |
|-----------|------|------|----------------|
| Flutter App | `lib/services/api_service.dart` | ~11 | `baseUrl` getter |
| Entry Gate | `backend/esp32cam_entry_gate.ino` | ~37 | `SERVER_URL` |
| Exit Gate | `backend/esp32cam_exit_gate.ino` | ~37 | `SERVER_URL` |

---

## 💡 Pro Tip

Create a constant file for easier management:

**Create:** `lib/config/app_config.dart`
```dart
class AppConfig {
  static const String backendUrl = 'https://parking-backend-xxxx.onrender.com';
  static const String apiVersion = 'v1';
}
```

Then use it in `api_service.dart`:
```dart
import '../config/app_config.dart';

static String get baseUrl => AppConfig.backendUrl;
```

---

**Need help updating these files? Just share your Render URL and I'll do it for you!**
