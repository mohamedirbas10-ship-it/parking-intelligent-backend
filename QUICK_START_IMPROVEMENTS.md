# 🚀 Quick Start Guide - Improved Backend & Scheduling Fix

## 🎯 What's New?

### ✅ CRITICAL FIX: Reservation Scheduling Bug
**Problem:** When someone booked a slot from 12 PM to 2 PM at 8 AM, it showed as "reserved" immediately instead of staying "available" until 12 PM.

**Solution:** ✅ **FIXED!** Slots now show correct availability based on actual reservation time!

### ✅ NEW FEATURES:
1. 🔐 **JWT Authentication** - Secure login with tokens
2. 🔒 **Password Hashing** - bcrypt encryption for passwords
3. 💾 **MongoDB Database** - Persistent storage (no data loss on restart)
4. 🔌 **WebSocket Real-time** - Instant updates (no more polling)
5. 📅 **Future Bookings** - Book slots for later times
6. ⏰ **Auto-expire** - Automatic cleanup of old bookings
7. 🌍 **Environment Variables** - Secure configuration

---

## 📋 Prerequisites

1. **Node.js** (v14 or higher) - [Download](https://nodejs.org/)
2. **MongoDB** (Local or Atlas) - [MongoDB Atlas Free](https://www.mongodb.com/cloud/atlas)
3. **Git** - [Download](https://git-scm.com/)

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Install Dependencies
```bash
cd backend
npm install
```

### Step 2: Configure Environment
```bash
# Copy example environment file
cp .env.example .env

# Edit .env file with your settings
# On Windows: notepad .env
# On Mac/Linux: nano .env
```

### Step 3: Set Up MongoDB

**Option A: MongoDB Atlas (Cloud - Recommended)**
1. Go to https://www.mongodb.com/cloud/atlas
2. Create free account
3. Create cluster (free tier)
4. Get connection string
5. Update `.env`:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/parking_intelligent
```

**Option B: Local MongoDB**
1. Install MongoDB locally
2. Update `.env`:
```env
MONGODB_URI=mongodb://localhost:27017/parking_intelligent
```

**Option C: No MongoDB (Fallback)**
- Server will use in-memory storage automatically
- Data lost on restart but works for testing

### Step 4: Generate JWT Secret
```bash
# Generate secure random key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Copy output and paste into .env:
JWT_SECRET=paste-generated-key-here
```

### Step 5: Start Server
```bash
npm start
```

**Success! You should see:**
```
========================================
🚗 Smart Car Parking API Server v2.0
========================================
📡 Server running on http://localhost:3000
✅ MongoDB connected successfully
🅿️  Parking: 1 floor, 6 slots (A1-A6)

✨ New Features:
   🔐 JWT Authentication
   🔒 Password Hashing (bcrypt)
   🔌 WebSocket Real-time Updates
   📅 Time-based Slot Availability
   🚀 Future Booking Support
========================================
```

---

## 🧪 Test the Scheduling Fix

### Test 1: Future Booking
```bash
# 1. Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'

# Save the token from response!

# 2. Book slot for 2 hours in the future
# Replace <TOKEN> with your actual token
curl -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "slotId": "A1",
    "duration": 2,
    "startTime": "2024-01-15T14:00:00.000Z"
  }'

# 3. Check slots NOW (before 2PM)
curl http://localhost:3000/api/parking/slots

# ✅ Result: Slot A1 shows as "available" (with nextBooking info)
# ✅ At 2PM: Slot A1 automatically changes to "booked"
```

### Test 2: Entry Time Validation
```bash
# Try to enter before booking starts
curl -X POST http://localhost:3000/api/parking/entry \
  -H "Content-Type: application/json" \
  -d '{
    "qrCode": "PARKING-your-qr-code"
  }'

# ✅ Response (if too early):
# {
#   "valid": false,
#   "message": "Booking starts at 2:00 PM. Too early!",
#   "action": "deny"
# }
```

### Test 3: Overlap Prevention
```bash
# Book A1 for 12PM-2PM
curl -X POST http://localhost:3000/api/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "slotId": "A1",
    "duration": 2,
    "startTime": "2024-01-15T12:00:00.000Z"
  }'

# Try to book A1 for 1PM-3PM (overlaps!)
curl -X POST http://localhost:3000/api/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "slotId": "A1",
    "duration": 2,
    "startTime": "2024-01-15T13:00:00.000Z"
  }'

# ✅ Response: "Slot is not available for the selected time"

# Book A1 for 2PM-4PM (no overlap)
curl -X POST http://localhost:3000/api/bookings \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "slotId": "A1",
    "duration": 2,
    "startTime": "2024-01-15T14:00:00.000Z"
  }'

# ✅ Success!
```

---

## 🔧 Configuration Options

### `.env` File Explained
```env
# Server port (default: 3000)
PORT=3000

# Environment (development/production)
NODE_ENV=development

# MongoDB connection string
# Local: mongodb://localhost:27017/parking_intelligent
# Atlas: mongodb+srv://user:pass@cluster.mongodb.net/parking_intelligent
MONGODB_URI=your-connection-string

# JWT secret key (generate with crypto)
# IMPORTANT: Use a long random string in production!
JWT_SECRET=your-super-secret-jwt-key-change-this

# JWT token expiration time
JWT_EXPIRES_IN=7d

# CORS origin (set to your frontend URL in production)
CORS_ORIGIN=*
```

---

## 📱 Flutter App Updates Needed

### Step 1: Update API Service
Add JWT token support to `lib/services/api_service.dart`:

```dart
class ApiService {
  static String? _token;
  
  static void setToken(String token) {
    _token = token;
  }
  
  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
  
  // Update all API calls to use _headers
  Future<Map<String, dynamic>> createBooking(...) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings'),
      headers: _headers, // Use authenticated headers
      body: jsonEncode({...}),
    );
    // ...
  }
}
```

### Step 2: Save Token After Login
In your login screen:

```dart
final result = await apiService.login(email: email, password: password);
if (result['success']) {
  final token = result['token'];
  final user = result['user'];
  
  // Save token
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
  
  // Set token for API calls
  ApiService.setToken(token);
}
```

### Step 3: Load Token on Startup
In `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    ApiService.setToken(token);
  }
  
  runApp(const ParkingApp());
}
```

### Step 4: Add Future Booking UI
Add time picker for booking start time:

```dart
DateTime? _startTime;

// Add button to select future time
ElevatedButton(
  onPressed: () async {
    final time = await showDatePicker(...);
    setState(() => _startTime = time);
  },
  child: Text('Book for Later'),
)

// Pass startTime to booking API
await createBooking(
  slotId: slotId,
  duration: duration,
  startTime: _startTime, // Can be null for immediate booking
);
```

---

## 📊 API Changes Summary

### Authentication Required
These endpoints now require JWT token in `Authorization: Bearer <token>` header:
- `POST /api/bookings` - Create booking
- `GET /api/bookings/user/:userId` - Get user bookings
- `GET /api/bookings/:bookingId` - Get booking details
- `DELETE /api/bookings/:bookingId` - Cancel booking

### New Request Fields
**Create Booking:**
```json
{
  "slotId": "A1",
  "duration": 2,
  "startTime": "2024-01-15T14:00:00.000Z"  // NEW: Optional, for future bookings
}
```

### New Response Fields
**Slot Status:**
```json
{
  "id": "A1",
  "status": "available",
  "bookedBy": null,
  "bookingId": null,
  "nextBooking": {  // NEW: Info about next reservation
    "start": "2024-01-15T14:00:00.000Z",
    "end": "2024-01-15T16:00:00.000Z",
    "userId": "user-id"
  }
}
```

**Login/Register:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIs...",  // NEW: JWT token
  "user": {
    "id": "user-id",
    "email": "test@example.com",
    "name": "Test User"
  }
}
```

---

## 🐛 Troubleshooting

### Issue: "MongoDB connection error"
**Solution:**
- Check MONGODB_URI in `.env`
- Verify MongoDB is running (if local)
- Check network connection (if Atlas)
- Server will use in-memory fallback automatically

### Issue: "Invalid token" or "Authentication required"
**Solution:**
- Make sure you're sending token in Authorization header
- Format: `Authorization: Bearer <token>`
- Check token hasn't expired (7 days default)
- Login again to get new token

### Issue: "Slot is not available for the selected time"
**Solution:**
- Check if another booking overlaps with your time
- Try different time slot
- Check next booking info: `GET /api/parking/slots`

### Issue: "Booking starts at X. Too early!"
**Solution:**
- This is expected! You're trying to enter before booking time
- Wait until booking start time
- Check booking details for correct time

---

## 🎮 Using Postman for Testing

### 1. Import Collection
Create Postman collection with these requests:

**Register:**
- POST `{{baseUrl}}/api/auth/register`
- Body: `{"email":"test@example.com","password":"password123","name":"Test"}`
- Save token from response

**Login:**
- POST `{{baseUrl}}/api/auth/login`
- Body: `{"email":"test@example.com","password":"password123"}`
- Save token from response

**Get Slots:**
- GET `{{baseUrl}}/api/parking/slots`

**Create Booking (Immediate):**
- POST `{{baseUrl}}/api/bookings`
- Headers: `Authorization: Bearer {{token}}`
- Body: `{"slotId":"A1","duration":2}`

**Create Booking (Future):**
- POST `{{baseUrl}}/api/bookings`
- Headers: `Authorization: Bearer {{token}}`
- Body: `{"slotId":"A2","duration":2,"startTime":"2024-01-15T14:00:00.000Z"}`

**Get My Bookings:**
- GET `{{baseUrl}}/api/bookings/user/{{userId}}`
- Headers: `Authorization: Bearer {{token}}`

**Cancel Booking:**
- DELETE `{{baseUrl}}/api/bookings/{{bookingId}}`
- Headers: `Authorization: Bearer {{token}}`

### 2. Set Environment Variables
```
baseUrl = http://localhost:3000
token = (paste token after login)
userId = (paste user id after login)
bookingId = (paste booking id after creation)
```

---

## 📚 Documentation Files

- **IMPROVEMENTS_AND_FIXES.md** - Detailed documentation of all changes
- **README.md** - Main project documentation
- **.env.example** - Environment variables template
- **server.js** - Main server file with all improvements

---

## ✅ Verification Checklist

After setup, verify:
- [ ] Server starts without errors
- [ ] MongoDB connected (or fallback message shown)
- [ ] Can register new user
- [ ] Can login and receive token
- [ ] Can create immediate booking
- [ ] Can create future booking
- [ ] Slot shows as available before booking time
- [ ] Slot changes to booked at booking time
- [ ] Can cancel booking
- [ ] Slot becomes available after cancellation
- [ ] WebSocket connection works
- [ ] Auto-expire runs every minute

---

## 🚀 Deploy to Production

### Render.com (Free)
1. Push code to GitHub
2. Create Render account
3. New → Web Service
4. Connect GitHub repo
5. Set environment variables in Render dashboard:
   - `MONGODB_URI` - Your MongoDB Atlas URL
   - `JWT_SECRET` - Generated secret key
   - `NODE_ENV=production`
6. Deploy!

### Environment Variables on Render
```
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/parking
JWT_SECRET=your-generated-secret
JWT_EXPIRES_IN=7d
NODE_ENV=production
PORT=3000
```

---

## 🎉 Success!

You now have:
- ✅ Fixed reservation scheduling bug
- ✅ Secure JWT authentication
- ✅ Encrypted passwords (bcrypt)
- ✅ Persistent MongoDB storage
- ✅ Real-time WebSocket updates
- ✅ Future booking support
- ✅ Production-ready backend

**Next Steps:**
1. Update Flutter app with JWT support
2. Add future booking UI
3. Test thoroughly
4. Deploy to production
5. Celebrate! 🎉

---

**Need Help?**
- Check `IMPROVEMENTS_AND_FIXES.md` for detailed documentation
- Review console logs for errors
- Test with Postman first before Flutter app
- Ensure `.env` is properly configured

**Version:** 2.0.0  
**Last Updated:** January 2024