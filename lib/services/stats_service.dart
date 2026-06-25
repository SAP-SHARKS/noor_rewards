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

  // In-flight flush Future, so screens that read the daily table (e.g. the
  // Impact Report) can await any pending exit flush before fetching.
  Future<void>? _pendingFlush;

  /// Returns the in-flight screen-time flush (if any), or a completed Future
  /// when nothing is pending. Callers should `await` this before reading
  /// per-day worship-time stats to avoid a race where the read happens
  /// before the previous screen's flush has committed.
  Future<void> awaitPendingFlush() async {
    final f = _pendingFlush;
    if (f != null) {
      try {
        await f;
      } catch (_) {}
    }
  }

  // ── In-memory caches for instant Akhirah-tab reflection ─────────────────
  // Each recordDhikr*/recordQuran* call bumps these synchronously, so the
  // Akhirah holdings reflect the change before the RPC has committed.
  // Caches are keyed by user id; switching users clears them.
  String? _cachedUid;
  final Map<String, int> _phraseCache = {};
  int _cachedLifetimeAyahs = 0;
  int _cachedLifetimeDhikr = 0;
  int _cachedLifetimeDhikrSets = 0;

  /// Increments any time the cached counts change. UI surfaces (e.g. the
  /// Akhirah holdings screen) listen to this so they refresh the moment
  /// a new dhikr is recorded — even while they're mounted offstage in an
  /// IndexedStack.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Bumped synchronously the moment a flush is **queued** (before the RPC
  /// completes) and again when the RPC commits. The Impact Report listens
  /// and re-renders immediately using the optimistic value below, then
  /// fetches fresh server state in the background. This avoids the user
  /// staring at a stale chart while the network round-trip resolves.
  final ValueNotifier<int> chartRefresh = ValueNotifier<int>(0);
  void bumpChartRefresh() {
    chartRefresh.value++;
  }

  /// Seconds that have been flushed locally but the next read of the chart
  /// hasn't yet observed on the server. Added to today's bar so the chart
  /// updates instantly when the user navigates to the Impact Report, even
  /// though the RPC is still in flight. Reset by the Impact Report after
  /// it successfully re-reads from `user_daily_stats`.
  int _optimisticTodaySec = 0;
  int get optimisticTodaySec => _optimisticTodaySec;
  void resetOptimisticToday() {
    _optimisticTodaySec = 0;
  }

  // Read-only snapshots of the cache for UI consumers.
  Map<String, int> get phraseCountsSnapshot => Map.unmodifiable(_phraseCache);
  int get lifetimeAyahsSnapshot => _cachedLifetimeAyahs;
  int get lifetimeDhikrSnapshot => _cachedLifetimeDhikr;
  int get lifetimeDhikrSetsSnapshot => _cachedLifetimeDhikrSets;

  void _ensureCacheFor(String? uid) {
    if (uid == null) return;
    if (_cachedUid != uid) {
      _cachedUid = uid;
      _phraseCache.clear();
      _cachedLifetimeAyahs = 0;
      _cachedLifetimeDhikr = 0;
      _cachedLifetimeDhikrSets = 0;
      revision.value++;
    }
  }

  void _bumpRevision() {
    revision.value++;
  }

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

    // Optimistic bookkeeping — see flushAndContinue for the rationale.
    _optimisticTodaySec += duration;
    chartRefresh.value++;

    final flush = _sb.rpc('record_activity_stats', params: {
      'p_user_id': uid,
      'p_type': _currentScreen!,
      'p_count': 0,
      'p_duration_sec': duration,
    });

    _pendingFlush = Future(() async {
      try {
        await flush;
        chartRefresh.value++;
      } catch (e) {
        debugPrint('StatsService.pauseScreenTimer error: $e');
      }
    });
    return _pendingFlush;
  }

  /// Call when app resumes from background — restart time counting.
  void resumeScreenTimer() {
    if (_currentScreen != null) {
      _screenEnteredAt = DateTime.now();
    }
  }

  /// Flush accumulated screen time without ending the session. The screen
  /// timer resets to `now()` so subsequent time keeps counting. Useful when
  /// the user navigates inside the app (e.g. tab change in an IndexedStack)
  /// where the Quran/Dhikr screen stays mounted but the user is no longer
  /// actively on it.
  Future<void> flushAndContinue() async {
    if (_currentScreen == null || _screenEnteredAt == null) return;
    final duration =
        DateTime.now().difference(_screenEnteredAt!).inSeconds;
    if (duration < 2) return;

    _screenEnteredAt = DateTime.now(); // reset, keep tracking

    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    // Optimistic bookkeeping: pre-add this duration to today's local total
    // and notify listeners synchronously so the chart updates instantly,
    // independent of the in-flight RPC latency.
    _optimisticTodaySec += duration;
    chartRefresh.value++;

    final type = _currentScreen!;
    _pendingFlush = Future(() async {
      try {
        await _sb.rpc('record_activity_stats', params: {
          'p_user_id': uid,
          'p_type': type,
          'p_count': 0,
          'p_duration_sec': duration,
        });
        // Second bump so the Impact Report can fetch fresh server state
        // and reconcile the optimistic counter.
        chartRefresh.value++;
      } catch (e) {
        debugPrint('StatsService.flushAndContinue error: $e');
      }
    });
    return _pendingFlush;
  }

  /// Call in dispose — computes duration and flushes to DB.
  /// The returned Future is also stored in [_pendingFlush] so other screens
  /// can [awaitPendingFlush] before reading per-day stats.
  Future<void> exitScreen() async {
    if (_currentScreen == null || _screenEnteredAt == null) return;

    final duration = DateTime.now().difference(_screenEnteredAt!).inSeconds;
    final type = _currentScreen!;
    _currentScreen = null;
    _screenEnteredAt = null;

    if (duration < 2) return; // ignore negligible time

    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    // Optimistic bookkeeping — see flushAndContinue for the rationale.
    _optimisticTodaySec += duration;
    chartRefresh.value++;

    final flush = _sb.rpc('record_activity_stats', params: {
      'p_user_id': uid,
      'p_type': type,
      'p_count': 0, // time-only flush, no activity count
      'p_duration_sec': duration,
    });

    _pendingFlush = Future(() async {
      try {
        await flush;
        chartRefresh.value++;
      } catch (e) {
        debugPrint('StatsService.exitScreen error: $e');
      }
    });
    return _pendingFlush;
  }

  // ── Activity recording (fire-and-forget) ─────────────────────────────────

  /// Record Quran ayah read. Call alongside earn_quran_points.
  Future<void> recordQuranActivity({int ayahs = 1}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    _ensureCacheFor(uid);
    if (ayahs > 0) {
      _cachedLifetimeAyahs += ayahs;
      _bumpRevision();
    }

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
    _ensureCacheFor(uid);
    if (count > 0) {
      _cachedLifetimeDhikr += count;
      _cachedLifetimeDhikrSets += 1;
      _bumpRevision();
    }

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

  /// Record which phrase the user just recited and how many times.
  /// Powers the Akhirah holdings that depend on specific phrases
  /// (Treasures of Jannah ← La hawla; Slaves Freed ← La ilaha illallahu
  /// wahdahu la sharika lahu; etc.). Safe to call even if the RPC is
  /// not yet deployed — failures are swallowed.
  Future<void> recordDhikrPhrase(String phraseId, {int count = 1}) async {
    if (phraseId.isEmpty || count <= 0) return;
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    _ensureCacheFor(uid);
    // Optimistic local bump — Akhirah tab sees this immediately even if the
    // RPC is still in flight.
    _phraseCache[phraseId] = (_phraseCache[phraseId] ?? 0) + count;
    _bumpRevision();

    try {
      await _sb.rpc('record_dhikr_phrase', params: {
        'p_user_id': uid,
        'p_phrase_id': phraseId,
        'p_count': count,
      });
    } catch (e) {
      debugPrint('StatsService.recordDhikrPhrase error: $e');
    }
  }

  /// Load per-phrase lifetime counts for the current user.
  /// Returns the cache merged with the server (taking the max per phrase),
  /// so values from in-flight RPCs aren't lost.
  Future<Map<String, int>> loadPhraseCounts() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return const {};
    _ensureCacheFor(uid);

    try {
      final rows = await _sb.rpc(
        'get_user_phrase_counts',
        params: {'p_user_id': uid},
      ) as List;
      var changed = false;
      for (final row in rows) {
        final m = row as Map<String, dynamic>;
        final id = m['phrase_id'] as String?;
        final serverCount = (m['count'] as num?)?.toInt() ?? 0;
        if (id == null) continue;
        final cached = _phraseCache[id] ?? 0;
        final merged = cached > serverCount ? cached : serverCount;
        if (merged != cached) {
          _phraseCache[id] = merged;
          changed = true;
        }
      }
      if (changed) _bumpRevision();
    } catch (e) {
      debugPrint('StatsService.loadPhraseCounts error: $e');
    }
    return Map.of(_phraseCache);
  }

  /// Lifetime totals (sum of every recorded month) — drives the Akhirah
  /// holding values that depend on aggregate dhikr and ayah counts.
  Future<({int ayahsRead, int dhikrCount, int dhikrSets})>
      loadLifetimeActivity() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return (ayahsRead: 0, dhikrCount: 0, dhikrSets: 0);
    _ensureCacheFor(uid);

    try {
      final rows = await _sb.rpc(
        'get_user_lifetime_activity',
        params: {'p_user_id': uid},
      ) as List;
      if (rows.isNotEmpty) {
        final r = rows.first as Map<String, dynamic>;
        final serverAyahs = (r['total_ayahs_read'] as num?)?.toInt() ?? 0;
        final serverDhikr = (r['total_dhikr'] as num?)?.toInt() ?? 0;
        final serverSets = (r['total_dhikr_sets'] as num?)?.toInt() ?? 0;
        var changed = false;
        // Max-merge so in-flight increments are never lost
        if (serverAyahs > _cachedLifetimeAyahs) {
          _cachedLifetimeAyahs = serverAyahs;
          changed = true;
        }
        if (serverDhikr > _cachedLifetimeDhikr) {
          _cachedLifetimeDhikr = serverDhikr;
          changed = true;
        }
        if (serverSets > _cachedLifetimeDhikrSets) {
          _cachedLifetimeDhikrSets = serverSets;
          changed = true;
        }
        if (changed) _bumpRevision();
      }
    } catch (e) {
      debugPrint('StatsService.loadLifetimeActivity error: $e');
    }
    return (
      ayahsRead: _cachedLifetimeAyahs,
      dhikrCount: _cachedLifetimeDhikr,
      dhikrSets: _cachedLifetimeDhikrSets,
    );
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

  /// Top surahs the community read in the last 7 days.
  /// Backed by the `popular_surahs_7d` view. Returns at most [limit] entries
  /// (each: surah number + read count). Silent fallback to empty list.
  Future<List<({int surah, int count})>> loadPopularSurahs({
    int limit = 3,
  }) async {
    try {
      final rows = await _sb
          .from('popular_surahs_7d')
          .select('surah, read_count')
          .limit(limit);
      return (rows as List).map((r) {
        final m = r as Map<String, dynamic>;
        return (
          surah: (m['surah'] as num).toInt(),
          count: (m['read_count'] as num).toInt(),
        );
      }).toList();
    } catch (e) {
      debugPrint('StatsService.loadPopularSurahs error: $e');
      return const [];
    }
  }
}
