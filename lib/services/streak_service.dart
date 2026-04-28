// lib/services/streak_service.dart
// Three-type streak system: login · dhikr · quran
// Integrates with the record_streak_activity() Supabase function.

import 'package:supabase_flutter/supabase_flutter.dart';

// ── Streak type enum ──────────────────────────────────────────────────────────
enum StreakType { login, dhikr, quran }

extension StreakTypeX on StreakType {
  String get key => name; // 'login' | 'dhikr' | 'quran'
  String get label {
    switch (this) {
      case StreakType.login:  return 'Daily Login';
      case StreakType.dhikr: return 'Zikr';
      case StreakType.quran: return 'Quran';
    }
  }
  String get emoji {
    switch (this) {
      case StreakType.login:  return '☀️';
      case StreakType.dhikr: return '📿';
      case StreakType.quran: return '📖';
    }
  }
}

// ── Full streak snapshot for a user ──────────────────────────────────────────
class StreakSnapshot {
  final int login, dhikr, quran;
  final int bestLogin, bestDhikr, bestQuran;
  final List<DateTime> loginHistory;  // dates active in last 7 days
  final List<DateTime> dhikrHistory;
  final List<DateTime> quranHistory;

  const StreakSnapshot({
    required this.login,  required this.dhikr,  required this.quran,
    required this.bestLogin, required this.bestDhikr, required this.bestQuran,
    required this.loginHistory,
    required this.dhikrHistory,
    required this.quranHistory,
  });

  int get combined => login + dhikr + quran;
  int streakFor(StreakType t) {
    switch (t) {
      case StreakType.login:  return login;
      case StreakType.dhikr: return dhikr;
      case StreakType.quran: return quran;
    }
  }
  int bestFor(StreakType t) {
    switch (t) {
      case StreakType.login:  return bestLogin;
      case StreakType.dhikr: return bestDhikr;
      case StreakType.quran: return bestQuran;
    }
  }
  List<DateTime> historyFor(StreakType t) {
    switch (t) {
      case StreakType.login:  return loginHistory;
      case StreakType.dhikr: return dhikrHistory;
      case StreakType.quran: return quranHistory;
    }
  }

  static const empty = StreakSnapshot(
    login: 0, dhikr: 0, quran: 0,
    bestLogin: 0, bestDhikr: 0, bestQuran: 0,
    loginHistory: [], dhikrHistory: [], quranHistory: [],
  );
}

// ── Milestone definition ──────────────────────────────────────────────────────
class StreakMilestone {
  final int days;
  final String label;
  final String emoji;
  final int ptsBonus;
  const StreakMilestone({
    required this.days, required this.label,
    required this.emoji, required this.ptsBonus,
  });
}

const kStreakMilestones = <StreakMilestone>[
  StreakMilestone(days: 3,   label: 'Warming Up',    emoji: '🌱', ptsBonus: 15),
  StreakMilestone(days: 7,   label: 'One Week',       emoji: '🔥', ptsBonus: 30),
  StreakMilestone(days: 14,  label: 'Two Weeks',      emoji: '⚡', ptsBonus: 60),
  StreakMilestone(days: 30,  label: 'One Month',      emoji: '🌟', ptsBonus: 100),
  StreakMilestone(days: 60,  label: 'Two Months',     emoji: '💎', ptsBonus: 200),
  StreakMilestone(days: 100, label: 'The Centurion',  emoji: '👑', ptsBonus: 400),
];

/// Returns the next milestone the user hasn't passed yet.
StreakMilestone? nextMilestone(int streak) {
  for (final m in kStreakMilestones) {
    if (streak < m.days) return m;
  }
  return null;
}

/// Returns the last milestone the user has passed.
StreakMilestone? lastMilestone(int streak) {
  StreakMilestone? last;
  for (final m in kStreakMilestones) {
    if (streak >= m.days) last = m;
  }
  return last;
}

// ── Streak Service ────────────────────────────────────────────────────────────
class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  final _sb = Supabase.instance.client;

  // ── Record activity (idempotent — safe to call multiple times per day) ──────
  /// Returns the new streak count, or 0 on error.
  Future<int> recordActivity(StreakType type) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final result = await _sb.rpc('record_streak_activity', params: {
        'p_user_id': uid,
        'p_type':    type.key,
      });
      return (result as num?)?.toInt() ?? 0;
    } catch (e) {
      // Fallback: update profile directly if RPC not yet deployed
      return _localFallback(uid, type);
    }
  }

  // Lightweight local fallback when the RPC isn't deployed yet
  Future<int> _localFallback(String uid, StreakType type) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final col   = '${type.key}_streak';
      final datCol = '${type.key}_streak_updated_at';
      final row = await _sb.from('profiles')
          .select('$col, $datCol')
          .eq('id', uid)
          .single();

      final current = (row[col] as num?)?.toInt() ?? 0;
      final lastStr = row[datCol] as String?;

      int newStreak;
      if (lastStr == null) {
        newStreak = 1;
      } else {
        final last = DateTime.parse(lastStr);
        final todayDt = DateTime.parse(today);
        final diff = todayDt.difference(last).inDays;
        if (diff == 0) { return current; }      // already done today
        if (diff == 1) { newStreak = current + 1; }
        else           { newStreak = 1; }         // missed a day
      }

      await _sb.from('profiles').update({
        col:    newStreak,
        datCol: today,
      }).eq('id', uid);
      return newStreak;
    } catch (_) {
      return 0;
    }
  }

  // ── Load full snapshot ────────────────────────────────────────────────────
  Future<StreakSnapshot> loadSnapshot() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return StreakSnapshot.empty;
    try {
      final profile = await _sb.from('profiles')
          .select(
            'login_streak, dhikr_streak, quran_streak,'
            'best_login_streak, best_dhikr_streak, best_quran_streak')
          .eq('id', uid)
          .single();

      // History for each type (last 7 days)
      final histories = await Future.wait(
        StreakType.values.map((t) => _loadHistory(uid, t, 7)),
      );

      return StreakSnapshot(
        login:  (profile['login_streak']  as num?)?.toInt() ?? 0,
        dhikr:  (profile['dhikr_streak']  as num?)?.toInt() ?? 0,
        quran:  (profile['quran_streak']  as num?)?.toInt() ?? 0,
        bestLogin:  (profile['best_login_streak']  as num?)?.toInt() ?? 0,
        bestDhikr:  (profile['best_dhikr_streak']  as num?)?.toInt() ?? 0,
        bestQuran:  (profile['best_quran_streak']  as num?)?.toInt() ?? 0,
        loginHistory: histories[0],
        dhikrHistory: histories[1],
        quranHistory: histories[2],
      );
    } catch (_) {
      return StreakSnapshot.empty;
    }
  }

  Future<List<DateTime>> _loadHistory(String uid, StreakType t, int days) async {
    try {
      // Try the RPC first
      final rows = await _sb.rpc('get_streak_history', params: {
        'p_user_id': uid,
        'p_type':    t.key,
        'p_days':    days,
      });
      return (rows as List)
          .map((r) => DateTime.parse(r.toString()))
          .toList();
    } catch (_) {
      // Fallback: query streak_history table directly
      try {
        final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
        final rows = await _sb
            .from('streak_history')
            .select('activity_date')
            .eq('user_id', uid)
            .eq('streak_type', t.key)
            .gte('activity_date', cutoff)
            .order('activity_date', ascending: false);
        return (rows as List)
            .map((r) => DateTime.parse(r['activity_date'].toString()))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  // ── Convenience: combined "max" streak for top-bar display ───────────────
  Future<int> topStreak() async {
    final s = await loadSnapshot();
    return [s.login, s.dhikr, s.quran].reduce((a, b) => a > b ? a : b);
  }
}
