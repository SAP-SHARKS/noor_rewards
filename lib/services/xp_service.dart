// lib/services/xp_service.dart
// Central service for points, levels, and badges.
// All point-earning events in the app must call methods here.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_service.dart';
import 'notification_center.dart';
import 'locale_service.dart';

// ── Point Rewards (unified — coins ARE the points) ────────────────────────────
class PointReward {
  static int get ayahRead => SettingsService.instance.config.coinsPerAyah;
  static const int juzComplete = 100;
  static int get dailyLogin => SettingsService.instance.config.pointsDailyLogin;
  static int get validate => SettingsService.instance.config.pointsValidate;
  static int get dhikr => SettingsService.instance.config.coinsPerDhikr;
}

// ── Level info ─────────────────────────────────────────────────────────────────
class LevelInfo {
  final int level;
  final String title;
  final int ptsRequired;
  final int nextPts;
  final String unlocks;
  const LevelInfo({
    required this.level,
    required this.title,
    required this.ptsRequired,
    required this.nextPts,
    required this.unlocks,
  });

  String get displayTitle =>
      LocaleService.instance.l?.xpService_level_226f81(title, level.toString()) ??
          '$title • Level $level';

  double progress(int currentPts) {
    if (nextPts <= ptsRequired) return 1.0;
    return ((currentPts - ptsRequired) / (nextPts - ptsRequired)).clamp(
      0.0,
      1.0,
    );
  }

  int ptsToNextLevel(int currentPts) =>
      (nextPts - currentPts).clamp(0, nextPts);
}

// ── Badge model ────────────────────────────────────────────────────────────────
class BadgeInfo {
  final String id, name, description, emoji;
  final int ptsReward;
  final bool earned;
  const BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.ptsReward,
    required this.earned,
  });
}

// ── Strict level thresholds (in-app fallback — mirrors DB xp_levels table) ────
// These kick in when the DB is unreachable.
const _kFallbackLevels = <(int level, int ptsRequired, String title)>[
  (1, 0, 'Seeker'),
  (2, 150, 'Seeker'),
  (3, 400, 'Seeker'),
  (4, 800, 'Believer'),
  (5, 1400, 'Believer'),
  (6, 2200, 'Believer'),
  (7, 3200, 'Devoted'),
  (8, 4500, 'Devoted'),
  (9, 6000, 'Devoted'),
  (10, 8000, 'Devoted'),
  (11, 10500, 'Champion'),
  (15, 20000, 'Champion'),
  (20, 40000, 'Champion'),
  (21, 55000, 'Legend'),
  (30, 100000, 'Legend'),
  (51, 250000, 'Legend'),
];

// ── Points Service ─────────────────────────────────────────────────────────────
class XpService {
  XpService._();
  static final XpService instance = XpService._();

  final _sb = Supabase.instance.client;

  // ── Pending points (accumulate locally, flush on Seal the Day) ────────────
  static const _kPendingPts = 'pending_points';
  static const _kPendingDate = 'pending_date';

  int _pendingPoints = 0;

  /// Current pending (unvalidated) points for today.
  int get pendingPoints => _pendingPoints;

  /// Load pending points from SharedPreferences. Call once on app start.
  Future<void> loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_kPendingDate) ?? '';
    if (savedDate != _todayStr()) {
      // New day — any unvalidated points from yesterday are lost
      _pendingPoints = 0;
      await prefs.setInt(_kPendingPts, 0);
      await prefs.setString(_kPendingDate, _todayStr());
    } else {
      _pendingPoints = prefs.getInt(_kPendingPts) ?? 0;
    }
  }

  Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPendingPts, _pendingPoints);
    await prefs.setString(_kPendingDate, _todayStr());
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ── Earn Points ──────────────────────────────────────────────────────────────
  /// Accumulates [amount] points (with challenge multiplier) as pending.
  /// Points are NOT committed to the server until the user seals the day.
  Future<int?> earnPoints(int amount) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final multiplier = await _getActiveMultiplier(uid);
      final effective = (amount * multiplier).round();

      // Accumulate locally — do NOT call earn_xp yet
      _pendingPoints += effective;
      await _savePending();

      return _pendingPoints;
    } catch (e) {
      return null;
    }
  }

  /// Flush all pending points to the server via earn_xp RPC.
  /// Called only by claimValidate() when user seals the day.
  Future<int?> _flushPendingToServer() async {
    if (_pendingPoints <= 0) return null;
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;

    final toFlush = _pendingPoints;
    try {
      final result = await _sb.rpc(
        'earn_xp',
        params: {'p_user_id': uid, 'p_amount': toFlush},
      );
      final newPts = result as int?;

      // Reset pending
      _pendingPoints = 0;
      await _savePending();

      if (newPts != null) {
        _checkMilestoneBadges(uid, newPts);
      }
      return newPts;
    } catch (e) {
      debugPrint('XpService._flushPendingToServer error: $e');
      return null;
    }
  }

  // ── Active challenge multiplier ──────────────────────────────────────────────
  /// Returns the highest active points multiplier for the user, or 1.0 if none.
  Future<double> _getActiveMultiplier(String uid) async {
    try {
      final progress = await _sb
          .from('user_challenge_progress')
          .select('challenge_id, completed')
          .eq('user_id', uid)
          .eq('completed', false);

      if ((progress as List).isEmpty) return 1.0;

      final challengeIds =
          progress.map((p) => p['challenge_id'] as String).toList();

      final challenges = await _sb
          .from('challenges')
          .select('xp_multiplier')
          .inFilter('id', challengeIds)
          .eq('is_active', true);

      if ((challenges as List).isEmpty) return 1.0;

      double best = 1.0;
      for (final c in challenges) {
        final m = (c['xp_multiplier'] as num?)?.toDouble() ?? 1.0;
        if (m > best) best = m;
      }
      return best;
    } catch (_) {
      return 1.0;
    }
  }

  // ── Milestone badge auto-award ────────────────────────────────────────────────
  /// Automatically awards badges when the user crosses point / level milestones.
  /// Fire-and-forget — errors are silently swallowed.
  void _checkMilestoneBadges(String uid, int totalPts) {
    if (totalPts >= 100) awardBadge('first_100xp');
    if (totalPts >= 500) awardBadge('xp_500');
    if (totalPts >= 1000) awardBadge('xp_1000');
    if (totalPts >= 5000) awardBadge('xp_5000');
    if (totalPts >= 10000) awardBadge('xp_10000');
  }

  // ── Award badge ───────────────────────────────────────────────────────────────
  /// Awards a badge by ID (idempotent — safe to call multiple times).
  /// Returns true if it was newly awarded (first time).
  Future<bool> awardBadge(String badgeId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final result = await _sb.rpc(
        'award_badge',
        params: {'p_user_id': uid, 'p_badge_id': badgeId},
      );
      final isNew = result as bool? ?? false;
      if (isNew) {
        // ── In-app notification: new badge unlocked. Tap goes to Journey
        // tab where the user can see all their badges.
        final l = LocaleService.instance.l;
        final humanized = _humanize(badgeId);
        NotificationCenter.instance.add(
          kind: NoorNotifKind.badge,
          title: l?.xpService_newBadgeUnlocked_2c8d0e ??
              'New badge unlocked 🏆',
          body: l?.xpService_badgeEarnedBody(humanized) ??
              'You\'ve earned the "$humanized" badge.',
          route: '/journey',
          data: {'badge_id': badgeId},
        );
      }
      return isNew;
    } catch (_) {
      return false;
    }
  }

  /// Convert a badge id like "first_100xp" → "First 100 Pts".
  String _humanize(String id) {
    final words =
        id.split('_').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).toList();
    return words.join(' ');
  }

  // ── Daily login points ────────────────────────────────────────────────────────
  Future<bool> claimDailyLogin() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await _sb
          .from('user_activities')
          .select('id')
          .eq('user_id', uid)
          .eq('activity_type', 'login')
          .gte('created_at', today)
          .limit(1);

      if ((rows as List).isNotEmpty) return false;

      await _sb.from('user_activities').insert({
        'user_id': uid,
        'activity_type': 'login',
        'points_earned': PointReward.dailyLogin,
      });

      await earnPoints(PointReward.dailyLogin);
      // ── In-app notification: daily-login reward earned
      final l = LocaleService.instance.l;
      NotificationCenter.instance.add(
        kind: NoorNotifKind.reward,
        title: l?.xpService_dailyLoginBonus_d011fa ?? 'Daily login bonus',
        body: l?.xpService_seedsWelcomeBack_47888a(
              PointReward.dailyLogin.toString(),
            ) ??
            '+${PointReward.dailyLogin} Seeds · welcome back!',
        route: '/journey',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the most recent [claimValidate] awarded the once-daily seal
  /// bonus. False on a repeat seal that only flushed newly-earned pending
  /// Seeds. The "Coins Sealed!" popup reads this so it advertises the
  /// +bonus only on the first seal of the day.
  bool lastSealAwardedBonus = false;

  // ── Seal the Day (flush pending Seeds) ───────────────────────────────────
  // The user can seal multiple times a day so newly-earned Seeds can always
  // be flushed when they tap. The validate *bonus* is only awarded on the
  // first seal of the day (one daily ritual reward, not an exploit).
  Future<bool> claimValidate() async {
    // Nothing pending → nothing to seal. Skip the RPC and return false so
    // the swipe button can show its boost / "earn more" hint instead.
    if (_pendingPoints <= 0) return false;

    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      // First seal of the *local* day. created_at is stored in UTC, so we
      // must compare against local midnight converted to UTC. Comparing
      // against a bare local date string (e.g. "2026-05-16") makes
      // Postgres treat it as UTC midnight — which, for users not on UTC,
      // lets an early-hours seal slip past the check and re-award the
      // daily bonus on a later seal.
      final now = DateTime.now();
      final localDayStartUtc =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final existing = await _sb
          .from('user_activities')
          .select('id')
          .eq('user_id', uid)
          .eq('activity_type', 'validate')
          .gte('created_at', localDayStartUtc)
          .limit(1);
      final firstSealToday = (existing as List).isEmpty;
      lastSealAwardedBonus = firstSealToday;
      final bonus = PointReward.validate;

      // Only stack the daily bonus on the first seal of the day.
      if (firstSealToday) {
        _pendingPoints += bonus;
      }

      // Flush everything pending (this resets _pendingPoints to 0 inside
      // _flushPendingToServer on success).
      final flushed = _pendingPoints;
      await _flushPendingToServer();

      // Record one validate activity per day so the bonus can't repeat.
      if (firstSealToday) {
        await _sb.from('user_activities').insert({
          'user_id': uid,
          'activity_type': 'validate',
          'points_earned': flushed,
        });
      }

      final l = LocaleService.instance.l;
      NotificationCenter.instance.add(
        kind: NoorNotifKind.validation,
        title: l?.xpService_daySealed_037a56 ?? 'Day sealed 🌙',
        body: firstSealToday
            ? (l?.xpService_sabiqSeedsConfirmedBonus_702902(
                    flushed.toString(),
                    bonus.toString(),
                  ) ??
                '+$flushed Sabiq Seeds confirmed! ($bonus bonus for sealing)')
            : (l?.xpService_sabiqSeedsConfirmed_34969c(flushed.toString()) ??
                '+$flushed Sabiq Seeds confirmed!'),
        route: '/home',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Daily Dhikr Goal points ──────────────────────────────────────────────────
  Future<bool> claimDailyDhikrGoal() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Guard: only once per day
      final existing = await _sb
          .from('user_activities')
          .select('id')
          .eq('user_id', uid)
          .eq('activity_type', 'dhikr')
          .gte('created_at', today)
          .limit(1);

      if ((existing as List).isNotEmpty) return false;

      await _sb.from('user_activities').insert({
        'user_id': uid,
        'activity_type': 'dhikr', // 'dhikr' is within the DB check constraint
        'points_earned': 50,
      });

      await earnPoints(50);
      return true;
    } catch (_) {
      // Silently fail — never crash the UI over a reward insert
      return false;
    }
  }

  // ── Load current user profile ─────────────────────────────────────────────────
  Future<({int pts, int level, int streak})> loadProfile() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return (pts: 0, level: 1, streak: 0);
    try {
      final row =
          await _sb
              .from('profiles')
              .select('total_xp, level, day_streak')
              .eq('id', uid)
              .single();
      return (
        pts: (row['total_xp'] as num?)?.toInt() ?? 0,
        level: (row['level'] as num?)?.toInt() ?? 1,
        streak: (row['day_streak'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return (pts: 0, level: 1, streak: 0);
    }
  }

  // ── Load all levels ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> loadLevels() async {
    try {
      final rows = await _sb.from('xp_levels').select().order('level');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  // ── Resolve LevelInfo (DB-first, strict fallback curve) ──────────────────────
  LevelInfo resolveLevelInfo(
    int currentXp,
    int currentLevel,
    List<Map<String, dynamic>> levels,
  ) {
    if (levels.isEmpty) {
      // Use strict in-app fallback curve
      return _levelInfoFromFallback(currentLevel);
    }

    final sorted = [...levels]
      ..sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));

    final idx = sorted.indexWhere((l) => (l['level'] as int) == currentLevel);
    final row = idx >= 0 ? sorted[idx] : sorted.first;
    final nextRow =
        idx >= 0 && idx + 1 < sorted.length ? sorted[idx + 1] : null;

    // If DB next level exists, use it; otherwise use strict fallback gap
    final nextPts =
        (nextRow?['xp_required'] as int?) ??
        _nextPtsFromFallback((row['level'] as int? ?? 1));

    return LevelInfo(
      level: (row['level'] as int?) ?? 1,
      title: (row['title'] as String?) ?? 'Seeker',
      ptsRequired: (row['xp_required'] as int?) ?? 0,
      nextPts: nextPts,
      unlocks: (row['unlocks'] as String?) ?? '',
    );
  }

  /// Returns the next-level xp_required from the fallback table.
  int _nextPtsFromFallback(int currentLevel) {
    for (int i = 0; i < _kFallbackLevels.length - 1; i++) {
      if (_kFallbackLevels[i].$1 == currentLevel) {
        return _kFallbackLevels[i + 1].$2;
      }
    }
    // Beyond the last defined level — use a steep curve
    final last = _kFallbackLevels.last;
    final gap = currentLevel - last.$1;
    return last.$2 + gap * 15000;
  }

  /// Builds a full LevelInfo from the strict fallback table.
  LevelInfo _levelInfoFromFallback(int level) {
    // Find the closest entry at or below requested level
    var entry = _kFallbackLevels.first;
    for (final e in _kFallbackLevels) {
      if (e.$1 <= level) entry = e;
    }
    return LevelInfo(
      level: entry.$1,
      title: entry.$3,
      ptsRequired: entry.$2,
      nextPts: _nextPtsFromFallback(entry.$1),
      unlocks: '',
    );
  }

  // ── Load badges with earned status ───────────────────────────────────────────
  Future<List<BadgeInfo>> loadBadges() async {
    final uid = _sb.auth.currentUser?.id;
    try {
      // Fire the catalog query and the user's earned list in parallel.
      // Was 2 sequential round-trips (badges → user_badges); now 1.
      final batch = await Future.wait<List<dynamic>>([
        _sb
            .from('badges')
            .select()
            .then<List<dynamic>>((v) => v as List)
            .catchError((_) => const <dynamic>[]),
        uid == null
            ? Future.value(const <dynamic>[])
            : _sb
                .from('user_badges')
                .select('badge_id')
                .eq('user_id', uid)
                .then<List<dynamic>>((v) => v as List)
                .catchError((_) => const <dynamic>[]),
      ]);
      final allBadges = batch[0];
      final Set<String> earnedIds =
          batch[1].map((e) => e['badge_id'] as String).toSet();

      return allBadges
          .map(
            (b) => BadgeInfo(
              id: b['id'] ?? '',
              name: b['name'] ?? '',
              description: b['description'] ?? '',
              emoji: b['emoji'] ?? '🏅',
              ptsReward: (b['xp_reward'] as num?)?.toInt() ?? 0,
              earned: earnedIds.contains(b['id']),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Load active challenges with user progress ─────────────────────────────────
  Future<List<Map<String, dynamic>>> loadChallenges() async {
    final uid = _sb.auth.currentUser?.id;
    try {
      final challenges = await _sb
          .from('challenges')
          .select()
          .eq('is_active', true)
          .order('end_date');

      if (uid == null) {
        return List<Map<String, dynamic>>.from(challenges as List);
      }

      final progress = await _sb
          .from('user_challenge_progress')
          .select()
          .eq('user_id', uid);

      final progressMap = Map.fromEntries(
        (progress as List).map((p) => MapEntry(p['challenge_id'] as String, p)),
      );

      return (challenges as List).map<Map<String, dynamic>>((c) {
        final p = progressMap[c['id'] as String];
        return {
          ...Map<String, dynamic>.from(c),
          'user_progress': (p?['progress'] as num?)?.toInt() ?? 0,
          'completed': p?['completed'] as bool? ?? false,
          'claimed': p?['claimed'] as bool? ?? false,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Global leaderboard ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> loadLeaderboard({
    String type = 'global',
  }) async {
    try {
      // leaderboard_global_v2 = filtered view that excludes merged
      // duplicate profiles (see 20260526_020_profile_dedup_by_email.sql).
      // The old `leaderboard_global` view doesn't filter, which is why
      // multiple "zaid" / "Yaseen" rows for the same email showed up.
      final rows = await _sb
          .from('leaderboard_global_v2')
          .select()
          .limit(100);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }
}
