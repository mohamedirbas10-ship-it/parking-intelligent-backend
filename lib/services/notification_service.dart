import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> showParkingExpiryWarning({
    required String slotId,
    required int minutesRemaining,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'parking_expiry',
      'Parking Expiry Alerts',
      channelDescription: 'Notifications for parking time expiring soon',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      slotId.hashCode,
      'Parking Time Ending Soon!',
      'Your parking at slot $slotId expires in $minutesRemaining minutes',
      details,
      payload: slotId,
    );
  }

  Future<void> showBookingConfirmation({
    required String slotId,
    required DateTime expiryTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_confirmation',
      'Booking Confirmations',
      channelDescription: 'Notifications for successful bookings',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      slotId.hashCode + 1000,
      'Booking Confirmed!',
      'Slot $slotId is reserved until ${expiryTime.hour}:${expiryTime.minute.toString().padLeft(2, '0')}',
      details,
      payload: slotId,
    );
  }

  Future<void> cancelNotification(String slotId) async {
    await _notifications.cancel(slotId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
