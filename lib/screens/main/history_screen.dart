import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/parking_spot.dart';
import '../main/qr_code_screen.dart';
import '../../widgets/animated_car_logo.dart';
import '../../widgets/parked_car_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ParkingSpot> _reservationHistory = [];
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadReservationHistory();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _loadReservationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];
    
    setState(() {
      _reservationHistory = historyJson.map((json) {
        // Simple JSON parsing for demo purposes
        final parts = json.split('|');
        return ParkingSpot(
          id: parts[0],
          name: parts[1],
          isAvailable: false,
          reservationTime: DateTime.parse(parts[2]),
          validityHours: int.parse(parts[3]),
          qrCode: parts[4],
          userId: parts[5],
          userName: parts[6],
          status: 'booked',
        );
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _saveReservationHistory(ParkingSpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('reservationHistory') ?? [];
    
    final spotJson = '${spot.id}|${spot.name}|${spot.reservationTime!.toIso8601String()}|${spot.validityHours}|${spot.qrCode}|${spot.userId}|${spot.userName}';
    historyJson.add(spotJson);
    
    await prefs.setStringList('reservationHistory', historyJson);
  }

  void _viewQRCode(ParkingSpot spot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScreen(spot: spot),
      ),
    );
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reservationHistory');
    setState(() {
      _reservationHistory = [];
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Reservation History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          if (_reservationHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all, color: Colors.red.shade600),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _reservationHistory.isEmpty
              ? _buildEmptyState(isMobile)
              : _buildHistoryList(isMobile),
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const AnimatedCarLogo(
                size: 64,
                carColor: Colors.blue,
                isAnimated: true,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reservations Yet',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your parking reservations will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.local_parking),
              label: const Text('Make a Reservation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const AnimatedCarLogo(
                  size: 24,
                  carColor: Colors.white,
                  isAnimated: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Reservations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_reservationHistory.length} total reservations',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _reservationHistory.length,
              itemBuilder: (context, index) {
                final spot = _reservationHistory[index];
                return _buildHistoryCard(spot, isMobile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ParkingSpot spot, bool isMobile) {
    final isExpired = spot.isExpired;
    final timeRemaining = spot.timeRemaining;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.blue.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ParkedCarWidget(
                        size: 20,
                        carColor: isExpired ? Colors.red.shade600 : Colors.blue.shade600,
                        isAnimated: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spot ${spot.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Reserved by ${spot.userName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired ? 'Expired' : 'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${spot.validityHours} hour${spot.validityHours > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Reserved: ${_formatDateTime(spot.reservationTime!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (!isExpired) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Time left: $timeRemaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewQRCode(spot),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('View QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
}
