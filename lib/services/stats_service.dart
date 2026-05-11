// lib/services/stats_service.dart
//
// Comprehensive stats tracking service.
// - Tracks time spent per feature (Quran vs Dhikr)
// - Records activity counts to user_monthly_stats + global_daily_stats
// - Loads monthly comparisons and community stats

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Data Classes ─────────────────────────────────────────────────────────────

class MonthlyStats {
  final DateTime month;
  final int ayahsRead;
  final int quranSessions;
  final int quranTimeSec;
  final int dhikrSets;
  final int dhikrCount;
  final int dhikrTimeSec;
  final int totalPoints;
  final int loginDays;
  final int activeDays;

  MonthlyStats({
    required this.month,
    this.ayahsRead = 0,
    this.quranSessions = 0,
    this.quranTimeSec = 0,
    this.dhikrSets = 0,
    this.dhikrCount = 0,
    this.dhikrTimeSec = 0,
    this.totalPoints = 0,
    this.loginDays = 0,
    this.activeDays = 0,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> j) => MonthlyStats(
        month: DateTime.parse(j['month'] as String),
        ayahsRead: (j['ayahs_read'] as num?)?.toInt() ?? 0,
        quranSessions: (j['quran_sessions'] as num?)?.toInt() ?? 0,
        quranTimeSec: (j['quran_time_sec'] as num?)?.toInt() ?? 0,
        dhikrSets: (j['dhikr_sets'] as num?)?.toInt() ?? 0,
        dhikrCount: (j['dhikr_count'] as num?)?.toInt() ?? 0,
        dhikrTimeSec: (j['dhikr_time_sec'] as num?)?.toInt() ?? 0,
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        loginDays: (j['login_days'] as num?)?.toInt() ?? 0,
        activeDays: (j['active_days'] as num?)?.toInt() ?? 0,
      );

  int get totalTimeSec => quranTimeSec + dhikrTimeSec;
  String get quranTimeFormatted => formatDuration(quranTimeSec);
  String get dhikrTimeFormatted => formatDuration(dhikrTimeSec);
  String get totalTimeFormatted => formatDuration(totalTimeSec);

  static String formatDuration(int sec) {
    if (sec < 60) return '${sec}s';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class GlobalStats {
  final int todayReaders;
  final int todayDhikrUsers;
  final int todayAyahs;
  final int todayTotalDhikr;
  final int todayActive;
  final int monthTotalAyahs;
  final int monthTotalDhikr;

  const GlobalStats({
    this.todayReaders = 0,
    this.todayDhikrUsers = 0,
    this.todayAyahs = 0,
    this.todayTotalDhikr = 0,
    this.todayActive = 0,
    this.monthTotalAyahs = 0,
    this.monthTotalDhikr = 0,
  });

  factory GlobalStats.fromRow(Map<String, dynamic> j) => GlobalStats(
        todayReaders: (j['today_readers'] as num?)?.toInt() ?? 0,
        todayDhikrUsers: (j['today_dhikr_users'] as num?)?.toInt() ?? 0,
        todayAyahs: (j['today_ayahs'] as num?)?.toInt() ?? 0,
        todayTotalDhikr: (j['today_total_dhikr'] as num?)?.toInt() ?? 0,
        todayActive: (j['today_active'] as num?)?.toInt() ?? 0,
        monthTotalAyahs: (j['month_total_ayahs'] as num?)?.toInt() ?? 0,
        monthTotalDhikr: (j['month_total_dhikr'] as num?)?.toInt() ?? 0,
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  SupabaseClient get _sb => Supabase.instance.client;

  // ── Screen time tracking ─────────────────────────────────────────────────
  DateTime? _screenEnteredAt;
  String? _currentScreen; // 'quran' | 'dhikr'
  bool _globalActiveRecordedThisSession = false;

  /// Call in initState of Quran reader or Dhikr detail screen.
  void enterScreen(String screenType) {
    // Flush any previous unfinished screen time
    if (_currentScreen != null) {
      exitScreen();
    }
    _currentScreen = screenType;
    _screenEnteredAt = DateTime.now();
  }

  /// Call when app goes to background — flush accumulated time, pause tracking.
  Future<void> pauseScreenTimer() async {
    if (_currentScreen == null || _screenEnteredAt == null) return;
    final duration = DateTime.now().difference(_screenEnteredAt!).inSeconds;
    _screenEnteredAt = null; // pause

    if (duration < 2) return;
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _sb.rpc('record_activity_stats', params: {
        'p_user_id': uid,
        'p_type': _currentScreen!,
        'p_count': 0,
        'p_duration_sec': duration,
      });
    } catch (e) {
      debugPrint('StatsService.pauseScreenTimer error: $e');
    }
  }

  /// Call when app resumes from background — restart time counting.
  void resumeScreenTimer() {
    if (_currentScreen != null) {
      _screenEnteredAt = DateTime.now();
    }
  }

  /// Call in dispose — computes duration and flushes to DB.
  Future<void> exitScreen() async {
    if (_currentScreen == null || _screenEnteredAt == null) return;

    final duration = DateTime.now().difference(_screenEnteredAt!).inSeconds;
    final type = _currentScreen!;
    _currentScreen = null;
    _screenEnteredAt = null;

    if (duration < 2) return; // ignore negligible time

    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _sb.rpc('record_activity_stats', params: {
        'p_user_id': uid,
        'p_type': type,
        'p_count': 0, // time-only flush, no activity count
        'p_duration_sec': duration,
      });
    } catch (e) {
      debugPrint('StatsService.exitScreen error: $e');
    }
  }

  // ── Activity recording (fire-and-forget) ─────────────────────────────────

  /// Record Quran ayah read. Call alongside earn_quran_points.
  Future<void> recordQuranActivity({int ayahs = 1}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _sb.rpc('record_activity_stats', params: {
        'p_user_id': uid,
        'p_type': 'quran',
        'p_count': ayahs,
        'p_duration_sec': 0, // time tracked separately via enterScreen/exitScreen
      });
    } catch (e) {
      debugPrint('StatsService.recordQuranActivity error: $e');
    }
  }

  /// Record dhikr set completion. Call alongside earn_dhikr_points.
  Future<void> recordDhikrActivity({int count = 1}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _sb.rpc('record_activity_stats', params: {
        'p_user_id': uid,
        'p_type': 'dhikr',
        'p_count': count,
        'p_duration_sec': 0,
      });
    } catch (e) {
      debugPrint('StatsService.recordDhikrActivity error: $e');
    }
  }

  /// Record daily active user. Call once per app session from dashboard.
  Future<void> recordDailyActive() async {
    if (_globalActiveRecordedThisSession) return;
    _globalActiveRecordedThisSession = true;

    try {
      await _sb.rpc('increment_global_active', params: {'p_type': 'login'});
    } catch (e) {
      debugPrint('StatsService.recordDailyActive error: $e');
    }
  }

  /// Record that user started a Quran or Dhikr session (global counter).
  Future<void> recordGlobalFeatureActive(String type) async {
    try {
      await _sb.rpc('increment_global_active', params: {'p_type': type});
    } catch (e) {
      debugPrint('StatsService.recordGlobalFeatureActive error: $e');
    }
  }

  // ── Stats loading ────────────────────────────────────────────────────────

  /// Load current + previous month stats for comparison.
  Future<({MonthlyStats current, MonthlyStats? previous})> loadComparison() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      return (
        current: MonthlyStats(month: DateTime.now()),
        previous: null,
      );
    }

    try {
      final rows = await _sb.rpc(
        'get_user_monthly_stats',
        params: {'p_user_id': uid},
      ) as List;

      MonthlyStats? current;
      MonthlyStats? previous;
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      for (final row in rows) {
        final stats = MonthlyStats.fromJson(row as Map<String, dynamic>);
        if (stats.month.year == thisMonth.year &&
            stats.month.month == thisMonth.month) {
          current = stats;
        } else {
          previous = stats;
        }
      }

      return (
        current: current ?? MonthlyStats(month: thisMonth),
        previous: previous,
      );
    } catch (e) {
      debugPrint('StatsService.loadComparison error: $e');
      return (
        current: MonthlyStats(month: DateTime.now()),
        previous: null,
      );
    }
  }

  /// Load today's community stats.
  Future<GlobalStats> loadGlobalStats() async {
    try {
      final rows = await _sb.rpc('get_global_stats') as List;
      if (rows.isNotEmpty) {
        return GlobalStats.fromRow(rows.first as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('StatsService.loadGlobalStats error: $e');
    }
    return const GlobalStats();
  }
}
