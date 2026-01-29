import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TimeSelectionDialog extends StatefulWidget {
  final String spotName;

  const TimeSelectionDialog({super.key, required this.spotName});

  @override
  State<TimeSelectionDialog> createState() => _TimeSelectionDialogState();
}

class _TimeSelectionDialogState extends State<TimeSelectionDialog> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    super.initState();
    // Set default start time to current time
    final now = TimeOfDay.now();
    startTime = now;
    // Set default end time to 2 hours from now
    endTime = TimeOfDay(hour: (now.hour + 2) % 24, minute: now.minute);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startTime = picked;
        // If end time is before start time, adjust it
        if (endTime != null && _isTimeBefore(endTime!, picked)) {
          endTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        endTime = picked;
      });
    }
  }

  bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour < time2.hour) return true;
    if (time1.hour == time2.hour && time1.minute < time2.minute) return true;
    return false;
  }

  int _calculateDurationInHours() {
    if (startTime == null || endTime == null) return 0;

    int startMinutes = startTime!.hour * 60 + startTime!.minute;
    int endMinutes = endTime!.hour * 60 + endTime!.minute;

    // Handle overnight bookings
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Add 24 hours
    }

    int durationMinutes = endMinutes - startMinutes;
    // Round up to nearest hour
    return (durationMinutes / 60).ceil();
  }

  String _formatDuration() {
    final hours = _calculateDurationInHours();
    if (hours == 0) return '0 minutes';
    if (hours == 1) return '1 hour';
    return '$hours hours';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final duration = _calculateDurationInHours();
    final isValid = duration > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: const Icon(
                Icons.access_time,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Time',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose start and end time for Spot ${widget.spotName}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Start Time
            _buildTimeSelector(
              label: 'Start Time',
              time: startTime,
              icon: Icons.login,
              onTap: _selectStartTime,
            ),

            const SizedBox(height: 16),

            // End Time
            _buildTimeSelector(
              label: 'End Time',
              time: endTime,
              icon: Icons.logout,
              onTap: _selectEndTime,
            ),

            const SizedBox(height: 20),

            // Duration Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isValid ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: isValid
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_formatDuration()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isValid
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),

            if (!isValid) ...[
              const SizedBox(height: 8),
              Text(
                'End time must be after start time',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isValid
                        ? () {
                            SchedulerBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              final now = DateTime.now();
                              final selectedStart = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                startTime!.hour,
                                startTime!.minute,
                              );
                              final effectiveStart = selectedStart.isBefore(now)
                                  ? selectedStart.add(const Duration(days: 1))
                                  : selectedStart;
                              Navigator.pop(context, {
                                'duration': duration,
                                'startTime': effectiveStart,
                              });
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue.shade600, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null ? time.format(context) : '--:--',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
