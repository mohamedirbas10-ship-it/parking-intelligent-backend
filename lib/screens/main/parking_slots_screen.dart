import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/booking_provider.dart';
import '../../services/notification_service.dart';
import 'booking_history_screen.dart';

class ParkingSlotsScreen extends StatefulWidget {
  const ParkingSlotsScreen({super.key});

  @override
  State<ParkingSlotsScreen> createState() => _ParkingSlotsScreenState();
}

class _ParkingSlotsScreenState extends State<ParkingSlotsScreen> with TickerProviderStateMixin {
  final String userName = 'Mohamed'; // You can change this to any user name
  final String userId = 'user_mohamed';
  late AnimationController _refreshController;
  
  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Initialize notifications
    NotificationService().initialize();
    
    // Load user bookings from backend (with error handling)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      provider.loadUserBookings(userId).catchError((error) {
        print('⚠️ Could not load user bookings: $error');
      });
    });
  }
  
  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Blue Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                    // History Button with badge
                    Consumer<BookingProvider>(
                      builder: (context, provider, child) {
                        final activeCount = provider.activeBookings.length;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history, color: Colors.white),
                              tooltip: 'Booking History',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BookingHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                            if (activeCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$activeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      tooltip: 'User Profile',
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Welcome Message
                Text(
                  'Welcome, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content with Real-time Updates
          Expanded(
            child: Container(
              color: const Color(0xFF607D8B),
              child: Consumer<BookingProvider>(
                builder: (context, provider, child) {
                  final spots = provider.parkingSpots;
                  final availableCount = spots.where((s) => s.isAvailable).length;
                  
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with availability stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Parking Slots',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$availableCount/${spots.length} Available',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Entry Label
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'ENTRY',
                                  semanticsLabel: 'Parking lot entry point',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Parking Slots Grid with Real-time Data
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
                                      color: Colors.white30,
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
    if (spot == null) return const SizedBox.shrink();
    
    final isAvailable = spot.isAvailable;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Semantics(
        label: 'Parking slot $slotId, ${isAvailable ? "available" : "occupied"}',
        button: isAvailable,
        child: Column(
          children: [
            // Parking Slot Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAvailable ? Colors.green.shade300 : Colors.red.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Car Icon or Empty with animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: !isAvailable
                        ? Icon(
                            Icons.directions_car,
                            key: ValueKey('car_$slotId'),
                            size: 40,
                            color: Colors.red.shade600,
                            semanticLabel: 'Car parked',
                          )
                        : Container(
                            key: ValueKey('empty_$slotId'),
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green.shade300,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade600,
                              semanticLabel: 'Slot available',
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Slot ID
                  Text(
                    slotId,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  // Time remaining if occupied
                  if (!isAvailable && spot.reservationTime != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            spot.timeRemaining,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Book Button with animation
                  if (isAvailable)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showBookingDialog(provider, slotId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'BOOK NOW',
                          semanticsLabel: 'Book this parking slot',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OCCUPIED',
                        textAlign: TextAlign.center,
                        semanticsLabel: 'Slot occupied',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BookingProvider provider, String slotId) {
    int selectedHours = 2;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.local_parking, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Book Parking Slot'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot: $slotId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Duration:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 6, 8].map((hours) {
                  final isSelected = selectedHours == hours;
                  return ChoiceChip(
                    label: Text('$hours hr${hours > 1 ? 's' : ''}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedHours = hours;
                      });
                    },
                    selectedColor: Colors.green.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                
                // Animate booking action
                _refreshController.forward().then((_) {
                  _refreshController.reverse();
                });
                
                // Create booking
                final result = await provider.createBooking(
                  slotId: slotId,
                  userId: userId,
                  durationHours: selectedHours,
                );
                
                if (mounted) {
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Slot $slotId booked for $selectedHours hour${selectedHours > 1 ? 's' : ''}!',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        action: SnackBarAction(
                          label: 'VIEW',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Booking failed'),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
