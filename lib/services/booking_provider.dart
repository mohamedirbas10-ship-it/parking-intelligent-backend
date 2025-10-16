import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/parking_spot.dart';
import 'notification_service.dart';
import 'api_service.dart';

class BookingProvider extends ChangeNotifier {
  final List<Booking> _bookings = [];
  final List<ParkingSpot> _parkingSpots = [];
  Timer? _updateTimer;
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<Booking> get activeBookings =>
      _bookings.where((b) => b.status == 'active' && !b.isExpired).toList();
  List<Booking> get pastBookings =>
      _bookings.where((b) => b.status == 'completed' || b.isExpired).toList();
  List<ParkingSpot> get parkingSpots => List.unmodifiable(_parkingSpots);
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookingProvider() {
    _initializeProvider();
    _startRealTimeUpdates();
  }

  Future<void> _initializeProvider() async {
    // Load slots asynchronously to avoid blocking constructor
    await _loadParkingSlotsFromAPI();
  }

  // Load parking slots from backend API
  Future<void> _loadParkingSlotsFromAPI() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final slots = await _apiService.getParkingSlots();
      _parkingSpots.clear();
      _parkingSpots.addAll(slots);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('⚠️ Failed to load slots from API: $e');
      print('📦 Using local fallback slots');
      
      // Fallback to local slots if API fails (matching backend: A1-A6)
      _parkingSpots.clear();
      _parkingSpots.addAll([
        ParkingSpot(
          id: 'A1',
          name: 'A1',
          isAvailable: true,
          status: 'available',
          validityHours: 2,
        ),
        ParkingSpot(
          id: 'A2',
          name: 'A2',
          isAvailable: true,
          status: 'available',
          validityHours: 2,
        ),
        ParkingSpot(
          id: 'A3',
          name: 'A3',
          isAvailable: true,
          status: 'available',
          validityHours: 2,
        ),
        ParkingSpot(
          id: 'A4',
          name: 'A4',
          isAvailable: true,
          status: 'available',
          validityHours: 2,
        ),
        ParkingSpot(
          id: 'A5',
          name: 'A5',
          isAvailable: true,
          status: 'available',
          validityHours: 2,
        ),
        ParkingSpot(
          id: 'A6',
          name: 'A6',
          isAvailable: true,
          status: 'available',
          validityHours: 2,
        ),
      ]);
      print('📦 Loaded 6 fallback slots (A1-A6)');
      
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh slots from API
  Future<void> refreshSlots() async {
    await _loadParkingSlotsFromAPI();
  }

  void _startRealTimeUpdates() {
    // Update every 30 seconds to check for expiry and send notifications
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkExpiringBookings();
      _updateExpiredBookings();
      notifyListeners();
    });
  }

  void _checkExpiringBookings() {
    for (var booking in activeBookings) {
      final now = DateTime.now();
      final difference = booking.expiresAt.difference(now);
      
      // Notify 15 minutes before expiry
      if (difference.inMinutes == 15) {
        _notificationService.showParkingExpiryWarning(
          slotId: booking.slotId,
          minutesRemaining: 15,
        );
      }
      // Notify 5 minutes before expiry
      else if (difference.inMinutes == 5) {
        _notificationService.showParkingExpiryWarning(
          slotId: booking.slotId,
          minutesRemaining: 5,
        );
      }
    }
  }

  void _updateExpiredBookings() {
    for (var booking in _bookings) {
      if (booking.status == 'active' && booking.isExpired) {
        // Mark as completed
        final index = _bookings.indexOf(booking);
        _bookings[index] = Booking(
          id: booking.id,
          userId: booking.userId,
          slotId: booking.slotId,
          duration: booking.duration,
          reservedAt: booking.reservedAt,
          expiresAt: booking.expiresAt,
          status: 'completed',
          qrCode: booking.qrCode,
        );

        // Free up the parking spot
        final spotIndex = _parkingSpots.indexWhere((s) => s.id == booking.slotId);
        if (spotIndex != -1) {
          _parkingSpots[spotIndex] = _parkingSpots[spotIndex].copyWith(
            isAvailable: true,
            status: 'available',
            bookedBy: null,
            bookingId: null,
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String slotId,
    required String userId,
    required int durationHours,
  }) async {
    try {
      print('🔵 Creating booking via API...');
      print('   User: $userId, Slot: $slotId, Duration: $durationHours hours');
      
      _isLoading = true;
      notifyListeners();

      // Create booking via API
      final result = await _apiService.createBooking(
        userId: userId,
        slotId: slotId,
        duration: durationHours,
      );

      print('🔵 API Response: ${result['success']}');

      if (result['success']) {
        final booking = result['booking'] as Booking;
        print('✅ Booking created! QR Code: ${booking.qrCode}');
        _bookings.add(booking);

        // Refresh slots to get updated status
        await _loadParkingSlotsFromAPI();

        // Show confirmation notification
        await _notificationService.showBookingConfirmation(
          slotId: slotId,
          expiryTime: booking.expiresAt,
        );

        _isLoading = false;
        notifyListeners();
        
        return {'success': true, 'booking': booking};
      } else {
        print('❌ Booking failed: ${result['error']}');
        _isLoading = false;
        _error = result['error'];
        notifyListeners();
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      print('❌ Exception creating booking: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  // Load user bookings from API
  Future<void> loadUserBookings(String userId) async {
    try {
      final bookings = await _apiService.getUserBookings(userId);
      _bookings.clear();
      _bookings.addAll(bookings);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      _bookings[index] = Booking(
        id: booking.id,
        userId: booking.userId,
        slotId: booking.slotId,
        duration: booking.duration,
        reservedAt: booking.reservedAt,
        expiresAt: booking.expiresAt,
        status: 'cancelled',
        qrCode: booking.qrCode,
      );

      // Free up the parking spot
      final spotIndex = _parkingSpots.indexWhere((s) => s.id == booking.slotId);
      if (spotIndex != -1) {
        _parkingSpots[spotIndex] = _parkingSpots[spotIndex].copyWith(
          isAvailable: true,
          status: 'available',
          bookedBy: null,
          bookingId: null,
        );
      }

      _notificationService.cancelNotification(booking.slotId);
      notifyListeners();
    }
  }

  ParkingSpot? getSpotById(String id) {
    try {
      return _parkingSpots.firstWhere((spot) => spot.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
