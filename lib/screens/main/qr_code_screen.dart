import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/parking_spot.dart';
import '../../widgets/animated_car_logo.dart';
import '../../theme/app_colors.dart';

class QRCodeScreen extends StatefulWidget {
  final ParkingSpot spot;

  const QRCodeScreen({
    super.key,
    required this.spot,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final qrSize = isMobile ? 180.0 : 220.0;
    final isCancelled = widget.spot.isCancelled;
    final isExpired = widget.spot.isExpired;
    final timeRemaining = widget.spot.timeRemaining;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'QR Code',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
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
                            colors: [Colors.blue.shade600, Colors.blue.shade400],
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Spot ${widget.spot.name}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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
                                    : (isExpired ? AppColors.warning : Colors.grey.shade200),
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
                              opacity: (isCancelled || isExpired) ? 0.3 : 1.0,
                              child: QrImageView(
                                data: widget.spot.qrCode ?? 'No QR Code',
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                          else if (isExpired)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black.withOpacity(0.7),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                              : (isExpired ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCancelled 
                                ? Colors.red.shade400 
                                : (isExpired ? AppColors.warning : AppColors.primary),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isCancelled ? Icons.block : (isExpired ? Icons.cancel : Icons.timer),
                                      color: isCancelled ? Colors.red.shade600 : (isExpired ? AppColors.warning : AppColors.success),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isCancelled ? 'Status:' : (isExpired ? 'Status:' : 'Time Remaining:'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCancelled ? Colors.red.shade600 : (isExpired ? AppColors.warning : AppColors.success),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCancelled ? 'CANCELLED' : (isExpired ? 'EXPIRED' : timeRemaining),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Reserved at:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Text(
                                    _formatDateTime(widget.spot.reservationTime ?? DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            if (!isExpired) ...[  
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.event_available, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Expires at:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Flexible(
                                    child: Text(
                                      _formatDateTime(
                                        widget.spot.reservationTime!.add(
                                          Duration(hours: widget.spot.validityHours),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.warning,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                Icon(Icons.code, color: Colors.grey.shade700, size: 20),
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
                                fontSize: 12,
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
                              : (isExpired ? AppColors.warning.withOpacity(0.1) : AppColors.success.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCancelled 
                                ? Colors.red.shade400 
                                : (isExpired ? AppColors.warning : AppColors.success),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCancelled ? Icons.block : (isExpired ? Icons.warning : Icons.info_outline),
                              color: isCancelled ? Colors.red.shade600 : (isExpired ? AppColors.warning : AppColors.success),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isCancelled
                                    ? 'This booking has been cancelled. The QR code is no longer valid.'
                                    : (isExpired
                                        ? 'This QR code has expired. Please book a new parking slot.'
                                        : 'Show this QR code to the parking attendant to access your spot.'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isCancelled ? Colors.red.shade600 : (isExpired ? AppColors.warning : AppColors.success),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
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
                            'Back to Parking Spots',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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