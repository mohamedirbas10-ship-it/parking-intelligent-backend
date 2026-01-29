require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// In-memory data storage (replace with database in production)
let users = [];
let parkingSlots = {};
let bookings = [];

// Initialize parking slots - single floor with 6 slots
const initializeParkingSlots = () => {
  parkingSlots = [];
  
  for (let i = 1; i <= 6; i++) {
    parkingSlots.push({
      id: `A${i}`,
      status: 'available', // available, occupied, booked
      bookedBy: null,
      bookingId: null
    });
  }
};

initializeParkingSlots();

// Routes

// Serve QR Scanner Test Page
app.get('/scanner', (req, res) => {
  res.sendFile(__dirname + '/qr-scanner-test.html');
});

// Health check
app.get('/', (req, res) => {
  res.json({ 
    message: 'Smart Car Parking API is running',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    scanner: 'http://' + req.get('host') + '/scanner'
  });
});

// Reset all data (for testing)
app.post('/api/reset', (req, res) => {
  console.log('🔄 Resetting all data...');
  
  // Clear all data
  users = [];
  bookings = [];
  initializeParkingSlots(); // Reset parking slots to available
  
  console.log('✅ All data reset successfully');
  console.log(`📊 Users: ${users.length}, Bookings: ${bookings.length}, Slots: ${parkingSlots.length}`);
  
  res.json({ 
    message: 'All data reset successfully',
    users: users.length,
    bookings: bookings.length,
    slots: parkingSlots.length
  });
});

// User Authentication
app.post('/api/auth/register', (req, res) => {
  const { email, password, name } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  
  const existingUser = users.find(u => u.email === email);
  if (existingUser) {
    return res.status(409).json({ error: 'User already exists' });
  }
  
  const user = {
    id: uuidv4(),
    email,
    password, // In production, hash this!
    name: name || email.split('@')[0],
    createdAt: new Date().toISOString()
  };
  
  users.push(user);
  
  res.status(201).json({
    message: 'User registered successfully',
    token: 'mock-token-' + user.id,
    user: {
      id: user.id,
      email: user.email,
      name: user.name
    }
  });
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  
  const user = users.find(u => u.email === email && u.password === password);
  
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  res.json({
    message: 'Login successful',
    token: 'mock-token-' + user.id,
    user: {
      id: user.id,
      email: user.email,
      name: user.name
    }
  });
});

// Helper to check availability
const isSlotAvailable = (slotId, startTime, endTime) => {
  const slotBookings = bookings.filter(b => 
    b.slotId === slotId && 
    ['active', 'occupied'].includes(b.status)
  );

  for (const b of slotBookings) {
    const bStart = new Date(b.reservedAt).getTime();
    const bEnd = new Date(b.expiresAt).getTime();
    const newStart = new Date(startTime).getTime();
    const newEnd = new Date(endTime).getTime();

    // Check overlap
    if (newStart < bEnd && newEnd > bStart) {
      return false;
    }
  }
  return true;
};

// Parking Slots
app.get('/api/parking/slots', (req, res) => {
  const now = new Date();
  
  const dynamicSlots = parkingSlots.map(slot => {
    // Find active bookings for this slot
    const slotBookings = bookings.filter(b => 
      b.slotId === slot.id && 
      ['active', 'occupied'].includes(b.status)
    );

    let status = 'available';
    let bookedBy = null;
    let bookingId = null;

    // Check for CURRENT occupation
    const currentBooking = slotBookings.find(b => {
      const start = new Date(b.reservedAt);
      const end = new Date(b.expiresAt);
      return now >= start && now <= end;
    });

    if (currentBooking) {
      status = currentBooking.enteredAt ? 'occupied' : 'booked';
      bookedBy = currentBooking.userId;
      bookingId = currentBooking.id;
    } 
    // If no current booking, it remains 'available' even if there are future bookings
    
    // Check for next upcoming booking to show "Reserved later" status if needed
    let nextBooking = null;
    if (status === 'available') {
        const futureBookings = slotBookings.filter(b => new Date(b.reservedAt) > now);
        if (futureBookings.length > 0) {
            // Get the earliest future booking
            const next = futureBookings.sort((a, b) => new Date(a.reservedAt) - new Date(b.reservedAt))[0];
            nextBooking = {
                start: next.reservedAt,
                end: next.expiresAt
            };
        }
    }

    return {
      ...slot,
      status,
      bookedBy,
      bookingId,
      nextBooking
    };
  });

  res.json({
    slots: dynamicSlots
  });
});

// Create Booking
app.post('/api/bookings', (req, res) => {
  const { userId, slotId, duration, startTime } = req.body;
  
  if (!userId || !slotId || !duration) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  const slot = parkingSlots.find(s => s.id === slotId);
  
  if (!slot) {
    return res.status(404).json({ error: 'Slot not found' });
  }
  
  // Calculate start and end times
  const start = startTime ? new Date(startTime) : new Date();
  const end = new Date(start.getTime() + duration * 60 * 60 * 1000);

  // Check for time-based availability
  if (!isSlotAvailable(slotId, start, end)) {
    return res.status(409).json({ error: 'Slot is not available for the selected time' });
  }
  
  const booking = {
    id: uuidv4(),
    userId,
    slotId,
    duration,
    reservedAt: start.toISOString(),
    expiresAt: end.toISOString(),
    status: 'active',
    qrCode: `PARKING-${uuidv4()}`
  };
  
  bookings.push(booking);
  
  // We no longer strictly set slot.status = 'booked' here because 
  // the status is now calculated dynamically in GET /slots based on time.
  // However, for compatibility with legacy code that might check the array directly:
  if (new Date() >= start && new Date() <= end) {
      slot.status = 'booked';
      slot.bookedBy = userId;
      slot.bookingId = booking.id;
  }
  
  res.status(201).json({
    message: 'Booking created successfully',
    booking
  });
});

// Get User Bookings
app.get('/api/bookings/user/:userId', (req, res) => {
  const { userId } = req.params;
  
  const userBookings = bookings.filter(b => b.userId === userId);
  
  res.json({
    count: userBookings.length,
    bookings: userBookings
  });
});

// Get Booking by ID
app.get('/api/bookings/:bookingId', (req, res) => {
  const { bookingId } = req.params;
  
  const booking = bookings.find(b => b.id === bookingId);
  
  if (!booking) {
    return res.status(404).json({ error: 'Booking not found' });
  }
  
  res.json({ booking });
});

// Cancel Booking
app.delete('/api/bookings/:bookingId', (req, res) => {
  const { bookingId } = req.params;
  
  const bookingIndex = bookings.findIndex(b => b.id === bookingId);
  
  if (bookingIndex === -1) {
    return res.status(404).json({ error: 'Booking not found' });
  }
  
  const booking = bookings[bookingIndex];
  const slot = parkingSlots.find(s => s.id === booking.slotId);
  
  if (slot) {
    slot.status = 'available';
    slot.bookedBy = null;
    slot.bookingId = null;
  }
  
  bookings.splice(bookingIndex, 1);
  
  res.json({ message: 'Booking cancelled successfully' });
});

// Update slot status (for admin/attendant)
app.patch('/api/parking/slots/:slotId', (req, res) => {
  const { slotId } = req.params;
  const { status } = req.body;
  
  const slot = parkingSlots.find(s => s.id === slotId);
  
  if (!slot) {
    return res.status(404).json({ error: 'Slot not found' });
  }
  
  if (status && ['available', 'occupied', 'booked'].includes(status)) {
    slot.status = status;
  }
  
  res.json({
    message: 'Slot updated successfully',
    slot
  });
});

// Verify QR Code at Entry Gate (ESP32-CAM #1)
app.post('/api/parking/entry', (req, res) => {
  const { qrCode } = req.body;
  
  if (!qrCode) {
    return res.status(400).json({ 
      valid: false, 
      message: 'QR code is required' 
    });
  }
  
  // Find active booking with this QR code
  const booking = bookings.find(b => b.qrCode === qrCode && b.status === 'active');
  
  if (!booking) {
    return res.status(404).json({ 
      valid: false, 
      message: 'Invalid QR code or booking not found',
      action: 'deny'
    });
  }
  
  // Check if already entered (prevent duplicate entry)
  if (booking.enteredAt) {
    return res.status(409).json({ 
      valid: false, 
      message: 'Already entered. Use this QR code at exit.',
      action: 'deny'
    });
  }
  
  // Check if booking expired
  if (new Date() > new Date(booking.expiresAt)) {
    booking.status = 'expired';
    return res.status(403).json({ 
      valid: false, 
      message: 'QR code expired',
      action: 'deny'
    });
  }
  
  // Mark as entered and update slot status
  booking.enteredAt = new Date().toISOString();
  const slot = parkingSlots.find(s => s.id === booking.slotId);
  
  if (slot) {
    slot.status = 'occupied';
  }
  
  res.json({ 
    valid: true, 
    message: 'Access granted - Welcome!',
    action: 'open_gate',
    slotId: booking.slotId,
    slotName: booking.slotId,
    expiresAt: booking.expiresAt,
    duration: booking.duration
  });
});

// Verify QR Code at Exit Gate (ESP32-CAM #2)
app.post('/api/parking/exit', (req, res) => {
  const { qrCode } = req.body;
  
  if (!qrCode) {
    return res.status(400).json({ 
      valid: false, 
      message: 'QR code is required' 
    });
  }
  
  // Find booking with this QR code
  const booking = bookings.find(b => b.qrCode === qrCode);
  
  if (!booking) {
    return res.status(404).json({ 
      valid: false, 
      message: 'Invalid QR code',
      action: 'deny'
    });
  }
  
  // Check if user has entered (must enter before exit)
  if (!booking.enteredAt) {
    return res.status(400).json({ 
      valid: false, 
      message: 'Please use entry gate first',
      action: 'deny'
    });
  }
  
  // Check if already exited
  if (booking.exitedAt) {
    return res.status(409).json({ 
      valid: false, 
      message: 'Already exited',
      action: 'deny'
    });
  }
  
  // Mark as exited and free the slot
  booking.exitedAt = new Date().toISOString();
  booking.status = 'completed';
  
  const slot = parkingSlots.find(s => s.id === booking.slotId);
  
  if (slot) {
    slot.status = 'available';
    slot.bookedBy = null;
    slot.bookingId = null;
  }
  
  // Calculate parking duration
  const entryTime = new Date(booking.enteredAt);
  const exitTime = new Date(booking.exitedAt);
  const actualDuration = Math.round((exitTime - entryTime) / (1000 * 60)); // in minutes
  
  res.json({ 
    valid: true, 
    message: 'Exit granted - Thank you!',
    action: 'open_gate',
    slotId: booking.slotId,
    slotName: booking.slotId,
    enteredAt: booking.enteredAt,
    exitedAt: booking.exitedAt,
    actualDuration: `${actualDuration} minutes`,
    bookedDuration: `${booking.duration} hours`
  });
});

// Get statistics
app.get('/api/stats', (req, res) => {
  const stats = {
    totalUsers: users.length,
    totalBookings: bookings.length,
    activeBookings: bookings.filter(b => b.status === 'active').length,
    completedBookings: bookings.filter(b => b.status === 'completed').length,
    slots: {
      total: parkingSlots.length,
      available: parkingSlots.filter(s => s.status === 'available').length,
      occupied: parkingSlots.filter(s => s.status === 'occupied').length,
      booked: parkingSlots.filter(s => s.status === 'booked').length
    }
  };
  
  res.json(stats);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚗 Smart Car Parking API Server`);
  console.log(`📡 Server running on http://localhost:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`⏰ Started at: ${new Date().toLocaleString()}`);
  console.log(`🅿️  Parking: 1 floor, 6 slots (A1-A6)`);
  console.log(`\n📋 Available endpoints:`);
  console.log(`   GET    /                           - Health check`);
  console.log(`   POST   /api/auth/register          - Register user`);
  console.log(`   POST   /api/auth/login             - Login user`);
  console.log(`   GET    /api/parking/slots          - Get all slots`);
  console.log(`   POST   /api/bookings               - Create booking`);
  console.log(`   GET    /api/bookings/user/:userId  - Get user bookings`);
  console.log(`   GET    /api/bookings/:bookingId    - Get booking by ID`);
  console.log(`   DELETE /api/bookings/:bookingId    - Cancel booking`);
  console.log(`   PATCH  /api/parking/slots/:slotId  - Update slot status`);
  console.log(`   POST   /api/parking/entry          - 🚗 Entry gate QR verification`);
  console.log(`   POST   /api/parking/exit           - 🚗 Exit gate QR verification`);
  console.log(`   GET    /api/stats                  - Get statistics`);
});
