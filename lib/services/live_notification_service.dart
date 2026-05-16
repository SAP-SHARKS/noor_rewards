// lib/services/live_notification_service.dart
//
// Persistent "live" notification — like Sweatcoin's step counter.
// Shows today's Quran ayat and Dhikr count in the Android notification shade.
// Stays pinned and updates in real time as the user reads/does dhikr.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoorLiveNotificationService {
  NoorLiveNotificationService._();
  static final NoorLiveNotificationService instance =
      NoorLiveNotificationService._();

  static const int _notifId = 1001; // stable ID — updates same notif
  static const String _channelId = 'noor_live_stats';
  static const String _channelName = 'Live Noor Stats';

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

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    // v21 uses named parameter 'settings'
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
    );

    // Request permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

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

    await _plugin.show(
      id: _notifId,
      title: 'Your Seeds Today ✨',
      body: lines.join('  •  '),
      notificationDetails: NotificationDetails(android: androidDetails),
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
