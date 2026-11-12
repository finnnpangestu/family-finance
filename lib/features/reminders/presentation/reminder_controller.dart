import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_service.dart';
import '../../../core/settings/settings_store.dart';

class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.dailyEnabled = false,
    this.hour = 20,
    this.minute = 0,
    this.budgetAlertEnabled = false,
  });

  final bool dailyEnabled;

  // Default 20:00: after dinner, when the day's spending is done.
  final int hour;
  final int minute;
  final bool budgetAlertEnabled;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static ReminderSettings parse({String? daily, String? time, String? budget}) {
    final List<int>? parts = time
        ?.split(':')
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final bool validTime =
        parts != null &&
        parts.length == 2 &&
        parts[0] >= 0 &&
        parts[0] < 24 &&
        parts[1] >= 0 &&
        parts[1] < 60;
    return ReminderSettings(
      dailyEnabled: daily == 'true',
      hour: validTime ? parts[0] : 20,
      minute: validTime ? parts[1] : 0,
      budgetAlertEnabled: budget == 'true',
    );
  }

  ReminderSettings copyWith({
    bool? dailyEnabled,
    int? hour,
    int? minute,
    bool? budgetAlertEnabled,
  }) => ReminderSettings(
    dailyEnabled: dailyEnabled ?? this.dailyEnabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    budgetAlertEnabled: budgetAlertEnabled ?? this.budgetAlertEnabled,
  );

  @override
  List<Object?> get props => [dailyEnabled, hour, minute, budgetAlertEnabled];
}

// Thrown when the user declines the notification permission.
class NotificationPermissionDenied implements Exception {
  const NotificationPermissionDenied();
}

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderSettings>(
      ReminderController.new,
    );

class ReminderController extends AsyncNotifier<ReminderSettings> {
  SettingsStore get _settings => ref.read(settingsStoreProvider);
  ReminderService get _service => ref.read(reminderServiceProvider);

  @override
  Future<ReminderSettings> build() async {
    final SettingsStore store = ref.read(settingsStoreProvider);
    return ReminderSettings.parse(
      daily: await store.read(SettingsStore.dailyReminderEnabled),
      time: await store.read(SettingsStore.dailyReminderTime),
      budget: await store.read(SettingsStore.budgetAlertEnabled),
    );
  }

  Future<void> setDailyEnabled(bool enabled) async {
    final ReminderSettings current = await future;
    if (enabled && !await _service.requestPermission()) {
      throw const NotificationPermissionDenied();
    }
    if (enabled) {
      await _service.scheduleDaily(hour: current.hour, minute: current.minute);
    } else {
      await _service.cancelDaily();
    }
    await _settings.write(SettingsStore.dailyReminderEnabled, '$enabled');
    state = AsyncData(current.copyWith(dailyEnabled: enabled));
  }

  Future<void> setTime(int hour, int minute) async {
    final ReminderSettings next = (await future).copyWith(
      hour: hour,
      minute: minute,
    );
    if (next.dailyEnabled) {
      await _service.scheduleDaily(hour: hour, minute: minute);
    }
    await _settings.write(SettingsStore.dailyReminderTime, next.timeLabel);
    state = AsyncData(next);
  }

  Future<void> setBudgetAlertEnabled(bool enabled) async {
    final ReminderSettings current = await future;
    if (enabled && !await _service.requestPermission()) {
      throw const NotificationPermissionDenied();
    }
    await _settings.write(SettingsStore.budgetAlertEnabled, '$enabled');
    state = AsyncData(current.copyWith(budgetAlertEnabled: enabled));
  }

  // Called at startup: re-registers the daily reminder, which also picks up
  // a changed timezone. Never throws; reminders must not block launch.
  Future<void> restoreSchedule() async {
    try {
      final ReminderSettings current = await future;
      if (current.dailyEnabled) {
        await _service.scheduleDaily(
          hour: current.hour,
          minute: current.minute,
        );
      }
    } catch (error) {
      debugPrint('Reminder restore skipped: $error');
    }
  }
}
