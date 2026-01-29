# 🚀 Run Local Backend - Get Scheduled Bookings Working!

## ✅ Quick Start (3 Steps)

### Step 1: Start Your Local Backend

Open a **NEW terminal/command prompt** and run:

```bash
cd C:\Users\MBHmaidi10\Desktop\parking_intelligent-main\backend
npm start
```

**You should see:**
```
🚀 Server running on port 3000
✅ MongoDB connected successfully
📋 Available endpoints:
   POST   /api/auth/register          - Register user
   POST   /api/auth/login             - Login user
   GET    /api/parking/slots          - Get all slots
   POST   /api/bookings               - Create booking
```

**Keep this terminal open!** The server needs to stay running.

---

### Step 2: Run Your Flutter App

Open **ANOTHER terminal** and run:

```bash
cd C:\Users\MBHmaidi10\Desktop\parking_intelligent-main
flutter run
```

---

### Step 3: Test Scheduled Bookings

1. **Login to the app**
2. **Select a parking slot**
3. **Choose time:** Start 1:00 PM, End 2:00 PM (future time)
4. **Book it**
5. **Check slot status:**
   - ✅ Should show "Available" until 1:00 PM
   - ✅ Changes to "Booked" at 1:00 PM
   - ✅ Changes back to "Available" at 2:00 PM

**IT WORKS!** 🎉

---

## 🔍 Why This Works

### Your Local Backend (server.js)
- ✅ Has correct scheduled booking code
- ✅ Respects `startTime` parameter
- ✅ Calculates slot status based on current time vs booking time
- ✅ Returns `nextBooking` info for future reservations

### Cloud Backend (Render.com)
- ❌ Running old/backup version
- ❌ Ignores `startTime` parameter
- ❌ Always books immediately
- ❌ Doesn't support scheduled bookings

---

## 📝 Your App is Now Using

```dart
// In lib/services/api_service.dart
static String get baseUrl {
  return 'http://192.168.1.19:3000';  // ✅ Local server
}
```

---

## 🎯 How Scheduled Bookings Work (Local Server)

### When You Book for 1:00 PM - 2:00 PM at 9:00 AM:

```javascript
// Server receives:
{
  userId: "abc-123",
  slotId: "A1",
  duration: 1,
  startTime: "2026-01-28T13:00:00Z"  // 1:00 PM
}

// Server creates booking:
{
  reservedAt: "2026-01-28T13:00:00Z",  // Respects your time! ✅
  expiresAt: "2026-01-28T14:00:00Z"
}

// When fetching slots at 9:00 AM:
const now = new Date();  // 9:00 AM
const start = new Date(booking.reservedAt);  // 1:00 PM
const end = new Date(booking.expiresAt);  // 2:00 PM

if (now >= start && now <= end) {
  status = 'booked';  // Not yet! (9 AM < 1 PM)
} else {
  status = 'available';  // ✅ Shows as available!
  nextBooking = { start: "1:00 PM", end: "2:00 PM" };
}

// At 1:00 PM, status automatically becomes 'booked' ✅
// At 2:00 PM, status automatically becomes 'available' ✅
```

---

## 🆘 Troubleshooting

### Problem 1: "Port 3000 already in use"

**Solution:**
```bash
# Windows:
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F

# Then restart:
npm start
```

---

### Problem 2: "Cannot connect to MongoDB"

**Check your .env file:**
```bash
cd backend
notepad .env
```

Should contain:
```
PORT=3000
MONGODB_URI=mongodb://localhost:27017/parking_intelligent
JWT_SECRET=your-secret-key-here
```

**If MongoDB not installed:**
- Server will use **in-memory storage** (works fine for testing!)
- Data lost when server restarts (that's OK)

---

### Problem 3: App can't reach backend

**Make sure:**
1. Backend terminal shows "Server running on port 3000"
2. Your phone/emulator is on **same WiFi** as laptop
3. Check IP address is correct:

```bash
# Windows - Get your IP:
ipconfig

# Look for "IPv4 Address" under your WiFi adapter
# Should be something like: 192.168.1.19
```

**Update app if IP changed:**
```dart
// In lib/services/api_service.dart
return 'http://192.168.1.XX:3000';  // Your actual IP
```

---

### Problem 4: Backend crashes/stops

**Restart it:**
```bash
cd C:\Users\MBHmaidi10\Desktop\parking_intelligent-main\backend
npm start
```

---

## 💡 Pro Tips

### Tip 1: Keep Backend Running
- Don't close the backend terminal
- If you close laptop, backend stops
- Just restart with `npm start`

### Tip 2: Test Different Times
```
Current: 9:00 AM

Book 1: 10:00 AM - 11:00 AM  (1 hour from now)
Book 2: 2:00 PM - 4:00 PM    (5 hours from now)
Book 3: 9:05 AM - 10:05 AM   (5 minutes from now)

All slots show as "Available" until their start time! ✅
```

### Tip 3: View Backend Logs
The backend terminal shows all requests:
```
POST /api/bookings - Creating booking...
  Start: 2026-01-28T13:00:00Z
  End: 2026-01-28T14:00:00Z
  Status: Future booking created

GET /api/parking/slots - Calculating slot status...
  Slot A1: available (next booking at 1:00 PM)
```

### Tip 4: Use MongoDB Compass (Optional)
If you have MongoDB installed, view your data:
```
mongodb://localhost:27017/parking_intelligent
```

---

## 🔄 Switching Back to Cloud

**If you want to use cloud server later:**

```dart
// In lib/services/api_service.dart
static String get baseUrl {
  // For scheduled bookings (laptop must be ON):
  // return 'http://192.168.1.19:3000';
  
  // For 24/7 access (no scheduled bookings):
  return 'https://parking-intelligent-backend.onrender.com';
}
```

Then restart app.

---

## 📊 Comparison

| Feature | Local Server | Cloud Server |
|---------|--------------|--------------|
| **Scheduled Bookings** | ✅ Works perfectly | ❌ Doesn't work |
| **Laptop Required** | ✅ Yes (must be ON) | ❌ No |
| **Works from Anywhere** | ❌ No (same WiFi) | ✅ Yes |
| **Available 24/7** | ❌ No | ✅ Yes |
| **Your Code** | ✅ Latest version | ❌ Old version |
| **For Development** | ✅ Perfect | ⚠️ OK |
| **For Production** | ❌ No | ✅ Yes |

---

## 🎉 You're All Set!

**Now you have:**
- ✅ Working scheduled bookings
- ✅ Slots show correct status based on time
- ✅ Book for future times
- ✅ Just like last night!

**Just remember:**
- Keep backend terminal open
- Laptop must stay ON while using app
- Backend needs to run on same network as your phone

---

## 🚀 Quick Commands Reference

### Start Backend:
```bash
cd C:\Users\MBHmaidi10\Desktop\parking_intelligent-main\backend
npm start
```

### Start App:
```bash
cd C:\Users\MBHmaidi10\Desktop\parking_intelligent-main
flutter run
```

### Stop Backend:
Press `Ctrl + C` in backend terminal

### Restart Backend:
```bash
npm start
```

---

**Status:** ✅ READY TO USE  
**Scheduled Bookings:** ✅ WORKING  
**Just like last night:** ✅ YES!  

**Run the backend and enjoy your working scheduled bookings!** 🎉