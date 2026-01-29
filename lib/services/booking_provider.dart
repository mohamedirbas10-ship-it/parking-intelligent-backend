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
  List<Booking> get pastBookings => _bookings
      .where(
        (b) =>
            b.status == 'completed' || b.isExpired || b.status == 'cancelled',
      )
      .toList();
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
    // Update every 5 seconds to check for expiry, sync with backend, and send notifications
    // Faster updates for better exit gate experience
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _checkExpiringBookings();
      _updateExpiredBookings();

      // Sync with backend to get latest booking and slot status
      await _syncWithBackend();

      notifyListeners();
    });
  }

  // Sync local data with backend to detect changes (like exit scans)
  Future<void> _syncWithBackend() async {
    try {
      // Refresh parking slots to get updated availability
      await _loadParkingSlotsFromAPI();

      // If we have bookings, refresh them to get updated status
      if (_bookings.isNotEmpty) {
        final userId = _bookings.first.userId;
        final updatedBookings = await _apiService.getUserBookings(userId);

        // Keep track of locally cancelled bookings before clearing
        final locallyCancelled = _bookings
            .where((b) => b.status == 'cancelled')
            .toList();

        // Update local bookings with backend data
        _bookings.clear();
        _bookings.addAll(updatedBookings);

        // Restore locally cancelled bookings if they're missing from backend
        // (Backend deletes cancelled bookings, but we want to show them as cancelled)
        for (var cancelled in locallyCancelled) {
          if (!_bookings.any((b) => b.id == cancelled.id)) {
            _bookings.add(cancelled);
          }
        }
      }
    } catch (e) {
      print('⚠️ Background sync failed: $e');
      // Don't throw error, just log it - we'll try again in 30 seconds
    }
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
        final spotIndex = _parkingSpots.indexWhere(
          (s) => s.id == booking.slotId,
        );
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
    DateTime? startTime,
  }) async {
    try {
      print('🔵 Creating booking via API...');
      print('   User: $userId, Slot: $slotId, Duration: $durationHours hours');
      if (startTime != null) {
        print('   Start Time: ${startTime.toIso8601String()}');
      }

      _isLoading = true;
      notifyListeners();

      // Create booking via API
      final result = await _apiService.createBooking(
        userId: userId,
        slotId: slotId,
        duration: durationHours,
        startTime: startTime,
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

  Future<void> cancelBooking(String bookingId) async {
    try {
      print('🔄 BookingProvider: Cancelling booking $bookingId');

      // Call backend API to cancel booking
      final success = await _apiService.cancelBooking(bookingId);

      print('📡 BookingProvider: API response: $success');

      if (success) {
        // Update local state
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

          // Free up the parking spot (clear all reservation data)
          final spotIndex = _parkingSpots.indexWhere(
            (s) => s.id == booking.slotId,
          );
          if (spotIndex != -1) {
            _parkingSpots[spotIndex] = _parkingSpots[spotIndex].copyWith(
              isAvailable: true,
              status: 'available',
              bookedBy: null,
              bookingId: null,
              reservationTime: null, // Clear reservation time
              validityHours: 0, // Reset validity
              qrCode: null, // Clear QR code
              userId: null, // Clear user
              isCancelled: false, // Reset cancelled status
            );
          }
        }

        // Refresh slots from backend to ensure sync
        await _loadParkingSlotsFromAPI();

        _notificationService.cancelNotification(bookingId);
        notifyListeners();

        print('✅ Booking cancelled successfully!');
      } else {
        print('❌ Failed to cancel booking');
        _error = 'Failed to cancel booking';
        notifyListeners();
      }
    } catch (e) {
      print('❌ Exception cancelling booking: $e');
      _error = e.toString();
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

  // Public method to manually refresh bookings and slots from backend
  Future<void> refreshBookingsAndSlots(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Refresh slots
      await _loadParkingSlotsFromAPI();

      // Refresh user bookings
      await loadUserBookings(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
