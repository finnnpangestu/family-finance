import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(),
);

// Local notifications only: a daily "record your expenses" reminder and
// one-off budget alerts. No server, works offline.
class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;
  static const int _budgetAlertBaseId = 2000;

  static const NotificationDetails _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Pengingat harian',
      channelDescription: 'Pengingat untuk mencatat pengeluaran hari ini',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _budgetDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'budget_alert',
      'Peringatan anggaran',
      channelDescription: 'Muncul saat pengeluaran mendekati batas anggaran',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;

  // Safe to call repeatedly; permission is asked separately, on demand.
  Future<void> ensureInitialized() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (error) {
      // Falls back to UTC; reminders may then drift by the UTC offset.
      debugPrint('Local timezone unavailable: $error');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  // Returns false when the user declines.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    final bool? android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final bool? ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? false;
  }

  // Repeats every day at hour:minute local time. Inexact on purpose: no
  // exact-alarm permission is needed, and a few minutes late is fine.
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await ensureInitialized();
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Sudah catat pengeluaran hari ini?',
      body: 'Ketuk untuk mencatat pengeluaran keluarga hari ini.',
      scheduledDate: nextInstanceOf(hour, minute, tz.TZDateTime.now(tz.local)),
      notificationDetails: _reminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await ensureInitialized();
    await _plugin.cancel(id: _dailyReminderId);
  }

  // One notification per category so repeated alerts replace each other.
  Future<void> showBudgetAlert({
    required String categoryName,
    required String message,
  }) async {
    await ensureInitialized();
    await _plugin.show(
      id: _budgetAlertBaseId + categoryName.hashCode.abs() % 1000,
      title: 'Peringatan anggaran',
      body: message,
      notificationDetails: _budgetDetails,
    );
  }

  // Today at hour:minute if still ahead, otherwise tomorrow.
  @visibleForTesting
  static tz.TZDateTime nextInstanceOf(int hour, int minute, tz.TZDateTime now) {
    tz.TZDateTime scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
