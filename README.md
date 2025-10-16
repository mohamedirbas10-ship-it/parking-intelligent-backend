# Parking Intelligent App

A Flutter application for managing parking spot reservations with QR code generation.

## Features

- **Authentication**: Login and registration screens
- **Parking Management**: View and reserve 5 parking spots (A1-A5)
- **QR Code Generation**: Generate QR codes for reserved spots
- **Time Management**: 1-hour validity for each reservation
- **Real-time Status**: Visual indicators for available, reserved, and expired spots

## App Structure

### Screens
- **Login Screen**: User authentication with email and password
- **Register Screen**: New user registration
- **Parking Home Screen**: Main dashboard showing all parking spots
- **QR Code Screen**: Displays QR code for reserved spots

### Models
- **ParkingSpot**: Represents individual parking spots with availability and timing
- **User**: User information and authentication data

## Getting Started

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `qr_flutter`: QR code generation
- `qr_code_scanner`: QR code scanning (for future implementation)
- `shared_preferences`: Local data storage
- `intl`: Date and time formatting

## Usage

1. **Login/Register**: Use any email and password to authenticate
2. **View Spots**: See all 5 parking spots with their current status
3. **Reserve Spot**: Tap "Reserve" on available spots
4. **QR Code**: View generated QR code for your reservation
5. **Time Tracking**: Monitor remaining time for your reservation

## Future Enhancements

- Backend integration for real-time data
- QR code scanning functionality
- Push notifications for expiry alerts
- Payment integration
- Admin dashboard for spot management

## Note

This is a UI-only implementation. Backend logic and real-time updates will be added in future iterations.