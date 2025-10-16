# Smart Car Parking - Backend API

Node.js/Express backend for the Smart Car Parking application.

## Features

- User authentication (register/login)
- Parking slot management (3 floors, 10 slots each)
- Booking system with QR code generation
- Real-time slot availability
- Statistics and analytics

## Installation

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

Or for development with auto-reload:
```bash
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Parking Slots
- `GET /api/parking/slots` - Get all parking slots
- `GET /api/parking/slots/:floor` - Get slots by floor (1st, 2nd, 3rd)
- `PATCH /api/parking/slots/:floor/:slotId` - Update slot status

### Bookings
- `POST /api/bookings` - Create new booking
- `GET /api/bookings/user/:userId` - Get user's bookings
- `GET /api/bookings/:bookingId` - Get booking details
- `DELETE /api/bookings/:bookingId` - Cancel booking

### Statistics
- `GET /api/stats` - Get system statistics

## Server Info

- Default Port: 3000
- Base URL: http://localhost:3000
