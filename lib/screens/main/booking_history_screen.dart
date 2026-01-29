import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/booking.dart';
import '../../services/booking_provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _userId = '';
  int _selectedTab = 0; // 0 = All, 1 = Active, 2 = Completed, 3 = Cancelled

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userEmail') ?? 'user_mohamed';
    });

    // Load bookings from backend
    if (mounted) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      await provider.loadUserBookings(_userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Consumer<BookingProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        await provider.loadUserBookings(_userId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bookings refreshed!'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
              );
            },
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          final allBookings = provider.bookings;
          final activeBookings = provider.activeBookings;
          final completedBookings = provider.pastBookings;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Tab Bar
              Container(
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(child: _buildTab('All', 0, allBookings.length)),
                    Expanded(
                      child: _buildTab('Active', 1, activeBookings.length),
                    ),
                    Expanded(
                      child: _buildTab(
                        'Completed',
                        2,
                        completedBookings.length,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _buildContent(
                  allBookings,
                  activeBookings,
                  completedBookings,
                ),
              ),
            ],
          );
        },
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

  Widget _buildContent(
    List<Booking> allBookings,
    List<Booking> activeBookings,
    List<Booking> completedBookings,
  ) {
    List<Booking> bookings;
    switch (_selectedTab) {
      case 1:
        bookings = activeBookings;
        break;
      case 2:
        bookings = completedBookings;
        break;
      default:
        bookings = allBookings;
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade300),
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

  Widget _buildHistoryCard(Booking booking) {
    final isActive = booking.status == 'active' && !booking.isExpired;
    final isCompleted = booking.status == 'completed' || booking.isExpired;
    final isCancelled = booking.status == 'cancelled';

    final statusColor = isCancelled
        ? Colors.red
        : (isCompleted ? Colors.orange : Colors.green);

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
                        'Slot ${booking.slotId}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCancelled
                              ? 'CANCELLED'
                              : (isCompleted ? 'COMPLETED' : 'ACTIVE'),
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
            _buildInfoRow(
              Icons.calendar_today,
              'Booked on',
              _formatDateTime(booking.reservedAt),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Duration',
              '${booking.duration} hour${booking.duration > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              isCancelled
                  ? Icons.block
                  : (isCompleted ? Icons.check_circle : Icons.timer),
              isCancelled
                  ? 'Status'
                  : (isCompleted ? 'Status' : 'Time Remaining'),
              isCancelled
                  ? 'Booking cancelled'
                  : (isCompleted ? 'Completed' : booking.timeRemaining),
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Show QR code
                        _showQRCode(booking);
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Cancel booking
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Booking'),
                            content: Text(
                              'Are you sure you want to cancel your booking for slot ${booking.slotId}?',
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
                          final provider = Provider.of<BookingProvider>(
                            context,
                            listen: false,
                          );
                          await provider.cancelBooking(booking.id);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Booking for slot ${booking.slotId} cancelled',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('CANCEL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
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
            ],
          ],
        ),
      ),
    );
  }

  void _showQRCode(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - Slot ${booking.slotId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.qrCode,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Time Remaining: ${booking.timeRemaining}',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
