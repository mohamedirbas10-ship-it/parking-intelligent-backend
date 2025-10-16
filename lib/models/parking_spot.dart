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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'bookedBy': bookedBy,
      'bookingId': bookingId,
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
    );
  }

  bool get isExpired {
    if (reservationTime == null) return false;
    final now = DateTime.now();
    final expiryTime = reservationTime!.add(Duration(hours: validityHours));
    return now.isAfter(expiryTime);
  }

  String get timeRemaining {
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
