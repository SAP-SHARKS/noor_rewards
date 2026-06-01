// lib/services/live_notification_service.dart
//
// Persistent "live" notification — like Sweatcoin's step counter.
// Shows today's Quran ayat and Dhikr count in the Android notification shade.
// Stays pinned and updates in real time as the user reads/does dhikr.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NoorLiveNotificationService {
  NoorLiveNotificationService._();
  static final NoorLiveNotificationService instance =
      NoorLiveNotificationService._();

  static const int _notifId = 1001; // stable ID — updates same notif
  static const String _channelId = 'noor_live_stats';
  static const String _channelName = 'Live Noor Stats';

  // Validate-reminder scheduled notification (system-level, fires even
  // when the app is closed). Separate channel + ID from the live stats
  // notification above so they don't fight each other.
  static const int _validateNotifId = 1002;
  static const String _validateChannelId = 'noor_validate_reminder';
  static const String _validateChannelName = 'Seal Reminders';
  static const String _kLastValidateScheduledDate =
      'noor_validate_reminder_scheduled_date';
  bool _tzInitialized = false;

  // SharedPreferences keys (auto-reset at midnight)
  static const String _kAyahKey = 'noor_today_ayah';
  static const String _kDhikrKey = 'noor_today_dhikr';
  static const String _kQuranTimeKey = 'noor_today_quran_sec';
  static const String _kDateKey = 'noor_stat_date';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  int _ayahCount = 0;
  int _dhikrCount = 0;
  int _quranTimeSec = 0;
  DateTime? _quranScreenEnteredAt;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Request iOS permission inside init so users see the system prompt the
    // first time the live notification fires (mirrors Android 13+ behavior).
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Request permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request iOS permission (in case the system prompt was suppressed during
    // initialize, e.g. on subsequent launches).
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: false);

    _initialized = true;
    await _loadCounts();
    await _refresh();
  }

  // ── Public API ─────────────────────────────────────────────────────────────
  /// Call after each Quran ayah is read.
  Future<void> recordAyah({int count = 1}) async {
    await _ensureInit();
    await _maybeSyncDate();
    _ayahCount += count;
    await _saveCounts();
    await _refresh();
  }

  /// Call when user enters Quran reader screen.
  void enterQuranScreen() {
    _quranScreenEnteredAt = DateTime.now();
  }

  /// Call when user leaves Quran reader screen — accumulates time.
  Future<void> exitQuranScreen() async {
    if (_quranScreenEnteredAt == null) return;
    await _ensureInit();
    await _maybeSyncDate();
    final sec = DateTime.now().difference(_quranScreenEnteredAt!).inSeconds;
    _quranScreenEnteredAt = null;
    if (sec < 2) return;
    _quranTimeSec += sec;
    await _saveCounts();
    await _refresh();
  }

  /// Call when app goes to background — pause time accumulation.
  Future<void> pauseQuranTimer() async {
    if (_quranScreenEnteredAt == null) return;
    final sec = DateTime.now().difference(_quranScreenEnteredAt!).inSeconds;
    _quranScreenEnteredAt = null; // stop counting
    if (sec < 2) return;
    await _ensureInit();
    await _maybeSyncDate();
    _quranTimeSec += sec;
    await _saveCounts();
    await _refresh();
  }

  /// Call when app resumes from background — restart time counting.
  void resumeQuranTimer() {
    // Only restart if we were tracking before (enterQuranScreen was called)
    // The caller should guard this — only call if Quran screen is active
    _quranScreenEnteredAt = DateTime.now();
  }

  /// Call after each Dhikr set is completed.
  Future<void> recordDhikr({int count = 1}) async {
    await _ensureInit();
    await _maybeSyncDate();
    _dhikrCount += count;
    await _saveCounts();
    await _refresh();
  }

  // ── Validate reminder (system-level scheduled notification) ─────────────────
  // Lazy-init the tz DB so we can use zonedSchedule.
  Future<void> _ensureTimezone() async {
    if (_tzInitialized) return;
    try {
      tzdata.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName.identifier));
      _tzInitialized = true;
    } catch (e) {
      // Fall back to UTC if tz init fails — the schedule still works,
      // just not in the user's exact local time.
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
      _tzInitialized = true;
      debugPrint('Timezone init fell back to UTC: $e');
    }
  }

  /// Schedules a system notification reminding the user to seal their
  /// pending Seeds before midnight. Fires even if the app is closed.
  /// Re-runs are idempotent for a given day — only schedules once per day.
  Future<void> scheduleValidateReminder(int pendingSeeds) async {
    if (kIsWeb || pendingSeeds <= 0) return;
    await _ensureInit();
    await _ensureTimezone();

    // Only schedule once per day to avoid duplicate notifications when the
    // dashboard reloads multiple times.
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    if (prefs.getString(_kLastValidateScheduledDate) == today) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    // Default target: 10 PM local. If we're already past 10 PM, schedule
    // 15 minutes from now so the user still gets the reminder tonight.
    tz.TZDateTime when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22, // 10 PM
      0,
    );
    if (when.isBefore(now)) {
      when = now.add(const Duration(minutes: 15));
    }
    // If 'when' is after midnight (shouldn't be but defensive), bail.
    final midnight = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      0,
      0,
    );
    if (when.isAfter(midnight)) return;

    final androidDetails = AndroidNotificationDetails(
      _validateChannelId,
      _validateChannelName,
      channelDescription:
          'Reminders to seal your pending Seeds before midnight.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Seal your Seeds before midnight',
      color: const Color(0xFFFFC83D),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _plugin.zonedSchedule(
        id: _validateNotifId,
        title: 'Seal your Seeds before midnight!',
        body:
            'You have $pendingSeeds pending Seeds. Tap Seal the Day before midnight or they expire.',
        scheduledDate: when,
        notificationDetails:
            NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      await prefs.setString(_kLastValidateScheduledDate, today);
      debugPrint('[NoorLive] scheduled validate reminder for $when');
    } catch (e) {
      debugPrint('[NoorLive] scheduleValidateReminder failed: $e');
    }
  }

  /// Cancels the pending validate reminder. Call after a successful seal.
  Future<void> cancelValidateReminder() async {
    if (kIsWeb) return;
    await _ensureInit();
    try {
      await _plugin.cancel(id: _validateNotifId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastValidateScheduledDate);
    } catch (e) {
      debugPrint('[NoorLive] cancelValidateReminder failed: $e');
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────
  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  Future<void> _refresh() async {
    if (kIsWeb) return;

    final lines = <String>[];

    // Quran lines
    if (_ayahCount > 0) {
      lines.add('$_ayahCount Ayat Read today 📖');
    }
    if (_quranTimeSec >= 60) {
      lines.add('${_formatTime(_quranTimeSec)} Read Quran today ⏱️');
    }
    if (_ayahCount == 0 && _quranTimeSec < 60) {
      lines.add('Nothing Read from Quran today 📖');
    }

    // Dhikr line
    if (_dhikrCount > 0) {
      lines.add('$_dhikrCount Dhikr completed today 📿');
    }

    final ticker =
        _ayahCount > 0
            ? '$_ayahCount ayat · $_dhikrCount dhikr today'
            : 'Keep reading and doing Dhikr!';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: "Live today's Quran and Dhikr progress",
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      ticker: ticker,
      styleInformation: BigTextStyleInformation(
        lines.join('\n'),
        contentTitle: 'Your Seeds Today ✨',
        summaryText: 'Tap to open Sabiq',
      ),
      color: const Color(0xFF6B4EBB),
    );

    // iOS has no concept of "ongoing" notifications, so we present silently
    // (no sound, no banner re-alert) and rely on the stable id to update the
    // single notification in place each time _refresh runs.
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      presentBanner: false,
      presentList: true,
      interruptionLevel: InterruptionLevel.passive,
      threadIdentifier: _channelId,
    );

    await _plugin.show(
      id: _notifId,
      title: 'Your Seeds Today ✨',
      body: lines.join('  •  '),
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(_kDateKey) ?? '';
      if (savedDate != _todayStr()) {
        _ayahCount = 0;
        _dhikrCount = 0;
        _quranTimeSec = 0;
        await prefs.setString(_kDateKey, _todayStr());
        await prefs.setInt(_kAyahKey, 0);
        await prefs.setInt(_kDhikrKey, 0);
        await prefs.setInt(_kQuranTimeKey, 0);
      } else {
        _ayahCount = prefs.getInt(_kAyahKey) ?? 0;
        _dhikrCount = prefs.getInt(_kDhikrKey) ?? 0;
        _quranTimeSec = prefs.getInt(_kQuranTimeKey) ?? 0;
      }
    } catch (_) {}
  }

  Future<void> _saveCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kAyahKey, _ayahCount);
      await prefs.setInt(_kDhikrKey, _dhikrCount);
      await prefs.setInt(_kQuranTimeKey, _quranTimeSec);
      await prefs.setString(_kDateKey, _todayStr());
    } catch (_) {}
  }

  Future<void> _maybeSyncDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kDateKey) ?? '';
      if (saved != _todayStr()) await _loadCounts();
    } catch (_) {}
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
