class ParkingSpot {
  final String id;
  final String name;
  final bool isAvailable;
  final DateTime? reservationTime;
  final int validityHours;
  final String? qrCode;
  final String? userId;
  final String? userName;
  final String status; // 'available', 'occupied', 'booked'
  final String? bookedBy;
  final String? bookingId;
  final bool isCancelled; // Track if booking was cancelled
  final Map<String, dynamic>? nextBooking; // Info about next reservation

  ParkingSpot({
    required this.id,
    required this.name,
    required this.isAvailable,
    this.reservationTime,
    required this.validityHours,
    this.qrCode,
    this.userId,
    this.userName,
    required this.status,
    this.bookedBy,
    this.bookingId,
    this.isCancelled = false,
    this.nextBooking,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'],
      name: json['id'], // Use id as name
      isAvailable: json['status'] == 'available',
      status: json['status'],
      bookedBy: json['bookedBy'],
      bookingId: json['bookingId'],
      reservationTime: null,
      validityHours: 0,
      nextBooking: json['nextBooking'],
    );
  }

  // Check if slot has a future booking
  bool get hasFutureBooking {
    if (nextBooking == null) return false;
    if (status != 'available') return false; // Only check for available slots
    return true;
  }

  // Get next booking start time
  DateTime? get nextBookingStart {
    if (nextBooking == null || nextBooking!['start'] == null) return null;
    try {
      return DateTime.parse(nextBooking!['start']);
    } catch (e) {
      return null;
    }
  }

  // Get next booking end time
  DateTime? get nextBookingEnd {
    if (nextBooking == null || nextBooking!['end'] == null) return null;
    try {
      return DateTime.parse(nextBooking!['end']);
    } catch (e) {
      return null;
    }
  }

  // Get formatted time until next booking
  String get timeUntilNextBooking {
    final nextStart = nextBookingStart;
    if (nextStart == null) return '';

    final now = DateTime.now();
    final difference = nextStart.difference(now);

    if (difference.isNegative) return '';

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 24) {
      final days = (hours / 24).floor();
      return 'in $days day${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'in ${hours}h ${minutes}m';
    } else {
      return 'in ${minutes}m';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'bookedBy': bookedBy,
      'bookingId': bookingId,
      'nextBooking': nextBooking,
    };
  }

  ParkingSpot copyWith({
    String? id,
    String? name,
    bool? isAvailable,
    DateTime? reservationTime,
    int? validityHours,
    String? qrCode,
    String? userId,
    String? userName,
    String? status,
    String? bookedBy,
    String? bookingId,
    bool? isCancelled,
    Map<String, dynamic>? nextBooking,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
      reservationTime: reservationTime ?? this.reservationTime,
      validityHours: validityHours ?? this.validityHours,
      qrCode: qrCode ?? this.qrCode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
      bookingId: bookingId ?? this.bookingId,
      isCancelled: isCancelled ?? this.isCancelled,
      nextBooking: nextBooking ?? this.nextBooking,
    );
  }

  bool get isExpired {
    // Cancelled slots are not expired, they're just cancelled
    if (isCancelled) return false;
    if (reservationTime == null) return false;
    final now = DateTime.now();
    final expiryTime = reservationTime!.add(Duration(hours: validityHours));
    return now.isAfter(expiryTime);
  }

  String get timeRemaining {
    // Cancelled slots don't have time remaining
    if (isCancelled) return '';
    if (reservationTime == null) return '';
    final now = DateTime.now();
    final expiryTime = reservationTime!.add(Duration(hours: validityHours));
    final difference = expiryTime.difference(now);

    if (difference.isNegative) return 'Expired';

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
