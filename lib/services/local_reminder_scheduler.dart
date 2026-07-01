// LocalReminderScheduler
//
// Schedules fixed-time recurring reminders LOCALLY on the device using
// `flutter_local_notifications` + Android's `AlarmManager` (via
// `AndroidScheduleMode.exactAllowWhileIdle`). This avoids the multi-hour
// delivery lag that plagues FCM pushes on phones with aggressive battery
// optimization (Xiaomi/Oppo/Vivo/Samsung) — local alarms are scheduled
// directly with the OS and fire at the exact wall-clock moment even under
// Doze.
//
// Owned reminder types:
//   • morning_azkaar      every day at 08:00 local
//   • daily_astaghfir     every day at 11:00 local
//   • evening_azkaar      every day at 15:30 local (Asr window)
//   • sleep_azkar         every day at 21:00 local
//   • surah_kahf_friday   every Friday at 07:00 and 16:00 local
//   • salawat_friday      every Friday at 12:00 local
//
// Server-side FCM crons for these 4 types were retired in favour of this
// scheduler — see migration `20260629_020_drop_local_scheduled_crons.sql`.
//
// All other (event-driven) notifications — streak-at-risk, level-up-close,
// resume-reading, community-momentum, monthly-* — stay on FCM because we
// can't predict their firing time on the device.
//
// Stable notification IDs (so re-scheduling doesn't pile up duplicates):
//   9001 morning, 9002 evening, 9003 sleep, 9004 kahf-am, 9005 kahf-pm.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderScheduler {
  LocalReminderScheduler._();
  static final LocalReminderScheduler instance = LocalReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Same channel id used by the FCM handler — keeps all our notifications in
  // a single user-controllable channel.
  static const _channelId = 'sabiq_default_channel';
  static const _channelName = 'Sabiq Rewards Notifications';

  bool _initialized = false;

  // ── IDs ────────────────────────────────────────────────────────────────────
  static const _idMorning   = 9001;
  static const _idEvening   = 9002;
  static const _idSleep     = 9003;
  static const _idKahfAm    = 9004;
  static const _idKahfPm    = 9005;
  static const _idAstaghfir = 9006;
  static const _idSalawat   = 9007;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // tz database — safe to call multiple times.
    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('[LocalReminderScheduler] tz fallback to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    // Channel itself is created by NotificationService.init() — we just
    // schedule against it here.
    await _plugin.initialize(settings: initSettings);
  }

  /// Re-schedules ALL local reminders. Safe to call repeatedly — each id is
  /// cancelled before being re-scheduled so we never end up with duplicates.
  /// Call after app launch (post-auth) and again whenever the user changes
  /// timezone or toggles a reminder preference.
  Future<void> scheduleAll() async {
    await init();
    try {
      await _scheduleDaily(_idMorning,  8,  0, 'morning',
        title: 'Morning Azkar',
        body: 'Start your day under Allah\'s protection — recite the morning adhkar.');
      await _scheduleDaily(_idAstaghfir, 11, 0, 'dhikr',
        title: 'A moment for istighfar',
        body: '"Astaghfirullah" polishes the heart and opens doors of provision. Pause for one minute.');
      await _scheduleDaily(_idEvening, 15, 30, 'evening',
        title: 'Evening Azkar',
        body: 'Protect yourself for the night — recite the evening adhkar.');
      await _scheduleDaily(_idSleep,   21, 0, 'dhikr',
        title: 'Time to wind down',
        body: 'End the day with sleep adhkar — Ayatul Kursi, the 3 Quls, and the bedtime du\'as.');
      await _scheduleWeekly(_idKahfAm, DateTime.friday,  7, 0, 'quran',
        title: 'It\'s Friday — read Surah Al-Kahf',
        body: 'Whoever recites Surah Al-Kahf on Friday, light shines for them between the two Fridays.');
      await _scheduleWeekly(_idSalawat, DateTime.friday, 12, 0, 'dhikr',
        title: 'Salawat on Friday',
        body: 'Recite salawat upon the Prophet ﷺ generously today — the deeds of Friday are shown to him.');
      await _scheduleWeekly(_idKahfPm, DateTime.friday, 16, 0, 'quran',
        title: 'Don\'t miss Surah Al-Kahf today',
        body: 'A few hours to Maghrib — finish Surah Al-Kahf if you haven\'t yet.');
    } catch (e) {
      debugPrint('[LocalReminderScheduler] scheduleAll failed: $e');
    }
  }

  /// Wipes every locally-scheduled reminder. Used when the user disables
  /// notifications globally or signs out.
  Future<void> cancelAll() async {
    await init();
    for (final id in const [
      _idMorning, _idEvening, _idSleep,
      _idKahfAm, _idKahfPm,
      _idAstaghfir, _idSalawat,
    ]) {
      try {
        await _plugin.cancel(id: id);
      } catch (_) {}
    }
  }

  // ── internals ──────────────────────────────────────────────────────────────

  Future<void> _scheduleDaily(
    int id,
    int hour,
    int minute,
    String route, {
    required String title,
    required String body,
  }) async {
    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Daily recurrence by matching wall-clock time only.
      matchDateTimeComponents: DateTimeComponents.time,
      payload: route,
    );
  }

  Future<void> _scheduleWeekly(
    int id,
    int weekday,
    int hour,
    int minute,
    String route, {
    required String title,
    required String body,
  }) async {
    await _plugin.cancel(id: id);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextWeekdayInstance(weekday, hour, minute),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Weekly recurrence (matches day-of-week + time).
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: route,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  tz.TZDateTime _nextWeekdayInstance(int weekday, int hour, int minute) {
    var when = _nextInstanceOf(hour, minute);
    while (when.weekday != weekday) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
