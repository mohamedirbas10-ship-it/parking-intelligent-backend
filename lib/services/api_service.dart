import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';

class ApiService {
  // Cloud backend URL - works from anywhere!
  static String get baseUrl {
    // Use your Render backend URL for production/cloud usage:
    return 'https://parking-intelligent-backend.onrender.com';
  }

  static String? _token;

  static void setToken(String token) {
    _token = token;
    print('🔑 Token set: ${token.substring(0, 20)}...');
  }

  static String? getToken() {
    return _token;
  }

  static bool get isAuthenticated => _token != null;

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Parking slots endpoints
  Future<List<ParkingSpot>> getParkingSlots() async {
    try {
      final url = '$baseUrl/api/parking/slots';
      print('🔵 Fetching slots from: $url');
      print('🔵 Base URL: $baseUrl');

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> slotsJson = data['slots'];
        final slots = slotsJson
            .map((json) => ParkingSpot.fromJson(json))
            .toList();
        print('✅ Parsed ${slots.length} slots successfully');
        for (var slot in slots) {
          print(
            '   - ${slot.id}: ${slot.status} (available: ${slot.isAvailable})',
          );
        }
        return slots;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: Failed to load parking slots',
        );
      }
    } catch (e) {
      print('❌ ERROR loading slots: ${e.toString()}');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<bool> updateSlotStatus({
    required String slotId,
    required String status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/parking/slots/$slotId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Booking endpoints
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String slotId,
    required int duration,
    DateTime? startTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'slotId': slotId,
          'duration': duration,
          if (startTime != null) 'startTime': startTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'booking': Booking.fromJson(data['booking'])};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error'] ?? 'Booking failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> bookingsJson = data['bookings'];
        return bookingsJson.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Booking.fromJson(data['booking']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      print('🔄 Cancelling booking: $bookingId');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/bookings/$bookingId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      return false;
    }
  }

  // Statistics endpoint
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
