import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/subscription/domain/entities/subscription.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('ic_diamond_filled');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(initSettings);

    // Create high importance notification channel for Android
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'alert_notifications',
          'Alert Notifications',
          description: 'Used for important alert messages like budget warnings and subscription renewals.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> scheduleSubscriptionAlert(Subscription subscription, String currency) async {
    final notificationId = subscription.id.hashCode.abs() & 0x7FFFFFFF;
    
    // Calculate alert time: 1 day before the next billing date at 9:00 AM
    DateTime alertDate = subscription.nextBillingDate.subtract(const Duration(days: 1));
    DateTime scheduledDate = DateTime(alertDate.year, alertDate.month, alertDate.day, 9, 0);

    // If 1 day before is in the past, schedule it on the billing date at 9:00 AM
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = DateTime(
        subscription.nextBillingDate.year,
        subscription.nextBillingDate.month,
        subscription.nextBillingDate.day,
        9,
        0,
      );
    }

    // If both dates are in the past, skip scheduling
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final formattedAmount = '$currency${subscription.amount.toStringAsFixed(0)}';

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Upcoming Renewal: ${subscription.name}',
      'Your subscription for ${subscription.name} ($formattedAmount) renews on ${subscription.nextBillingDate.day}/${subscription.nextBillingDate.month}.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_notifications',
          'Alert Notifications',
          channelDescription: 'Used for important alert messages like budget warnings and subscription renewals.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_diamond_filled',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelSubscriptionAlert(String subscriptionId) async {
    final notificationId = subscriptionId.hashCode.abs() & 0x7FFFFFFF;
    await _notificationsPlugin.cancel(notificationId);
  }

  Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    const notificationId = 999;
    
    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_notifications',
          'Alert Notifications',
          channelDescription: 'Used for important alert messages like budget warnings and subscription renewals.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_diamond_filled',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<bool?> requestPermission() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission();
    }
    final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return false;
  }

  Future<bool> checkPermission() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }
}
