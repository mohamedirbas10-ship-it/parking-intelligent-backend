import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/parking_spot.dart';
import '../../models/booking.dart';
import '../../widgets/animated_car_logo.dart';
import '../../theme/app_colors.dart';
import '../../services/booking_provider.dart';

class QRCodeScreen extends StatefulWidget {
  final ParkingSpot spot;

  const QRCodeScreen({super.key, required this.spot});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        // Find the latest status of this spot
        final currentSpot = provider.parkingSpots.firstWhere(
          (s) => s.id == widget.spot.id,
          orElse: () => widget.spot,
        );

        // Also check if there's an active booking for this spot
        final booking = provider.bookings.firstWhere(
          (b) => b.slotId == widget.spot.id && b.status == 'active',
          orElse: () => Booking(
            id: '',
            userId: '',
            slotId: '',
            duration: 0,
            reservedAt: DateTime.now(),
            expiresAt: DateTime.now(),
            status: 'unknown',
            qrCode: '',
          ),
        );

        // If booking is not found or not active, and the spot is available,
        // it means the booking was cancelled or completed (exit)
        final bool isInvalid =
            (booking.status == 'unknown') && currentSpot.isAvailable;

        final isCancelled =
            currentSpot.isCancelled ||
            (isInvalid &&
                provider.pastBookings.any(
                  (b) => b.slotId == widget.spot.id && b.status == 'cancelled',
                ));
        final isExpired =
            currentSpot.isExpired || (booking.status == 'expired');
        final isCompleted =
            booking.status == 'completed' || (isInvalid && !isCancelled);

        final isMobile = MediaQuery.of(context).size.width < 600;
        final qrSize = isMobile ? 160.0 : 200.0;
        final timeRemaining = currentSpot.timeRemaining;

        // Determine state for UI
        final bool showInvalid = isCancelled || isExpired || isCompleted;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'QR Code',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue.shade700,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade600,
                                  Colors.blue.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const AnimatedCarLogo(
                              size: 48,
                              carColor: Colors.white,
                              isAnimated: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Your Parking QR Code',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              'Spot ${widget.spot.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: isCancelled ? 24 : 32),
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCancelled
                                        ? Colors.red.shade300
                                        : (isExpired
                                              ? AppColors.warning
                                              : Colors.grey.shade200),
                                    width: (isCancelled || isExpired) ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Opacity(
                                  opacity: showInvalid ? 0.1 : 1.0,
                                  child: QrImageView(
                                    data: showInvalid
                                        ? 'INVALID_QR_CODE'
                                        : (widget.spot.qrCode ?? 'No QR Code'),
                                    version: QrVersions.auto,
                                    size: qrSize,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              if (isCancelled)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.block,
                                          color: Colors.red.shade400,
                                          size: 64,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'CANCELLED',
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (isCompleted)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 64,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'COMPLETED',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (isExpired)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cancel,
                                          color: AppColors.warning,
                                          size: 64,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'EXPIRED',
                                          style: TextStyle(
                                            color: AppColors.warning,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? Colors.red.withOpacity(0.1)
                                  : (isExpired
                                        ? AppColors.warning.withOpacity(0.1)
                                        : AppColors.primary.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCancelled
                                    ? Colors.red.shade400
                                    : (isExpired
                                          ? AppColors.warning
                                          : AppColors.primary),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCancelled
                                              ? Icons.block
                                              : (isExpired
                                                    ? Icons.cancel
                                                    : Icons.timer),
                                          color: isCancelled
                                              ? Colors.red.shade600
                                              : (isExpired
                                                    ? AppColors.warning
                                                    : AppColors.success),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isCancelled
                                              ? 'Status:'
                                              : (isExpired
                                                    ? 'Status:'
                                                    : 'Time:'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? Colors.red.shade600
                                            : (isExpired
                                                  ? AppColors.warning
                                                  : AppColors.success),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isCancelled
                                            ? 'CANCELLED'
                                            : (isExpired
                                                  ? 'EXPIRED'
                                                  : timeRemaining),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isCancelled ? 12 : 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Reserved:',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Expanded(
                                      child: Text(
                                        _formatDateTime(
                                          widget.spot.reservationTime ??
                                              DateTime.now(),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        textAlign: TextAlign.end,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isExpired) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            color: AppColors.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Expires:',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: Text(
                                          _formatDateTime(
                                            widget.spot.reservationTime!.add(
                                              Duration(
                                                hours:
                                                    widget.spot.validityHours,
                                              ),
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.warning,
                                          ),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: isCancelled ? 16 : 24),
                          // QR Code Text (for copying)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.code,
                                      color: Colors.grey.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'QR Code Data:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  widget.spot.qrCode ?? 'No QR Code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select and copy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? Colors.red.withOpacity(0.1)
                                  : (isExpired
                                        ? AppColors.warning.withOpacity(0.1)
                                        : AppColors.success.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCancelled
                                    ? Colors.red.shade400
                                    : (isExpired
                                          ? AppColors.warning
                                          : AppColors.success),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCancelled
                                      ? Icons.block
                                      : (isExpired
                                            ? Icons.warning
                                            : Icons.info_outline),
                                  color: isCancelled
                                      ? Colors.red.shade600
                                      : (isExpired
                                            ? AppColors.warning
                                            : AppColors.success),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isCancelled
                                        ? 'Booking cancelled. QR code is no longer valid.'
                                        : (isExpired
                                              ? 'QR code expired. Please book a new slot.'
                                              : 'Show this QR code to access your spot.'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCancelled
                                          ? Colors.red.shade600
                                          : (isExpired
                                                ? AppColors.warning
                                                : AppColors.success),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isCancelled ? 20 : 32),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shadowColor: Colors.blue.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Back',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!isCancelled &&
                                  !isExpired &&
                                  !isCompleted) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Cancel booking
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Cancel Booking'),
                                            content: Text(
                                              'Are you sure you want to cancel your booking for slot ${widget.spot.name}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('NO'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade600,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text(
                                                  'YES, CANCEL',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          if (booking.id.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Booking not found',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await provider.cancelBooking(
                                            booking.id,
                                          );

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Booking cancelled',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red.shade700,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
