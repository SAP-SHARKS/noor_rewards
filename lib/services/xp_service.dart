// lib/services/xp_service.dart
// Central service for XP, levels, and badges.
// All XP-earning events in the app must call methods here.

import 'package:supabase_flutter/supabase_flutter.dart';

// ── XP Rewards (matches the spec) ─────────────────────────────────────────────
class XpReward {
  static const int ayahRead      = 5;   // per ayah
  static const int juzComplete   = 100; // per juz
  static const int dhikrSet      = 10;  // 33× dhikr complete
  static const int tafsirTenMin  = 15;  // 10 min tafsir
  static const int dailyLogin    = 5;   // once per day
  static const int validateCoins = 20;  // validate & support
}

// ── Level info ─────────────────────────────────────────────────────────────────
class LevelInfo {
  final int level;
  final String title;
  final int xpRequired;
  final int nextXp;
  final String unlocks;
  const LevelInfo({
    required this.level,
    required this.title,
    required this.xpRequired,
    required this.nextXp,
    required this.unlocks,
  });

  // e.g. "Seeker • Level 3"
  String get displayTitle => '$title • Level $level';

  // 0.0 – 1.0 progress to next level
  double progress(int currentXp) {
    if (nextXp <= xpRequired) return 1.0;
    return ((currentXp - xpRequired) / (nextXp - xpRequired)).clamp(0.0, 1.0);
  }

  int xpToNextLevel(int currentXp) => (nextXp - currentXp).clamp(0, nextXp);
}

// ── Badge model ────────────────────────────────────────────────────────────────
class BadgeInfo {
  final String id, name, description, emoji;
  final int xpReward;
  final bool earned;
  const BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.earned,
  });
}

// ── XP Service ─────────────────────────────────────────────────────────────────
class XpService {
  XpService._();
  static final XpService instance = XpService._();

  final _sb = Supabase.instance.client;

  // ── Earn XP ──────────────────────────────────────────────────────────────────
  /// Awards [amount] XP to the current user.
  /// Returns new total_xp. Null if not logged in.
  Future<int?> earnXp(int amount) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final result = await _sb.rpc('earn_xp', params: {
        'p_user_id': uid,
        'p_amount': amount,
      });
      return result as int?;
    } catch (e) {
      return null;
    }
  }

  // ── Award badge ───────────────────────────────────────────────────────────────
  /// Awards a badge by ID (idempotent — safe to call multiple times).
  /// Returns true if it was newly awarded (first time).
  Future<bool> awardBadge(String badgeId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final result = await _sb.rpc('award_badge', params: {
        'p_user_id': uid,
        'p_badge_id': badgeId,
      });
      return result as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Daily login XP ────────────────────────────────────────────────────────────
  /// Call once when the app launches / user visits the home screen.
  /// Checks if XP was already awarded today before calling earn_xp.
  Future<bool> claimDailyLoginXp() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      // Check last activity of type 'login' today
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await _sb
          .from('user_activities')
          .select('id')
          .eq('user_id', uid)
          .eq('activity_type', 'login')
          .gte('created_at', today)
          .limit(1);

      if ((rows as List).isNotEmpty) return false; // already claimed today

      // Insert activity record
      await _sb.from('user_activities').insert({
        'user_id': uid,
        'activity_type': 'login',
        'points_earned': XpReward.dailyLogin,
      });

      // Award XP
      await earnXp(XpReward.dailyLogin);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Validate & Support XP ─────────────────────────────────────────────────
  /// Awards XP when the user completes the swipe-to-validate gesture.
  /// Limited to once per day — safe to call on every swipe completion.
  /// Returns true if XP was newly awarded, false if already claimed today.
  Future<bool> claimValidateXp() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final existing = await _sb
          .from('user_activities')
          .select('id')
          .eq('user_id', uid)
          .eq('activity_type', 'validate')
          .gte('created_at', today)
          .limit(1);

      if ((existing as List).isNotEmpty) return false; // already validated today

      await _sb.from('user_activities').insert({
        'user_id': uid,
        'activity_type': 'validate',
        'points_earned': XpReward.validateCoins,
      });

      await earnXp(XpReward.validateCoins);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Load current user profile XP + level ─────────────────────────────────────
  Future<({int xp, int level, int streak})> loadProfile() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return (xp: 0, level: 1, streak: 0);
    try {
      final row = await _sb
          .from('profiles')
          .select('total_xp, level, day_streak')
          .eq('id', uid)
          .single();
      return (
        xp:     (row['total_xp']  as num?)?.toInt() ?? 0,
        level:  (row['level']     as num?)?.toInt() ?? 1,
        streak: (row['day_streak'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return (xp: 0, level: 1, streak: 0);
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

  // ── Resolve LevelInfo for a given xp + level ─────────────────────────────────
  LevelInfo resolveLevelInfo(
    int currentXp,
    int currentLevel,
    List<Map<String, dynamic>> levels,
  ) {
    if (levels.isEmpty) {
      return const LevelInfo(
          level: 1, title: 'Seeker', xpRequired: 0, nextXp: 100, unlocks: '');
    }

    final sorted = [...levels]
      ..sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));

    final idx = sorted.indexWhere((l) => (l['level'] as int) == currentLevel);
    final row = idx >= 0 ? sorted[idx] : sorted.first;
    final nextRow = idx >= 0 && idx + 1 < sorted.length ? sorted[idx + 1] : null;

    return LevelInfo(
      level:       (row['level']       as int?) ?? 1,
      title:       (row['title']       as String?) ?? 'Seeker',
      xpRequired:  (row['xp_required'] as int?) ?? 0,
      nextXp:      (nextRow?['xp_required'] as int?) ?? ((row['xp_required'] as int? ?? 0) + 500),
      unlocks:     (row['unlocks']     as String?) ?? '',
    );
  }

  // ── Load badges with earned status ───────────────────────────────────────────
  Future<List<BadgeInfo>> loadBadges() async {
    final uid = _sb.auth.currentUser?.id;
    try {
      final allBadges = await _sb.from('badges').select();
      Set<String> earnedIds = {};

      if (uid != null) {
        final earned = await _sb
            .from('user_badges')
            .select('badge_id')
            .eq('user_id', uid);
        earnedIds = (earned as List)
            .map((e) => e['badge_id'] as String)
            .toSet();
      }

      return (allBadges as List).map((b) => BadgeInfo(
        id:          b['id']          ?? '',
        name:        b['name']        ?? '',
        description: b['description'] ?? '',
        emoji:       b['emoji']       ?? '🏅',
        xpReward:    (b['xp_reward'] as num?)?.toInt() ?? 0,
        earned:      earnedIds.contains(b['id']),
      )).toList();
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

      if (uid == null) return List<Map<String, dynamic>>.from(challenges as List);

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
          'completed':     p?['completed'] as bool? ?? false,
          'claimed':       p?['claimed']   as bool? ?? false,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Global leaderboard ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> loadLeaderboard({String type = 'global'}) async {
    try {
      final rows = await _sb
          .from('leaderboard_global')
          .select()
          .limit(100);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }
}
