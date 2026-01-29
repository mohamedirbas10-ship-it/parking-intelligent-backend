# 🧪 Manual Testing Guide

## ✅ Quick Test - Is Everything Working?

### Step 1: Test Server Health

Open your web browser and go to:
```
http://localhost:3000
```

**You should see:**
```json
{
  "message": "Smart Car Parking API is running",
  "version": "2.0.0",
  "database": "In-Memory (Fallback)" or "MongoDB",
  "features": [...]
}
```

✅ If you see this → Server is working!

---

### Step 2: Test Registration (Using Browser or Postman)

**Method:** POST  
**URL:** `http://localhost:3000/api/auth/register`  
**Body (JSON):**
```json
{
  "email": "test@example.com",
  "password": "password123",
  "name": "Test User"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGci...",
  "user": {
    "id": "...",
    "email": "test@example.com",
    "name": "Test User"
  }
}
```

✅ **Save the token!** You'll need it for next steps.

---

### Step 3: Test Login

**Method:** POST  
**URL:** `http://localhost:3000/api/auth/login`  
**Body (JSON):**
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGci...",
  "user": {...}
}
```

✅ Token received → Authentication works!

---

### Step 4: Test Get Parking Slots

**Method:** GET  
**URL:** `http://localhost:3000/api/parking/slots`  
**Headers:** None needed

**Expected Response:**
```json
{
  "success": true,
  "slots": [
    {
      "id": "A1",
      "status": "available",
      "bookedBy": null,
      "bookingId": null,
      "nextBooking": null
    },
    // ... 5 more slots (A2-A6)
  ]
}
```

✅ 6 slots returned → Slots endpoint works!

---

### Step 5: Test Create Booking (CRITICAL - Tests Scheduling Fix!)

**Method:** POST  
**URL:** `http://localhost:3000/api/bookings`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
```
**Body (Immediate Booking):**
```json
{
  "slotId": "A1",
  "duration": 2
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "booking": {
    "id": "...",
    "slotId": "A1",
    "duration": 2,
    "reservedAt": "2024-01-27T...",
    "expiresAt": "2024-01-27T...",
    "qrCode": "PARKING-xxx-xxx",
    "status": "active"
  }
}
```

✅ Booking created → Booking system works!

---

### Step 6: Test FUTURE Booking (SCHEDULING BUG FIX TEST!)

**Method:** POST  
**URL:** `http://localhost:3000/api/bookings`  
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
```
**Body (Future Booking - 2 hours from now):**
```json
{
  "slotId": "A2",
  "duration": 2,
  "startTime": "2024-01-27T16:00:00.000Z"
}
```
*Note: Change the startTime to 2 hours from your current time*

**Expected Response:**
```json
{
  "success": true,
  "booking": {
    "slotId": "A2",
    "reservedAt": "2024-01-27T16:00:00.000Z",
    "expiresAt": "2024-01-27T18:00:00.000Z",
    ...
  }
}
```

✅ Future booking created!

---

### Step 7: **CRITICAL TEST** - Verify Slot Status

**Method:** GET  
**URL:** `http://localhost:3000/api/parking/slots`

**Look at Slot A2:**
```json
{
  "id": "A2",
  "status": "available",  // ← Should be AVAILABLE (not booked!)
  "nextBooking": {
    "start": "2024-01-27T16:00:00.000Z",
    "end": "2024-01-27T18:00:00.000Z"
  }
}
```

✅ **If status is "available" → SCHEDULING BUG IS FIXED!** 🎉  
❌ If status is "booked" → Bug not fixed (shouldn't happen)

**This proves the fix:**
- Booked for 4 PM (future)
- Current time is before 4 PM
- Slot shows as "available" ✅
- At 4 PM, it will automatically change to "booked"

---

### Step 8: Test Cancellation

**Method:** DELETE  
**URL:** `http://localhost:3000/api/bookings/BOOKING_ID`  
*Replace BOOKING_ID with the id from Step 5*

**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking cancelled successfully"
}
```

✅ Booking cancelled → Cancellation works!

---

### Step 9: Verify Slot Freed

**Method:** GET  
**URL:** `http://localhost:3000/api/parking/slots`

**Check Slot A1:**
```json
{
  "id": "A1",
  "status": "available",  // ← Should be available again
  "bookedBy": null,
  "bookingId": null
}
```

✅ Slot is available → Cancellation properly frees slot!

---

## 🎯 Using Postman (Recommended)

1. **Download Postman:** https://www.postman.com/downloads/
2. **Create a new collection:** "Parking API Tests"
3. **Add requests** for each test above
4. **Set environment variable:** `token` = (your token from login)
5. **Use:** `{{token}}` in Authorization headers

---

## 🌐 Using Browser (Simple Test)

1. Open browser
2. Go to: `http://localhost:3000`
3. Should see JSON response
4. For other tests, use browser extensions like:
   - **REST Client** (VS Code extension)
   - **Thunder Client** (VS Code extension)
   - **Postman**

---

## ✅ Success Checklist

After all tests:

- [ ] Server health check returns v2.0
- [ ] Can register new user
- [ ] Can login and receive token
- [ ] Can get parking slots (6 slots)
- [ ] Can create immediate booking
- [ ] Can create future booking
- [ ] **Future booking shows slot as AVAILABLE** ✅
- [ ] Can cancel booking
- [ ] Cancelled slot becomes available
- [ ] Token required for booking operations

---

## 🎉 **All Tests Pass?**

**Congratulations!** Your backend is working perfectly:
- ✅ Authentication working
- ✅ Booking system working
- ✅ **SCHEDULING BUG FIXED** 🎊
- ✅ Cancellation working
- ✅ Real-time updates working

---

## 📱 Next: Test with Flutter App

Now run your Flutter app and test:
1. Register/Login in app
2. Book a slot
3. View QR code
4. Restart app (should auto-login)
5. Cancel booking

---

**Happy Testing!** 🚀