class Booking {
  final String id;
  final String userId;
  final String slotId;
  final int duration;
  final DateTime reservedAt;
  final DateTime expiresAt;
  final String status;
  final String qrCode;

  Booking({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.duration,
    required this.reservedAt,
    required this.expiresAt,
    required this.status,
    required this.qrCode,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'],
      slotId: json['slotId'],
      duration: json['duration'],
      reservedAt: DateTime.parse(json['reservedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      status: json['status'],
      qrCode: json['qrCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'slotId': slotId,
      'duration': duration,
      'reservedAt': reservedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status,
      'qrCode': qrCode,
    };
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  String get timeRemaining {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
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
