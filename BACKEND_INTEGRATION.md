# Backend Integration Guide

## ✅ Setup Complete!

Your Flutter app is now connected to the Node.js backend!

## 🚀 What's Been Done

### 1. Backend Server
- **Status**: ✅ Running on `http://localhost:3000`
- **Technology**: Node.js + Express
- **Features**:
  - User authentication (register/login)
  - Parking slot management (5 slots: A1-A5)
  - Booking system with QR codes
  - Statistics API

### 2. Flutter App Updates
- ✅ Added `http` package for API calls
- ✅ Created `ApiService` class (`lib/services/api_service.dart`)
- ✅ Created `Booking` model (`lib/models/booking.dart`)
- ✅ Updated `ParkingSpot` model with backend fields
- ✅ Updated `LoginScreen` to use backend API
- ✅ Updated `RegisterScreen` to use backend API

## 📱 Testing the Connection

### Step 1: Ensure Backend is Running
The backend server is already running on port 3000. You can verify by opening:
```
http://localhost:3000
```
You should see: `{"message": "Smart Car Parking API is running", ...}`

### Step 2: Configure API URL for Your Device

Open `lib/services/api_service.dart` and update the `baseUrl`:

```dart
// For testing on different devices:
// - Desktop/Web: http://localhost:3000
// - Android Emulator: http://10.0.2.2:3000
// - iOS Simulator: http://localhost:3000
// - Physical Device: http://YOUR_COMPUTER_IP:3000

static const String baseUrl = 'http://localhost:3000';
```

**For Physical Device:**
1. Find your computer's IP address:
   - Windows: Run `ipconfig` in Command Prompt, look for IPv4 Address
   - Example: `192.168.1.100`
2. Update baseUrl to: `http://192.168.1.100:3000`
3. Make sure your phone and computer are on the same WiFi network

### Step 3: Run the Flutter App
```bash
flutter run
```

### Step 4: Test Authentication
1. **Register a new account**:
   - Open the app
   - Click "Sign Up"
   - Enter name, email, and password
   - Click "Register"
   
2. **Login**:
   - Enter the email and password you just registered
   - Click "Sign In"

## 🔌 Available API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Parking Slots
- `GET /api/parking/slots` - Get all parking slots
- `PATCH /api/parking/slots/:slotId` - Update slot status

### Bookings
- `POST /api/bookings` - Create new booking
- `GET /api/bookings/user/:userId` - Get user's bookings
- `GET /api/bookings/:bookingId` - Get booking details
- `DELETE /api/bookings/:bookingId` - Cancel booking

### Statistics
- `GET /api/stats` - Get system statistics

## 🔧 Next Steps to Fully Integrate

### Update Parking Slots Screen
The parking slots screen still uses local data. To connect it to the backend:

1. Import ApiService in `parking_slots_screen.dart`
2. Load slots from API using `apiService.getParkingSlots()`
3. Create bookings using `apiService.createBooking()`

### Update History Screen
Connect the history screen to show bookings from the backend:

1. Import ApiService in `history_screen.dart`
2. Load bookings using `apiService.getUserBookings(userId)`

## 🐛 Troubleshooting

### "Network error" or "Connection refused"
- ✅ Check backend server is running: `http://localhost:3000`
- ✅ Verify the `baseUrl` in `api_service.dart` matches your setup
- ✅ For physical devices, use your computer's IP address
- ✅ Disable firewall or allow port 3000

### "CORS error" (Web only)
The backend already has CORS enabled, but if you still see errors:
- Restart the backend server
- Clear browser cache

### Backend not starting
```bash
cd backend
npm install
node server.js
```

## 📊 Testing with API Client

You can test the backend directly using tools like Postman or curl:

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\",\"name\":\"Test User\"}"
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

### Get Parking Slots
```bash
curl http://localhost:3000/api/parking/slots
```

## 🎯 Current Status

✅ **Working**:
- Backend server running
- User registration via API
- User login via API
- API service layer created
- Models updated

⚠️ **Needs Integration**:
- Parking slots screen (still using local data)
- Booking creation (needs to call API)
- History screen (needs to load from API)

## 📝 Notes

- The backend uses **in-memory storage** (data resets on server restart)
- For production, you'll need to add a database (MongoDB, PostgreSQL, etc.)
- User passwords are stored in plain text (add hashing for production!)
- No JWT tokens yet (add for better security)

## 🚀 Running Everything

**Terminal 1 - Backend:**
```bash
cd backend
node server.js
```

**Terminal 2 - Flutter:**
```bash
flutter run
```

---

**Your backend is ready! Start testing the authentication flow now! 🎉**
