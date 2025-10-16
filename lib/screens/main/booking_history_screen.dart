import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/parking_spot.dart';
import 'qr_code_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<ParkingSpot> _allBookings = [];
  List<ParkingSpot> _activeBookings = [];
  List<ParkingSpot> _expiredBookings = [];
  List<ParkingSpot> _cancelledBookings = [];
  String _userId = '';
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = All, 1 = Active, 2 = Expired, 3 = Cancelled

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userEmail') ?? '';
    final historyJson = prefs.getStringList('reservationHistory') ?? [];

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

    // Filter by current user
    final userBookings = allSpots.where((spot) => spot.userId == _userId).toList();

    // Sort by date (newest first)
    userBookings.sort((a, b) => b.reservationTime!.compareTo(a.reservationTime!));

    setState(() {
      _allBookings = userBookings;
      _activeBookings = userBookings.where((spot) => !spot.isExpired && !spot.isCancelled).toList();
      _expiredBookings = userBookings.where((spot) => spot.isExpired && !spot.isCancelled).toList();
      _cancelledBookings = userBookings.where((spot) => spot.isCancelled).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTab('All', 0, _allBookings.length),
                      ),
                      Expanded(
                        child: _buildTab('Active', 1, _activeBookings.length),
                      ),
                      Expanded(
                        child: _buildTab('Expired', 2, _expiredBookings.length),
                      ),
                      Expanded(
                        child: _buildTab('Cancelled', 3, _cancelledBookings.length),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildTab(String title, int index, int count) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue.shade700 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    List<ParkingSpot> bookings;
    switch (_selectedTab) {
      case 1:
        bookings = _activeBookings;
        break;
      case 2:
        bookings = _expiredBookings;
        break;
      case 3:
        bookings = _cancelledBookings;
        break;
      default:
        bookings = _allBookings;
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(bookings[index]);
      },
    );
  }

  Widget _buildHistoryCard(ParkingSpot spot) {
    final isCancelled = spot.isCancelled;
    final isExpired = spot.isExpired;
    final statusColor = isCancelled ? Colors.red : (isExpired ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCancelled ? Icons.cancel : Icons.local_parking,
                    color: statusColor.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slot ${spot.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCancelled ? 'CANCELLED' : (isExpired ? 'EXPIRED' : 'ACTIVE'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Booked on', _formatDateTime(spot.reservationTime!)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Duration', '${spot.validityHours} hour${spot.validityHours > 1 ? 's' : ''}'),
            const SizedBox(height: 8),
            _buildInfoRow(
              isCancelled ? Icons.block : (isExpired ? Icons.cancel : Icons.timer),
              isCancelled ? 'Status' : (isExpired ? 'Expired' : 'Time Remaining'),
              isCancelled ? 'Booking cancelled' : (isExpired ? 'Booking expired' : spot.timeRemaining),
            ),
            if (!isExpired && !isCancelled) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRCodeScreen(spot: spot),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('VIEW QR CODE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
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
}
