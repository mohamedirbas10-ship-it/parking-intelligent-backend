# Smart Car Parking App - Features

## 🚀 Complete App Flow

### 1. **Splash Screen** (3 seconds)
- Modern car illustration
- "CAR PARKING" title with description
- Automatically checks if user is logged in
- Navigates to Login or Home based on status

### 2. **Login Screen**
- Clean "Welcome" greeting (no "Back")
- Circular parking icon (no blue square)
- Email and password fields
- Sign up option
- Professional, minimal design

### 3. **Parking Slots Screen** (Main Screen)
- **Blue Header**: "SMART CAR PARKING" with parking icon
- **Floor Selector**: Dropdown to choose 1st, 2nd, or 3rd floor
- **Entry Label**: Shows parking entry point
- **Parking Layout**: Two columns with center road divider
- **Slot Features**:
  - Slot numbers (top and bottom)
  - Car icon if occupied
  - Empty box if available
  - Slot ID (A1, A2, A3, etc.)
  - BOOK button (blue) for available slots
  - OCCUPIED label (red) for taken slots
  - VIEW QR button (green) for your booked slots

## ⏰ Time Selection & QR Code Features

### When You Click "BOOK":

1. **Time Selection Dialog Opens**
   - Choose parking duration: 1H, 2H, 3H, 4H, 6H, 8H, 12H, or 24H
   - Visual selection with blue highlight
   - Confirm or Cancel options

2. **After Confirmation**:
   - Slot is marked as booked (green border, car icon)
   - Success message shows duration
   - Automatically navigates to QR Code screen

### QR Code Screen Shows:

- **QR Code**: Scannable code for parking entry
- **Spot Number**: Your reserved slot (e.g., "Spot A2")
- **Validity**: Duration you selected (e.g., "2 hours")
- **Reserved Time**: Exact date and time of booking
- **Instructions**: Info about showing QR to attendant
- **Back Button**: Return to parking slots

### Accessing Your Booking:

- Booked slots show **green border** with car icon
- Click **"VIEW QR"** button to see your QR code again
- Booking is saved to history

## 📱 Key Features

✅ **Splash Screen** with car animation  
✅ **User Authentication** (login/register)  
✅ **Floor Selection** (multiple floors)  
✅ **Real-time Slot Status** (available/occupied/booked)  
✅ **Time Selection** (flexible duration)  
✅ **QR Code Generation** (unique per booking)  
✅ **Booking History** (saved locally)  
✅ **Professional UI** matching reference design  

## 🎨 Design Highlights

- **Blue gradient header** with white text
- **Clean parking slot cards** with borders
- **Color-coded status**:
  - Gray = Available
  - Red = Occupied
  - Green = Your booking
- **Modern icons** and typography
- **Responsive layout** for mobile

## 🔧 Technical Stack

- **Flutter** framework
- **SharedPreferences** for local storage
- **qr_flutter** for QR code generation
- **Material Design** components

## 📝 Usage

1. Open app → See splash screen
2. Login with any email/password
3. Select floor from dropdown
4. Click "BOOK" on available slot
5. Choose parking duration
6. View and save QR code
7. Show QR code to parking attendant

---

**Note**: All bookings are saved locally and persist across app restarts.
