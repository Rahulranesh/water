import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../models/hydro_state.dart';
import '../models/weather_model.dart';

class ReminderService {
  const ReminderService();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Schedule building ──────────────────────────────────────────────────────

  List<TimeOfDay> buildSchedule(
    UserProfile profile,
    ReminderSettings settings,
  ) {
    return _buildSlots(profile, settings, null)
        .map((s) => s.time)
        .toList();
  }

  List<_ReminderSlot> _buildSlots(
    UserProfile profile,
    ReminderSettings settings,
    WeatherData? weather,
  ) {
    if (!settings.enabled) return const [];

    final intervalMinutes = weather?.reminderIntervalMinutes
        ?? settings.intervalMinutes;

    final wake = _minutes(profile.wakeTime);
    final sleep = _minutes(profile.sleepTime);
    final end = sleep > wake ? sleep : sleep + Duration.minutesPerDay;
    final slots = <_ReminderSlot>[];

    for (
      var minute = wake + intervalMinutes;
      minute < end;
      minute += intervalMinutes
    ) {
      final normalized = minute % Duration.minutesPerDay;
      final time = TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
      if (!_inQuietWindow(time, settings)) {
        slots.add(_ReminderSlot(
          time: time,
          weather: weather,
          index: slots.length,
        ));
      }
    }

    return slots;
  }

  // ── Permission + schedule ──────────────────────────────────────────────────

  Future<bool> requestPermissionsAndSchedule({
    required UserProfile profile,
    required ReminderSettings settings,
    WeatherData? weather,
  }) async {
    final slots = _buildSlots(profile, settings, weather);

    debugPrint(
      'HydroFlow reminders (${slots.length} splits${weather != null ? ' @ ${weather.temperatureLabel}' : ''}): '
      '${slots.map((s) => '${s.time.hour}:${s.time.minute.toString().padLeft(2, '0')}').join(', ')}',
    );

    if (!kIsWeb) {
      await _ensureInitialized();
      await _cancelAll();
      for (final slot in slots) {
        await _scheduleSlot(slot, profile, settings);
      }
    }

    return slots.isNotEmpty || !settings.enabled;
  }

  Future<void> showInstantTestNotification() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    
    await _plugin.show(
      id: 999,
      title: '💧 Test Hydration Check',
      body: 'This is a test notification confirming HydroFlow reminders are correctly configured!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydroflow_test_reminders',
          'Test Reminders',
          channelDescription: 'Used for testing notification configuration.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
    );
  }

  // ── Local notification plumbing ───────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> _cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _scheduleSlot(
    _ReminderSlot slot,
    UserProfile profile,
    ReminderSettings settings,
  ) async {
    try {
      final now = DateTime.now();
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        slot.time.hour,
        slot.time.minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);

      final title = _notificationTitle(slot);
      final body = _notificationBody(slot);

      await _plugin.zonedSchedule(
        id: slot.index + 100,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'hydroflow_reminders',
            'Hydration Reminders',
            channelDescription:
                'Smart reminders to keep you hydrated throughout the day.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('ReminderService schedule error slot ${slot.index}: $e');
    }
  }

  String _notificationTitle(_ReminderSlot slot) {
    final weather = slot.weather;
    if (weather == null) return '💧 Hydration Check';
    final t = weather.temperatureC;
    if (t >= 38) return '🔥 Extreme Heat — Drink Now!';
    if (t >= 30) return '☀️ Hot Day — Stay Hydrated';
    if (t >= 20) return '💧 Time for a Sip';
    return '❄️ Stay Hydrated Today';
  }

  String _notificationBody(_ReminderSlot slot) {
    final weather = slot.weather;
    if (weather == null) {
      return 'Your body is waiting for water. Have a glass now!';
    }
    final t = weather.temperatureC;
    final city = weather.city;
    if (t >= 38) {
      return 'It\'s ${ t.round()}°C in $city. Drink 300ml right now — extreme heat dehydrates fast.';
    }
    if (t >= 33) {
      return 'At ${t.round()}°C in $city your water needs are elevated. Have 250ml now.';
    }
    if (t >= 28) {
      return 'It\'s warm in $city (${t.round()}°C). Keep sipping — aim for 200ml this round.';
    }
    if (t >= 20) {
      return 'Comfortable ${t.round()}°C in $city. A steady sip now keeps your goal on track.';
    }
    return 'Cool ${t.round()}°C in $city. Don\'t forget — cool air is dehydrating too!';
  }

  bool get nativeNotificationsAvailable => !kIsWeb;
}

class _ReminderSlot {
  const _ReminderSlot({
    required this.time,
    required this.weather,
    required this.index,
  });
  final TimeOfDay time;
  final WeatherData? weather;
  final int index;
}

int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

bool _inQuietWindow(TimeOfDay time, ReminderSettings settings) {
  final start = settings.quietStart;
  final end = settings.quietEnd;
  if (start == null || end == null) return false;

  final value = _minutes(time);
  final startValue = _minutes(start);
  final endValue = _minutes(end);
  if (startValue <= endValue) {
    return value >= startValue && value <= endValue;
  }
  return value >= startValue || value <= endValue;
}
