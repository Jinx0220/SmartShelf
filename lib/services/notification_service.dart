import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static final List<int> _activeNotificationIds = [];

  // Initialize notifications
  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Show low stock notification
  Future<void> showLowStockNotification(String productName, int stock) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Notifications when products are low on stock',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    _activeNotificationIds.add(id);

    await _notifications.show(
      id,
      '⚠️ Low Stock Alert',
      '$productName is low on stock! Only $stock units remaining.',
      details,
    );
  }

  // Show daily summary notification
  Future<void> showDailySummaryNotification(int totalSales, int lowStockCount) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Summary',
      channelDescription: 'Daily sales and stock summary',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch % 100000 + 1;
    _activeNotificationIds.add(id);

    await _notifications.show(
      id,
      '📊 Daily Summary',
      'Today\'s sales: NPR $totalSales | Low stock items: $lowStockCount',
      details,
    );
  }

  // Show streak notification (US-32)
  Future<void> showStreakNotification(int days) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'streak_channel',
      'Sales Streak',
      channelDescription: 'Congratulations on your sales streak!',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch % 100000 + 2;
    _activeNotificationIds.add(id);

    await _notifications.show(
      id,
      '🎉 Amazing Streak!',
      'You\'ve logged sales for $days consecutive days! Keep it up!',
      details,
    );
  }

  // US-30: Dismiss specific notification
  Future<void> dismissNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _activeNotificationIds.remove(id);
    } catch (e) {
      // Handle error
    }
  }

  // US-30: Dismiss all notifications
  Future<void> dismissAllNotifications() async {
    try {
      for (var id in _activeNotificationIds) {
        await _notifications.cancel(id);
      }
      _activeNotificationIds.clear();
      await _notifications.cancelAll();
    } catch (e) {
      // Handle error
    }
  }

  // Schedule weekly report
  Future<void> scheduleWeeklyReport() async {
    // TODO: Implement weekly report scheduling
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _activeNotificationIds.clear();
  }
}