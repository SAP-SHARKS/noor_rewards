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
  static const String _kDateKey = 'noor_stat_date';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  int _ayahCount = 0;
  int _dhikrCount = 0;

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

    final ayahMsg =
        _ayahCount == 0
            ? 'No ayat read yet today'
            : '$_ayahCount ayat read today 📖';
    final dhikrMsg =
        _dhikrCount == 0
            ? 'No Dhikr yet today'
            : '$_dhikrCount Dhikr completed today 📿';

    final ticker =
        _ayahCount > 0
            ? '$_ayahCount ayat · $_dhikrCount dhikr today'
            : 'Keep reading and doing Dhikr!';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: "Live today's Quran and Dhikr progress",
      importance: Importance.low, // No sound/vibration on update
      priority: Priority.low,
      ongoing: true, // Pinned — can't be swiped away
      autoCancel: false,
      onlyAlertOnce: true, // Silent on repeat updates
      ticker: ticker,
      styleInformation: BigTextStyleInformation(
        '$ayahMsg\n$dhikrMsg',
        contentTitle: 'Your Noor Today ✨',
        summaryText: 'Tap to open Noor Rewards',
      ),
      color: const Color(0xFF6B4EBB),
    );

    // v21: show() uses named params (id, title, body, notificationDetails)
    await _plugin.show(
      id: _notifId,
      title: 'Your Noor Today ✨',
      body: '$ayahMsg  •  $dhikrMsg',
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
        await prefs.setString(_kDateKey, _todayStr());
        await prefs.setInt(_kAyahKey, 0);
        await prefs.setInt(_kDhikrKey, 0);
      } else {
        _ayahCount = prefs.getInt(_kAyahKey) ?? 0;
        _dhikrCount = prefs.getInt(_kDhikrKey) ?? 0;
      }
    } catch (_) {}
  }

  Future<void> _saveCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kAyahKey, _ayahCount);
      await prefs.setInt(_kDhikrKey, _dhikrCount);
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

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
