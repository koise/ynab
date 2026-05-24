import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timezonesInitialized = false;

  NotificationService() {
    _initialize();
  }

  static Future<void> _ensureTimezonesInitialized() async {
    if (!_timezonesInitialized) {
      tz.initializeTimeZones();
      _timezonesInitialized = true;
    }
  }

  void _initialize() async {
    if (_initialized) return;

    // Notifications are not supported on web
    if (kIsWeb) return;

    await _ensureTimezonesInitialized();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Request notification permissions (no-op on web).
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    bool? iosGranted = false;
    bool? androidGranted = false;

    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      iosGranted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      androidGranted =
          await androidImplementation.requestNotificationsPermission();
    }

    return (iosGranted ?? false) || (androidGranted ?? false);
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Show an immediate budget-alert notification.
  static Future<void> scheduleBudgetAlert({
    required String categoryName,
    required double percentUsed,
    required double remaining,
    required String currencySymbol,
  }) async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      'budget_alert',
      'Budget Alerts',
      channelDescription: 'Notifies when budget usage exceeds thresholds',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(
      categoryName.hashCode,
      'Budget Alert: $categoryName',
      'Used ${(percentUsed * 100).toStringAsFixed(0)}% — '
          'Remaining $currencySymbol${remaining.toStringAsFixed(2)}',
      details,
    );
  }

  /// Schedule a daily 9 AM reminder for a recurring rule.
  static Future<void> scheduleRecurringReminder({
    required RecurringRule rule,
    required String currencySymbol,
  }) async {
    if (kIsWeb) return;

    await _ensureTimezonesInitialized();

    // Resolve the local timezone safely
    tz.Location localLocation;
    try {
      localLocation = tz.local;
    } catch (_) {
      // Fall back to UTC if local timezone is not initialized
      localLocation = tz.UTC;
    }

    final now = tz.TZDateTime.now(localLocation);
    var scheduledDate = tz.TZDateTime(
        localLocation, now.year, now.month, now.day, 9, 0, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'recurring_reminder',
      'Recurring Reminders',
      channelDescription: 'Reminds about upcoming recurring transactions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      rule.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      'Recurring: ${rule.title}',
      'Amount: $currencySymbol${rule.amount}',
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelRecurringReminder({required String ruleId}) async {
    if (kIsWeb) return;
    await _plugin.cancel(ruleId.hashCode);
  }

  void dispose() {
    // No resources to dispose currently
  }
}
