// lib/screens/level_screen.dart
// Full XP / Levels / Badges / Challenges / History screen

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/xp_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg     = Color(0xFFF7F3EE);
const _kWhite  = Colors.white;
const _kText   = Color(0xFF1C1C1E);
const _kSub    = Color(0xFF8E8E93);
const _kGold   = Color(0xFFF5A623);
const _kPurple = Color(0xFF6B4EBB);
const _kGreen  = Color(0xFF2BAE99);

// ── Level tier colours ────────────────────────────────────────────────────────
Color _tierColor(String title) {
  switch (title) {
    case 'Seeker':   return const Color(0xFF78C1F3);
    case 'Believer': return const Color(0xFF4CAF50);
    case 'Devoted':  return const Color(0xFFAB47BC);
    case 'Champion': return const Color(0xFFF5A623);
    case 'Legend':   return const Color(0xFFE53935);
    default:         return _kSub;
  }
}

String _tierEmoji(String title) {
  switch (title) {
    case 'Seeker':   return '🌱';
    case 'Believer': return '🌟';
    case 'Devoted':  return '💜';
    case 'Champion': return '🏆';
    case 'Legend':   return '👑';
    default:         return '✨';
  }
}

// Activity type → readable label + emoji + colour
({String label, String emoji, Color color}) _activityMeta(String type) {
  switch (type) {
    case 'login':    return (label: 'Daily Login',       emoji: '☀️',  color: const Color(0xFF00897B));
    case 'validate': return (label: 'Validate & Support',emoji: '✅',  color: const Color(0xFF6B4EBB));
    case 'quran':    return (label: 'Read Quran',         emoji: '📖',  color: const Color(0xFF1565C0));
    case 'dhikr':    return (label: 'Count Dhikr',        emoji: '📿',  color: const Color(0xFF558B2F));
    case 'tafsir':   return (label: 'Listen Tafsir',      emoji: '🎧',  color: const Color(0xFFAD1457));
    case 'challenge':return (label: 'Challenge',          emoji: '🏅',  color: const Color(0xFFF5A623));
    default:         return (label: type,                 emoji: '⭐',  color: _kSub);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});
  @override State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _xp = XpService.instance;
  final _sb = Supabase.instance.client;

  // Profile
  int _currentXp    = 0;
  int _currentLevel = 1;
  int _streak       = 0;
  LevelInfo?                  _levelInfo;
  List<Map<String, dynamic>>  _allLevels   = [];
  List<BadgeInfo>             _badges      = [];
  List<Map<String, dynamic>>  _challenges  = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final profile    = await _xp.loadProfile();
    final levels     = await _xp.loadLevels();
    final badges     = await _xp.loadBadges();
    final challenges = await _xp.loadChallenges();

    _currentXp    = profile.xp;
    _currentLevel = profile.level;
    _streak       = profile.streak;
    _allLevels    = levels;
    _badges       = badges;
    _challenges   = challenges;
    _levelInfo    = _xp.resolveLevelInfo(_currentXp, _currentLevel, levels);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kWhite,
        surfaceTintColor: _kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _kText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('XP & Achievements',
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPurple,
          unselectedLabelColor: _kSub,
          indicatorColor: _kPurple,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Progress'),
            Tab(text: 'Badges'),
            Tab(text: 'Challenges'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPurple))
          : TabBarView(
              controller: _tabs,
              children: [
                _ProgressTab(
                  xp:        _currentXp,
                  level:     _currentLevel,
                  streak:    _streak,
                  levelInfo: _levelInfo,
                  allLevels: _allLevels,
                ),
                _BadgesTab(badges: _badges),
                _ChallengesTab(challenges: _challenges, onRefresh: _loadAll),
                _HistoryTab(supabase: _sb),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PROGRESS
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  final int xp, level, streak;
  final LevelInfo? levelInfo;
  final List<Map<String, dynamic>> allLevels;
  const _ProgressTab({
    required this.xp, required this.level, required this.streak,
    required this.levelInfo, required this.allLevels,
  });

  @override
  Widget build(BuildContext context) {
    final info = levelInfo;
    final color = info != null ? _tierColor(info.title) : _kPurple;
    final progress = info?.progress(xp) ?? 0.0;
    final toNext   = info?.xpToNextLevel(xp) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Hero level card ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.04)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(info != null ? _tierEmoji(info.title) : '🌱',
                  style: const TextStyle(fontSize: 48)),
            ]),
            const SizedBox(height: 12),
            Text('Level $level',
                style: GoogleFonts.outfit(
                    fontSize: 42, fontWeight: FontWeight.w900,
                    color: color, height: 1.0)),
            const SizedBox(height: 4),
            Text(info?.title ?? 'Seeker',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v, minHeight: 14,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text('$xp XP',
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              const Spacer(),
              Text('$toNext XP to next level',
                  style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
            ]),
          ]),
        ),

        // ── Stats row ─────────────────────────────────────────────────────
        const SizedBox(height: 20),
        Row(children: [
          _MiniStat('🔥', '$streak', 'Day Streak'),
          const SizedBox(width: 12),
          _MiniStat('⭐', '$xp', 'Total XP'),
          const SizedBox(width: 12),
          _MiniStat('🏅', 'Lv $level', 'Current Level'),
        ]),

        // ── XP Earning guide ───────────────────────────────────────────────
        const SizedBox(height: 28),
        Text('How to Earn XP',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 14),
        _XpRow('📖', 'Read 1 Ayah',          '+${XpReward.ayahRead} XP'),
        _XpRow('📚', 'Complete 1 Juz',        '+${XpReward.juzComplete} XP'),
        _XpRow('📿', 'Complete 33× Dhikr',    '+${XpReward.dhikrSet} XP'),
        _XpRow('🎧', 'Listen 10min Tafsir',   '+${XpReward.tafsirTenMin} XP'),
        _XpRow('☀️',  'Daily Login',            '+${XpReward.dailyLogin} XP'),
        _XpRow('✨', 'Validate & Support',    '+${XpReward.validateCoins} XP'),

        // ── Level tiers ────────────────────────────────────────────────────
        const SizedBox(height: 28),
        Text('Level Tiers',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 14),
        for (final tier in _tierGroups) _TierCard(tier: tier, currentLevel: level),
      ]),
    );
  }

  static const _tierGroups = [
    (title: 'Seeker',   emoji: '🌱', range: '1–5',   xp: '0–500 XP',        color: Color(0xFF78C1F3), unlocks: 'Basic features'),
    (title: 'Believer', emoji: '🌟', range: '6–10',  xp: '500–1,500 XP',    color: Color(0xFF4CAF50), unlocks: 'Custom profile themes'),
    (title: 'Devoted',  emoji: '💜', range: '11–20', xp: '1,500–5,000 XP',  color: Color(0xFFAB47BC), unlocks: 'Leaderboard badge'),
    (title: 'Champion', emoji: '🏆', range: '21–50', xp: '5,000–20,000 XP', color: Color(0xFFF5A623), unlocks: 'Exclusive voting rights'),
    (title: 'Legend',   emoji: '👑', range: '50+',   xp: '20,000+ XP',      color: Color(0xFFE53935), unlocks: 'Hall of Fame listing'),
  ];
}

class _MiniStat extends StatelessWidget {
  final String emoji, value, label;
  const _MiniStat(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: _kSub), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _XpRow extends StatelessWidget {
  final String emoji, label, reward;
  const _XpRow(this.emoji, this.label, this.reward);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _kText))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Text(reward,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _kPurple)),
      ),
    ]),
  );
}

class _TierCard extends StatelessWidget {
  final ({String title, String emoji, String range, String xp, Color color, String unlocks}) tier;
  final int currentLevel;
  const _TierCard({required this.tier, required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final levelNum  = int.tryParse(tier.range.split('–').first.replaceAll('+','')) ?? 1;
    final isActive  = _isInTier(currentLevel, tier.range);
    final isUnlocked = currentLevel >= levelNum;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? tier.color.withValues(alpha: 0.1) : _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? tier.color : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: tier.color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        Text(tier.emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(tier.title,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800,
                    color: isUnlocked ? tier.color : _kSub)),
            const SizedBox(width: 8),
            Text('Lv ${tier.range}',
                style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
          ]),
          const SizedBox(height: 2),
          Text(tier.xp, style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
          const SizedBox(height: 3),
          Text('Unlocks: ${tier.unlocks}',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isUnlocked ? tier.color : _kSub)),
        ])),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: tier.color, borderRadius: BorderRadius.circular(8)),
            child: Text('NOW', style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          )
        else if (!isUnlocked)
          const Icon(Icons.lock_rounded, color: _kSub, size: 20),
      ]),
    );
  }

  bool _isInTier(int level, String range) {
    if (range.endsWith('+')) {
      return level >= int.parse(range.replaceAll('+', ''));
    }
    final parts = range.split('–');
    final lo = int.tryParse(parts[0]) ?? 0;
    final hi = int.tryParse(parts[1]) ?? 0;
    return level >= lo && level <= hi;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — BADGES
// ─────────────────────────────────────────────────────────────────────────────
class _BadgesTab extends StatelessWidget {
  final List<BadgeInfo> badges;
  const _BadgesTab({required this.badges});

  @override
  Widget build(BuildContext context) {
    final earned  = badges.where((b) => b.earned).toList();
    final locked  = badges.where((b) => !b.earned).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kGold.withValues(alpha: 0.15), _kGold.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGold.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Text('🏅', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${earned.length} / ${badges.length} Earned',
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
              Text('Keep going — more badges to unlock!',
                  style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
            ]),
          ]),
        ),

        if (earned.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Earned ✅',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
            children: earned.map((b) => _BadgeCard(b, true)).toList(),
          ),
        ],

        if (locked.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Locked 🔒',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
            children: locked.map((b) => _BadgeCard(b, false)).toList(),
          ),
        ],
      ]),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeInfo badge;
  final bool earned;
  const _BadgeCard(this.badge, this.earned);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: earned ? _kWhite : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: earned ? _kGold.withValues(alpha: 0.4) : Colors.grey.shade200),
      boxShadow: earned
          ? [BoxShadow(color: _kGold.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
          : [],
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Stack(alignment: Alignment.center, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned
                ? _kGold.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.08),
          ),
          child: Center(child: Text(
            earned ? badge.emoji : '🔒',
            style: TextStyle(fontSize: earned ? 28 : 22),
          )),
        ),
      ]),
      const SizedBox(height: 8),
      Text(badge.name,
          style: GoogleFonts.outfit(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: earned ? _kText : _kSub),
          textAlign: TextAlign.center, maxLines: 2),
      const SizedBox(height: 3),
      Text('+${badge.xpReward} XP',
          style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: earned ? _kGold : _kSub)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — CHALLENGES
// ─────────────────────────────────────────────────────────────────────────────
class _ChallengesTab extends StatelessWidget {
  final List<Map<String, dynamic>> challenges;
  final VoidCallback onRefresh;
  const _ChallengesTab({required this.challenges, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final weekly   = challenges.where((c) => c['type'] == 'weekly').toList();
    final seasonal = challenges.where((c) => c['type'] == 'seasonal').toList();
    final special  = challenges.where((c) => c['type'] == 'special').toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: _kPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RamadanBanner(),
          if (seasonal.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader('🕋 Seasonal Events'),
            const SizedBox(height: 12),
            for (final c in seasonal) _ChallengeCard(c),
          ],
          if (weekly.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader('📅 Weekly Challenges'),
            const SizedBox(height: 12),
            for (final c in weekly) _ChallengeCard(c),
          ],
          if (special.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader('⭐ Special Events'),
            const SizedBox(height: 12),
            for (final c in special) _ChallengeCard(c),
          ],
          if (challenges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Text('🌙', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text('No active challenges right now',
                      style: GoogleFonts.outfit(fontSize: 16, color: _kSub),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Check back soon — Ramadan & Dhul-Hijjah events are coming!',
                      style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
                      textAlign: TextAlign.center),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _kText));
}

class _RamadanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A1040), Color(0xFF2D1B69)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: const Color(0xFF2D1B69).withValues(alpha: 0.4),
          blurRadius: 20, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      const Text('🌙', style: TextStyle(fontSize: 44)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ramadan Challenge',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('3× XP multiplier • Special badges • Community wells goal',
            style: GoogleFonts.outfit(fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
          child: Text('Coming Soon — Stay Consistent!',
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9))),
        ),
      ])),
    ]),
  );
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  const _ChallengeCard(this.challenge);

  @override
  Widget build(BuildContext context) {
    final title       = challenge['title']         as String? ?? '';
    final description = challenge['description']   as String? ?? '';
    final emoji       = challenge['emoji']         as String? ?? '⭐';
    final xpReward    = (challenge['xp_reward']    as num?)?.toInt() ?? 0;
    final coinReward  = (challenge['coin_reward']  as num?)?.toInt() ?? 0;
    final multiplier  = (challenge['xp_multiplier'] as num?)?.toDouble() ?? 1.0;
    final endDate     = challenge['end_date']      as String? ?? '';
    final progress    = (challenge['user_progress'] as num?)?.toInt() ?? 0;
    final goalTarget  = (challenge['goal_target']  as num?)?.toInt() ?? 1;
    final completed   = challenge['completed']     as bool? ?? false;
    final pct         = goalTarget > 0 ? (progress / goalTarget).clamp(0.0, 1.0) : 0.0;

    Color cardColor = _kPurple;
    if (multiplier > 1.0) cardColor = const Color(0xFFF5A623);
    if (completed)        cardColor = _kGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
            color: cardColor.withValues(alpha: 0.1),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
            Text(description,
                style: GoogleFonts.outfit(fontSize: 12, color: _kSub),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          if (completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
              child: Text('Done!', style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
        ]),
        if (goalTarget > 1) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8,
              backgroundColor: cardColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(cardColor),
            ),
          ),
          const SizedBox(height: 6),
          Text('$progress / $goalTarget',
              style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          if (xpReward > 0) _RewardChip('+$xpReward XP', cardColor),
          if (coinReward > 0) _RewardChip('+$coinReward Noor', _kGold),
          if (multiplier > 1.0)
            _RewardChip('${multiplier.toStringAsFixed(0)}× XP Boost', Colors.orange),
          if (endDate.isNotEmpty)
            _RewardChip('Ends ${endDate.substring(0, 10)}', _kSub),
        ]),
      ]),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RewardChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Text(label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — HISTORY  (Today / This Week / This Month / All Time)
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  final SupabaseClient supabase;
  const _HistoryTab({required this.supabase});
  @override State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  // 0=Today 1=Week 2=Month 3=All
  int _period = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  static const _periods = ['today', 'week', 'month', 'all'];
  static const _labels  = ['Today', 'This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.supabase
          .rpc('get_activity_history', params: {'period': _periods[_period]});
      _rows = (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _rows = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  // Derived stats
  int get _totalXp => _rows.fold(0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));
  int get _totalActions => _rows.length;

  // Group by activity_type for mini donut
  Map<String, int> get _byType {
    final m = <String, int>{};
    for (final r in _rows) {
      final t = r['activity_type'] as String? ?? 'other';
      m[t] = (m[t] ?? 0) + ((r['points_earned'] as num?)?.toInt() ?? 0);
    }
    return m;
  }

  void _switchPeriod(int i) {
    if (_period == i) return;
    setState(() => _period = i);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Period selector ────────────────────────────────────────────────────
      Container(
        color: _kWhite,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: List.generate(_labels.length, (i) {
            final sel = _period == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchPeriod(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < _labels.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? _kPurple : const Color(0xFFF2EFFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_labels[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _kPurple)),
                ),
              ),
            );
          }),
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPurple))
            : _rows.isEmpty
                ? _EmptyHistory(label: _labels[_period])
                : RefreshIndicator(
                    onRefresh: _load,
                    color: _kPurple,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _HistorySummary(
                          totalXp:     _totalXp,
                          totalActions:_totalActions,
                          byType:      _byType,
                          period:      _labels[_period],
                        )),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          sliver: SliverList(delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _ActivityRow(_rows[i]),
                            childCount: _rows.length,
                          )),
                        ),
                      ],
                    ),
                  ),
      ),
    ]);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  final String label;
  const _EmptyHistory({required this.label});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🌙', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('No activity $label',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 8),
        Text('Start earning XP — read Quran, count Dhikr, or log in daily.',
            style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Summary hero ──────────────────────────────────────────────────────────────
class _HistorySummary extends StatelessWidget {
  final int totalXp, totalActions;
  final Map<String, int> byType;
  final String period;
  const _HistorySummary({
    required this.totalXp, required this.totalActions,
    required this.byType,  required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Hero XP card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4EBB), Color(0xFF9B59B6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(
                color: _kPurple.withValues(alpha: 0.35),
                blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            // Animated XP counter
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(period,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 6),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: totalXp),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, v, __) => Text('$v XP',
                    style: GoogleFonts.outfit(
                        fontSize: 40, fontWeight: FontWeight.w900,
                        color: Colors.white, height: 1.0)),
              ),
              const SizedBox(height: 4),
              Text('across $totalActions action${totalActions == 1 ? '' : 's'}',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
            ])),
            const SizedBox(width: 16),
            // Mini donut
            if (byType.isNotEmpty)
              _MiniDonut(byType: byType),
          ]),
        ),

        // Breakdown chips
        if (byType.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Breakdown',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: byType.entries.map((e) {
              final meta = _activityMeta(e.key);
              return _BreakdownChip(
                  emoji: meta.emoji, label: meta.label,
                  xp: e.value, color: meta.color);
            }).toList(),
          ),
        ],

        const SizedBox(height: 20),
        Text('Activity Log',
            style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Mini donut chart ──────────────────────────────────────────────────────────
class _MiniDonut extends StatelessWidget {
  final Map<String, int> byType;
  const _MiniDonut({required this.byType});

  @override
  Widget build(BuildContext context) {
    final total = byType.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    return SizedBox(
      width: 72, height: 72,
      child: CustomPaint(
        painter: _DonutPainter(byType: byType, total: total),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> byType;
  final int total;
  _DonutPainter({required this.byType, required this.total});

  static const _colors = [
    Color(0xFFFFD700), Color(0xFF4FC3F7), Color(0xFFAED581),
    Color(0xFFFF8A65), Color(0xFFCE93D8), Color(0xFF80CBC4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;
    final innerR = r * 0.55;
    double startAngle = -math.pi / 2;
    int colorIdx = 0;

    for (final entry in byType.entries) {
      final sweep = 2 * math.pi * entry.value / total;
      final paint = Paint()
        ..color = _colors[colorIdx % _colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = r - innerR
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: (r + innerR) / 2),
        startAngle, sweep - 0.04, false, paint,
      );
      startAngle += sweep;
      colorIdx++;
    }

    // White centre circle
    canvas.drawCircle(Offset(cx, cy), innerR,
        Paint()..color = Colors.transparent);
  }

  @override bool shouldRepaint(_DonutPainter o) => o.byType != byType;
}

// ── Breakdown chip ────────────────────────────────────────────────────────────
class _BreakdownChip extends StatelessWidget {
  final String emoji, label;
  final int xp;
  final Color color;
  const _BreakdownChip({
    required this.emoji, required this.label,
    required this.xp,    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.w700, color: _kText)),
        Text('+$xp XP',
            style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    ]),
  );
}

// ── Individual activity row ───────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _ActivityRow(this.row);

  @override
  Widget build(BuildContext context) {
    final type    = row['activity_type']  as String? ?? 'other';
    final pts     = (row['points_earned'] as num?)?.toInt() ?? 0;
    final tsRaw   = row['created_at']     as String? ?? '';
    final meta    = _activityMeta(type);

    DateTime? ts;
    try { ts = DateTime.parse(tsRaw).toLocal(); } catch (_) {}

    final timeStr = ts != null
        ? '${_pad(ts.hour)}:${_pad(ts.minute)}  ${ts.day}/${ts.month}/${ts.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.color.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Icon circle
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: meta.color.withValues(alpha: 0.1),
          ),
          child: Center(child: Text(meta.emoji,
              style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        // Label + time
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meta.label,
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
          if (timeStr.isNotEmpty)
            Text(timeStr,
                style: GoogleFonts.outfit(fontSize: 11, color: _kSub)),
        ])),
        // XP badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('+$pts XP',
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: meta.color)),
        ),
      ]),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
