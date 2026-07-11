import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin
  _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    const android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings =
    InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  Future<void> showLowStockNotification(
      String productName,
      int stock,
      ) async {
    await _notifications.show(
      0,
      'Low Stock Alert',
      '$productName only has $stock items left',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock',
          'Low Stock',
          importance: Importance.max,
        ),
      ),
    );
  }

  Future<void> showDailySummaryNotification(
      int totalSales,
      int lowStockCount,
      ) async {
    await _notifications.show(
      1,
      'Daily Summary',
      'Sales: $totalSales | Low Stock: $lowStockCount',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summary',
          importance: Importance.high,
        ),
      ),
    );
  }

  Future<void> scheduleWeeklyReport() async {
    // Implement later
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}