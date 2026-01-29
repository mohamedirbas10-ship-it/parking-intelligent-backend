import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../../models/parking_spot.dart';
import '../../widgets/time_selection_dialog.dart';
import '../../services/booking_provider.dart';
import '../../models/booking.dart';
import 'qr_code_screen.dart';
import 'booking_history_screen.dart';
import 'profile_screen.dart';
import '../../theme/app_colors.dart';

class ParkingHomeScreen extends StatefulWidget {
  const ParkingHomeScreen({super.key});

  @override
  State<ParkingHomeScreen> createState() => _ParkingHomeScreenState();
}

class _ParkingHomeScreenState extends State<ParkingHomeScreen> {
  String _userName = '';
  String _userId = '';

  // Track booked slots globally (shared across all users)
  Map<String, ParkingSpot> bookedSlots = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGlobalBookings();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userId = prefs.getString('userEmail') ?? 'user@example.com';
    });

    if (mounted && _userId.isNotEmpty) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      await provider.loadUserBookings(_userId);
    }
  }

  Future<void> _loadGlobalBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final globalBookingsJson = prefs.getStringList('globalBookings') ?? [];

    final Map<String, ParkingSpot> loadedBookings = {};
    bool hasExpiredBookings = false;

    for (var json in globalBookingsJson) {
      final parts = json.split('|');
      final spot = ParkingSpot(
        id: parts[0],
        name: parts[1],
        isAvailable: false,
        status: 'booked',
        reservationTime: DateTime.parse(parts[2]),
        validityHours: int.parse(parts[3]),
        qrCode: parts[4],
        userId: parts.length > 5 ? parts[5] : '',
        userName: parts.length > 6 ? parts[6] : '',
      );

      // Only add if not expired
      if (!spot.isExpired) {
        loadedBookings[parts[0]] = spot;
      } else {
        hasExpiredBookings = true;
      }
    }

    setState(() {
      bookedSlots = loadedBookings;
    });

    // Save back to remove expired bookings
    if (hasExpiredBookings) {
      await _saveGlobalBookings();
    }
  }

  Future<void> _refreshBookings() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    await provider.refreshBookingsAndSlots(_userId);
    await _loadGlobalBookings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookings refreshed'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveGlobalBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = bookedSlots.values.map((spot) {
      return '${spot.id}|${spot.name}|${spot.reservationTime!.toIso8601String()}|${spot.validityHours}|${spot.qrCode}|${spot.userId}|${spot.userName}';
    }).toList();

    await prefs.setStringList('globalBookings', bookingsJson);
  }

  Future<void> _showMyBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];

    // Parse history into ParkingSpot objects and filter by current user
    final List<ParkingSpot> allSpots = historyJson.map((json) {
      final parts = json.split('|');
      final isCancelled = parts.length > 7 ? parts[7] == 'true' : false;

      return ParkingSpot(
        id: parts[0],
        name: parts[1],
        isAvailable: false,
        status: 'booked',
        reservationTime: DateTime.parse(parts[2]),
        validityHours: int.parse(parts[3]),
        qrCode: parts[4],
        userId: parts.length > 5 ? parts[5] : '',
        userName: parts.length > 6 ? parts[6] : '',
        isCancelled: isCancelled,
      );
    }).toList();

    // Filter to show only current user's bookings (both active and cancelled)
    final List<ParkingSpot> spots = allSpots
        .where((spot) => spot.userId == _userId)
        .toList();

    if (spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR codes yet. Book a parking slot first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show bottom sheet with QR code history
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(232, 192, 186, 186),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My QR Codes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${spots.length} Total',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot =
                        spots[spots.length - 1 - index]; // Show newest first
                    return _buildQRHistoryCard(spot);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRHistoryCard(ParkingSpot spot) {
    final isCancelled = spot.isCancelled;
    final isExpired = spot.isExpired;

    // Determine card color based on status
    final Color borderColor = isCancelled
        ? Colors.red.shade300
        : (isExpired ? Colors.orange.shade300 : Colors.green.shade200);
    final Color iconBgColor = isCancelled
        ? Colors.red.shade50
        : (isExpired ? Colors.orange.shade50 : Colors.green.shade50);
    final Color iconColor = isCancelled
        ? Colors.red.shade600
        : (isExpired ? Colors.orange.shade600 : Colors.green.shade600);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCancelled ? Icons.cancel : Icons.local_parking,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Slot ${spot.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCancelled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block,
                                size: 10,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'CANCEL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.validityHours} hour${spot.validityHours > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(spot.reservationTime ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: isCancelled
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRCodeScreen(spot: spot),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCancelled
                      ? Colors.grey.shade300
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isCancelled ? 'Done' : 'View QR',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;

    return '$day/$month/$year $hour:$minute';
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.menu, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: Icons.history,
                title: 'Booking History',
                subtitle: 'View all your bookings',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingHistoryScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.qr_code,
                title: 'My QR Codes',
                subtitle: 'View active QR codes',
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(context);
                  _showMyBookings();
                },
              ),
              _buildMenuItem(
                icon: Icons.refresh,
                title: 'Refresh',
                subtitle: 'Reload parking slots',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _refreshBookings();
                },
              ),
              _buildMenuItem(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Account settings',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');
    await prefs.remove('userName');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Primary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SMART CAR PARKING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Menu',
                      onPressed: _showMenu,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Welcome Message
                Text(
                  'Welcome, $_userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Consumer<BookingProvider>(
                builder: (context, provider, child) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parking Slots',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Entry Label
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'ENTRY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Parking Slots Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildParkingSlot(provider, 'A1'),
                                    const SizedBox(height: 40),
                                    _buildParkingSlot(provider, 'A3'),
                                    const SizedBox(height: 40),
                                    _buildParkingSlot(provider, 'A5'),
                                  ],
                                ),
                              ),

                              // Center Road
                              SizedBox(
                                width: 60,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 400,
                                      width: 3,
                                      color: Colors.grey.shade300,
                                    ),
                                  ],
                                ),
                              ),

                              // Right Column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildParkingSlot(provider, 'A2'),
                                    const SizedBox(height: 40),
                                    _buildParkingSlot(provider, 'A4'),
                                    const SizedBox(height: 40),
                                    _buildParkingSlot(provider, 'A6'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingSlot(BookingProvider provider, String slotId) {
    final spot = provider.getSpotById(slotId);
    final activeBooking = provider.activeBookings.firstWhere(
      (b) => b.slotId == slotId,
      orElse: () => Booking(
        id: '',
        userId: '',
        slotId: '',
        duration: 0,
        reservedAt: DateTime.now(),
        expiresAt: DateTime.now(),
        status: 'none',
        qrCode: '',
      ),
    );
    final hasActiveBooking = activeBooking.status == 'active';
    final isBookedByCurrentUser =
        hasActiveBooking && activeBooking.userId == _userId;
    final isAvailable = spot?.isAvailable ?? true;
    final actuallyAvailable = isAvailable;
    final isBooked = !isAvailable || hasActiveBooking;
    final showCancel = isBookedByCurrentUser;

    final nextBooking = spot?.nextBooking;
    String? nextBookingText;
    if (nextBooking != null && actuallyAvailable) {
      final start = DateTime.parse(nextBooking!['start']);
      final hour = start.hour.toString().padLeft(2, '0');
      final minute = start.minute.toString().padLeft(2, '0');
      nextBookingText = "Reserved at $hour:$minute";
    }

    return Column(
      children: [
        // Parking Slot (removed top number)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: actuallyAvailable
                  ? (nextBookingText != null ? Colors.amber : AppColors.border)
                  : (isBooked ? AppColors.success : AppColors.warning),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Car Icon or Empty with parking lines
              if (!actuallyAvailable)
                Icon(
                  Icons.directions_car,
                  size: 40,
                  color: isBooked ? AppColors.success : AppColors.textLight,
                )
              else
                SizedBox(
                  height: 40,
                  child: CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: ParkingLinesPainter(),
                  ),
                ),

              const SizedBox(height: 12),

              // Slot ID
              Text(
                slotId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 12),

              // Book Button or Status
              if (actuallyAvailable)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showBookingDialog(slotId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'BOOK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    if (nextBookingText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        nextBookingText,
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                )
              else if (isBooked)
                Column(
                  children: [
                    if (showCancel)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _cancelBooking(slotId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    if (showCancel) const SizedBox(height: 8),
                    if (!showCancel)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BOOKED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OCCUPIED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _cancelBooking(String slotId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel your booking for slot $slotId?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cancelledSpot = bookedSlots[slotId];

      if (cancelledSpot != null) {
        // Use the proper cancellation method from BookingProvider
        final provider = Provider.of<BookingProvider>(context, listen: false);

        // Find the booking ID for this slot
        try {
          final booking = provider.bookings.firstWhere(
            (b) => b.slotId == slotId && b.status == 'active',
          );

          // Cancel via backend API
          await provider.cancelBooking(booking.id);
        } catch (e) {
          // If booking not found in provider, just remove locally
          print('⚠️ Booking not found in provider, removing locally only');
        }

        // Remove from local map
        setState(() {
          bookedSlots.remove(slotId);
        });

        // Update global bookings
        await _saveGlobalBookings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking for slot $slotId has been cancelled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _showBookingDialog(String slotId) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final spot = provider.getSpotById(slotId);
    final isBooked = spot != null
        ? !spot.isAvailable
        : bookedSlots.containsKey(slotId);
    if (isBooked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slot $slotId is already booked'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'REFRESH',
              textColor: Colors.white,
              onPressed: _refreshBookings,
            ),
          ),
        );
      }
      return;
    }

    final userActiveBookings = provider.activeBookings
        .where((b) => b.userId == _userId)
        .toList();

    if (userActiveBookings.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Active Booking Exists'),
          content: Text(
            'You already have an active booking for slot ${userActiveBookings.first.slotId}. '
            'Do you want to book another slot?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Show time selection dialog
    final selection = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TimeSelectionDialog(spotName: slotId),
    );

    if (selection != null) {
      final int selectedHours = selection['duration'] as int;
      final DateTime startTime = selection['startTime'] as DateTime;
      try {
        // Create booking via backend API
        final provider = Provider.of<BookingProvider>(context, listen: false);
        final result = await provider.createBooking(
          slotId: slotId,
          userId: _userId,
          durationHours: selectedHours,
          startTime: startTime,
        );

        if (result['success'] != true) {
          // Show error if booking failed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Booking failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final booking = result['booking'];
        final now = startTime;
        final spot = ParkingSpot(
          id: slotId,
          name: slotId,
          isAvailable: false,
          status: 'booked',
          reservationTime: now,
          validityHours: selectedHours,
          qrCode: booking.qrCode, // Use backend-generated QR code
          userId: _userId,
          userName: _userName,
        );

        setState(() {
          bookedSlots[slotId] = spot;
        });

        // Save to global bookings and history
        await _saveGlobalBookings();
        await _saveReservationHistory(spot);

        // Show success message with expiry notification
        if (mounted) {
          final expiryTime = now.add(Duration(hours: selectedHours));
          final expiryTimeStr =
              '${expiryTime.hour.toString().padLeft(2, '0')}:${expiryTime.minute.toString().padLeft(2, '0')}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓ Slot $slotId booked successfully!'),
                  const SizedBox(height: 4),
                  Text(
                    'Valid until $expiryTimeStr (${selectedHours}h)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate to QR code screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRCodeScreen(spot: spot)),
          );
        }
      } catch (e) {
        // Error handling
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to book slot: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _showBookingDialog(slotId),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveReservationHistory(ParkingSpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];

    final spotJson =
        '${spot.id}|${spot.name}|${spot.reservationTime!.toIso8601String()}|${spot.validityHours}|${spot.qrCode}|${spot.userId}|${spot.userName}';
    historyJson.add(spotJson);

    await prefs.setStringList('reservationHistory', historyJson);
  }
}

// Custom painter for parking lines in empty slots
class ParkingLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.blue.shade200
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw parking bay outline
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, 5, size.width * 0.6, size.height - 10),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);

    // Draw center dashed line
    final dashWidth = 4.0;
    final dashSpace = 3.0;
    double startY = 10;

    while (startY < size.height - 10) {
      canvas.drawLine(
        Offset(size.width * 0.5, startY),
        Offset(size.width * 0.5, startY + dashWidth),
        dashedPaint,
      );
      startY += dashWidth + dashSpace;
    }

    // Draw "P" icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
