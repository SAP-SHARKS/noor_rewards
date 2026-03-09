// lib/screens/level_screen.dart
// Full XP / Levels / Badges / Challenges / History screen

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/xp_service.dart';
import '../services/streak_service.dart';
import '../widgets/noor_icons.dart';
import '../widgets/noor_offline.dart';

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

Widget _tierIcon(String title, {double size = 32}) {
  switch (title) {
    case 'Seeker':   return NoorIcon.seedling(size: size);
    case 'Believer': return NoorIcon.star(size: size);
    case 'Devoted':  return NoorIcon.heart(size: size);
    case 'Champion': return NoorIcon.trophy(size: size);
    case 'Legend':   return NoorIcon.crown(size: size);
    default:         return NoorIcon.sparkles(size: size);
  }
}

// Activity type → readable label + emoji + colour
({String label, Widget icon, Color color}) _activityMeta(String type) {
  switch (type) {
    case 'login':    return (label: 'Daily Login',       icon: NoorIcon.sunrise(size:22),  color: const Color(0xFF00897B));
    case 'validate': return (label: 'Validate & Support',icon: NoorIcon.check(size:22),    color: const Color(0xFF6B4EBB));
    case 'quran':    return (label: 'Read Quran',         icon: NoorIcon.book(size:22),     color: const Color(0xFF1565C0));
    case 'dhikr':    return (label: 'Dhikar & Dua',       icon: NoorIcon.beads(size:22),    color: const Color(0xFF558B2F));
    case 'tafsir':   return (label: 'Listen Tafsir',      icon: NoorIcon.headphones(size:22),color: const Color(0xFFAD1457));
    case 'challenge':return (label: 'Challenge',          icon: NoorIcon.medal(size:22),    color: const Color(0xFFF5A623));
    default:         return (label: type,                 icon: NoorIcon.star(size:22),     color: _kSub);
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
        title: Text('Journey',
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPurple,
          unselectedLabelColor: _kSub,
          indicatorColor: _kPurple,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '🔥 Streaks'),
            Tab(text: '📈 Progress'),
            Tab(text: '🏅 Badges'),
            Tab(text: '⚡ Challenges'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPurple))
          : TabBarView(
              controller: _tabs,
              children: [
                const _StreaksTab(),
                _ProgressTab(
                  xp:        _currentXp,
                  level:     _currentLevel,
                  streak:    _streak,
                  levelInfo: _levelInfo,
                  allLevels: _allLevels,
                  supabase:  _sb,
                ),
                _BadgesTab(badges: _badges),
                _ChallengesTab(challenges: _challenges, onRefresh: _loadAll),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PROGRESS  (includes embedded activity history at bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressTab extends StatefulWidget {
  final int xp, level, streak;
  final LevelInfo? levelInfo;
  final List<Map<String, dynamic>> allLevels;
  final SupabaseClient supabase;
  const _ProgressTab({
    required this.xp, required this.level, required this.streak,
    required this.levelInfo, required this.allLevels, required this.supabase,
  });
  @override State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  // ── History state ──────────────────────────────────────────────────────────
  int _period = 0;
  bool _histLoading = true;
  List<Map<String, dynamic>> _rows = [];

  static const _periods = ['today', 'week', 'month', 'all'];
  static const _pLabels  = ['Today', 'This Week', 'This Month', 'All Time'];

  @override void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    setState(() => _histLoading = true);
    try {
      final data = await widget.supabase
          .rpc('get_activity_history', params: {'period': _periods[_period]});
      _rows = (data as List).cast<Map<String, dynamic>>();
    } catch (_) { _rows = []; }
    if (mounted) setState(() => _histLoading = false);
  }

  void _switchPeriod(int i) {
    if (_period == i) return;
    setState(() => _period = i);
    _loadHistory();
  }

  int get _totalXp     => _rows.fold(0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));
  int get _totalActions => _rows.length;
  Map<String, int> get _byType {
    final m = <String, int>{};
    for (final r in _rows) {
      final t = r['activity_type'] as String? ?? 'other';
      m[t] = (m[t] ?? 0) + ((r['points_earned'] as num?)?.toInt() ?? 0);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final info     = widget.levelInfo;
    final color    = info != null ? _tierColor(info.title) : _kPurple;
    final progress = info?.progress(widget.xp) ?? 0.0;
    final toNext   = info?.xpToNextLevel(widget.xp) ?? 0;

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
              info != null ? _tierIcon(info.title, size: 48) : NoorIcon.seedling(size: 48),
            ]),
            const SizedBox(height: 12),
            Text('Level ${widget.level}',
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
              Text('${widget.xp} XP',
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
          _MiniStat(NoorIcon.fire(size:22), '${widget.streak}', 'Day Streak'),
          const SizedBox(width: 12),
          _MiniStat(NoorIcon.star(size:22), '${widget.xp}', 'Total XP'),
          const SizedBox(width: 12),
          _MiniStat(NoorIcon.medal(size:22), 'Lv ${widget.level}', 'Current Level'),
        ]),

        // ── XP Earning guide ───────────────────────────────────────────────
        const SizedBox(height: 28),
        Text('How to Earn XP',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 14),
        _XpRow(NoorIcon.book(size:20), 'Read 1 Ayah',           '+${XpReward.ayahRead} XP'),
        _XpRow(NoorIcon.books(size:20), 'Complete 1 Juz',        '+${XpReward.juzComplete} XP'),
        _XpRow(NoorIcon.beads(size:20), 'SubhanAllah x33',       '+8 XP'),
        _XpRow(NoorIcon.beads(size:20), 'La ilaha illallah x100','+15 XP'),
        _XpRow(NoorIcon.sunrise(size:20), 'Daily Login',          '+${XpReward.dailyLogin} XP'),
        _XpRow(NoorIcon.sparkles(size:20),'Validate & Support',   '+${XpReward.validateCoins} XP'),

        // ── Level tiers ────────────────────────────────────────────────────
        const SizedBox(height: 28),
        Text('Level Tiers',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 14),
        for (final tier in _tierGroups) _TierCard(tier: tier, currentLevel: widget.level),

        // ── Activity History ───────────────────────────────────────────────
        const SizedBox(height: 32),
        Row(children: [
          NoorIcon.lightning(size: 20),
          const SizedBox(width: 8),
          Text('Activity History',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
        ]),
        const SizedBox(height: 14),

        // Period selector
        Container(
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: List.generate(_pLabels.length, (i) {
              final sel = _period == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchPeriod(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _kPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_pLabels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : _kPurple)),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        if (_histLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: NoorInlineLoader(height: 100, color: _kPurple, label: 'Loading history…'),
          )
        else if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Column(children: [
              NoorIcon.moon(size: 52),
              const SizedBox(height: 12),
              Text('No activity ${_pLabels[_period].toLowerCase()}',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
              const SizedBox(height: 6),
              Text('Start earning XP — read Quran, do Dhikr & Dua, or log in daily.',
                  style: GoogleFonts.outfit(fontSize: 13, color: _kSub), textAlign: TextAlign.center),
            ])),
          )
        else ...[
          // Summary hero card
          _HistorySummary(
            totalXp: _totalXp, totalActions: _totalActions,
            byType: _byType, period: _pLabels[_period],
          ),
          const SizedBox(height: 4),
          // Activity rows
          for (final row in _rows) _ActivityRow(row),
        ],
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
  final Widget icon;
  final String value, label;
  const _MiniStat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(children: [
        icon,
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: _kSub), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _XpRow extends StatelessWidget {
  final Widget icon;
  final String label, reward;
  const _XpRow(this.icon, this.label, this.reward);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
    child: Row(children: [
      icon,
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
        SizedBox(
          width: 32, height: 32,
          child: _tierIcon(tier.title, size: 32),
        ),
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
            NoorIcon.medal(size: 40),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${earned.length} / ${badges.length} Earned',
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
              Text('Keep going — more badges to unlock!',
                  style: GoogleFonts.outfit(fontSize: 12, color: _kSub)),
            ])),
          ]),
        ),

        if (earned.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Earned',
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
          Text('Locked',
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
          child: Center(child: earned
            ? NoorIcon.fromEmoji(badge.emoji, size: earned ? 28 : 22)
            : NoorIcon.lock(size: 22)),
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
            _SectionHeader('Seasonal Events', NoorIcon.kaaba(size:18)),
            const SizedBox(height: 12),
            for (final c in seasonal) _ChallengeCard(c),
          ],
          if (weekly.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader('Weekly Challenges', NoorIcon.calendar(size:18)),
            const SizedBox(height: 12),
            for (final c in weekly) _ChallengeCard(c),
          ],
          if (special.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader('Special Events', NoorIcon.star(size:18)),
            const SizedBox(height: 12),
            for (final c in special) _ChallengeCard(c),
          ],
          if (challenges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  NoorIcon.moon(size: 56),
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
  final Widget? icon;
  const _SectionHeader(this.text, [this.icon]);
  @override
  Widget build(BuildContext context) => Row(children: [
    if (icon != null) ...[ icon!, const SizedBox(width: 8) ],
    Text(text, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
  ]);
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
      NoorIcon.moon(size: 44),
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
                  icon: meta.icon, label: meta.label,
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
  final Widget icon;
  final String label;
  final int xp;
  final Color color;
  const _BreakdownChip({
    required this.icon, required this.label,
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
      icon,
      const SizedBox(width: 6),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _kText)),
          Text('+$xp XP',
              style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
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
          child: Center(child: meta.icon),
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

// ─────────────────────────────────────────────────────────────────────────────
// STREAKS TAB — embedded in Journey screen (formerly standalone StreakScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _StreaksTab extends StatefulWidget {
  const _StreaksTab();
  @override State<_StreaksTab> createState() => _StreaksTabState();
}

class _StreaksTabState extends State<_StreaksTab> with TickerProviderStateMixin {
  StreakSnapshot _snap = StreakSnapshot.empty;
  bool _loading = true;

  late AnimationController _flameCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late Animation<double> _flameScale;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _orbCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _flameScale = Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));
    _pulse      = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
  }

  Future<void> _load() async {
    final snap = await StreakService.instance.loadSnapshot();
    if (mounted) setState(() { _snap = snap; _loading = false; });
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final best      = [_snap.login, _snap.dhikr, _snap.quran].reduce((a, b) => a > b ? a : b);
    final milestone = nextMilestone(best);
    final lastM     = lastMilestone(best);

    return Container(
      color: const Color(0xFF0A1628),
      child: Stack(children: [
        // Animated aura background
        Positioned.fill(child: AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) => CustomPaint(painter: _StreakAuraPainter(phase: _orbCtrl.value)),
        )),
        if (_loading)
          const NoorInlineLoader(height: double.infinity, color: Color(0xFFFF6B35), label: 'Loading streaks…')
        else
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(children: [
              // ── Hero flame ───────────────────────────────────────────────
              _StreakHeroFlame(streak: best, flameScale: _flameScale, pulse: _pulse, milestone: lastM),
              const SizedBox(height: 24),

              // ── 3 flame cards (Login / Dhikr / Quran) ───────────────────
              Row(children: StreakType.values.map((t) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: t == StreakType.login ? 0 : 6, right: t == StreakType.quran ? 0 : 6),
                  child: _StreakFlameCard(type: t, streak: _snap.streakFor(t), best: _snap.bestFor(t), pulse: _pulse),
                ),
              )).toList()),
              const SizedBox(height: 20),

              // ── 7-day calendar ───────────────────────────────────────────
              _StreakCalendar(snap: _snap),
              const SizedBox(height: 20),

              // ── Milestone progress bar ───────────────────────────────────
              if (milestone != null) ...[
                _StreakMilestoneProgress(current: best, milestone: milestone, lastM: lastM),
                const SizedBox(height: 20),
              ],

              // ── All milestones ───────────────────────────────────────────
              _StreakMilestoneList(streak: best),
            ]),
          ),
      ]),
    );
  }
}

// ── Aura background painter ───────────────────────────────────────────────────
class _StreakAuraPainter extends CustomPainter {
  final double phase;
  const _StreakAuraPainter({required this.phase});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final p1 = Paint()..shader = RadialGradient(colors: [
      const Color(0xFFFF6B35).withValues(alpha: 0.20), Colors.transparent,
    ]).createShader(Rect.fromCircle(center: Offset(cx, size.height * 0.25), radius: 240));
    canvas.drawCircle(Offset(cx, size.height * 0.25), 240, p1);
    final ang = phase * 2 * math.pi;
    final p2 = Paint()..shader = RadialGradient(colors: [
      const Color(0xFFFF9500).withValues(alpha: 0.10), Colors.transparent,
    ]).createShader(Rect.fromCircle(center: Offset(cx + math.cos(ang) * 50, size.height * 0.32 + math.sin(ang) * 30), radius: 160));
    canvas.drawCircle(Offset(cx + math.cos(ang) * 50, size.height * 0.32 + math.sin(ang) * 30), 160, p2);
  }
  @override bool shouldRepaint(_StreakAuraPainter o) => o.phase != phase;
}

// ── Hero flame widget ─────────────────────────────────────────────────────────
class _StreakHeroFlame extends StatelessWidget {
  final int streak;
  final Animation<double> flameScale, pulse;
  final StreakMilestone? milestone;
  const _StreakHeroFlame({required this.streak, required this.flameScale, required this.pulse, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([flameScale, pulse]),
      builder: (_, __) => Column(children: [
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: pulse.value * 0.4), blurRadius: 50, spreadRadius: 10),
          ]),
          child: Center(child: Transform.scale(scale: flameScale.value, child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFFFFD700), Color(0xFFFF9500), Color(0xFFFF6B35)], stops: [0.0, 0.55, 1.0]),
              boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.5), blurRadius: 28, spreadRadius: 4)],
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              NoorIcon.fire(size: 32),
              Text('$streak', style: GoogleFonts.rajdhani(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
              Text('day${streak == 1 ? '' : 's'}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
            ])),
          ))),
        ),
        const SizedBox(height: 12),
        Text(streak == 0 ? 'Start your streak today!' : streak >= 100 ? "Centurion — Masha'Allah!" : 'Current best streak',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500)),
        if (streak > 0 && milestone != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF9500)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Next: ${milestone!.label} (${milestone!.days} days)',
                style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4)),
          ),
        ],
      ]),
    );
  }
}

// ── Flame card (one per streak type) ─────────────────────────────────────────
class _StreakFlameCard extends StatelessWidget {
  final StreakType type;
  final int streak, best;
  final Animation<double> pulse;
  const _StreakFlameCard({required this.type, required this.streak, required this.best, required this.pulse});

  Color get _color => switch (type) {
    StreakType.login  => const Color(0xFFFF6B35),
    StreakType.dhikr  => const Color(0xFF00C875),
    StreakType.quran  => const Color(0xFF5856D6),
  };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: streak > 0 ? _color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08)),
        boxShadow: streak > 0 ? [BoxShadow(color: _color.withValues(alpha: pulse.value * 0.22), blurRadius: 14, spreadRadius: 2)] : [],
      ),
      child: Column(children: [
        Text(type.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text('$streak', style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.w900, color: streak > 0 ? _color : Colors.white30, height: 1.0)),
        Text('day${streak == 1 ? '' : 's'}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text('Best $best', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: _color.withValues(alpha: 0.9))),
        ),
        const SizedBox(height: 4),
        Text(type.label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ── 7-day calendar ────────────────────────────────────────────────────────────
class _StreakCalendar extends StatelessWidget {
  final StreakSnapshot snap;
  const _StreakCalendar({required this.snap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days  = List.generate(7, (i) => DateTime(today.year, today.month, today.day - (6 - i)));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LAST 7 DAYS', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: days.map((day) {
          final isToday = day.day == today.day && day.month == today.month && day.year == today.year;
          return Expanded(child: Column(children: [
            Text(['Mo','Tu','We','Th','Fr','Sa','Su'][day.weekday - 1],
                style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${day.day}', style: GoogleFonts.outfit(fontSize: 10, color: isToday ? Colors.white : Colors.white38,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w400)),
            const SizedBox(height: 6),
            ...StreakType.values.map((t) {
              final on = snap.historyFor(t).any((d) => d.day == day.day && d.month == day.month && d.year == day.year);
              final col = switch (t) { StreakType.login => const Color(0xFFFF6B35), StreakType.dhikr => const Color(0xFF00C875), StreakType.quran => const Color(0xFF5856D6) };
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Container(width: 9, height: 9, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? col : Colors.white.withValues(alpha: 0.08),
                  boxShadow: on ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 5)] : [],
                )),
              );
            }),
          ]));
        }).toList()),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: StreakType.values.map((t) {
          final col = switch (t) { StreakType.login => const Color(0xFFFF6B35), StreakType.dhikr => const Color(0xFF00C875), StreakType.quran => const Color(0xFF5856D6) };
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(t.label, style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38)),
          ]));
        }).toList()),
      ]),
    );
  }
}

// ── Milestone progress bar ────────────────────────────────────────────────────
class _StreakMilestoneProgress extends StatelessWidget {
  final int current;
  final StreakMilestone milestone;
  final StreakMilestone? lastM;
  const _StreakMilestoneProgress({required this.current, required this.milestone, required this.lastM});

  @override
  Widget build(BuildContext context) {
    final start = lastM?.days ?? 0;
    final pct   = ((current - start) / (milestone.days - start)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('NEXT MILESTONE', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 1.2)),
          const Spacer(),
          Text('+${milestone.xpBonus} XP', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFFFD700))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(milestone.label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
          Text('$current / ${milestone.days} days', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
        ]),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: v, minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35))),
          ),
        ),
        const SizedBox(height: 6),
        Text('${milestone.days - current} more day${milestone.days - current == 1 ? '' : 's'} to go!',
            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Full milestone list ───────────────────────────────────────────────────────
class _StreakMilestoneList extends StatelessWidget {
  final int streak;
  const _StreakMilestoneList({required this.streak});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ALL MILESTONES', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white54, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ...kStreakMilestones.map((m) {
        final done = streak >= m.days;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: done ? const Color(0xFFFF6B35).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: done ? const Color(0xFFFF6B35).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.10)),
                boxShadow: done ? [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.28), blurRadius: 10)] : [],
              ),
              child: Center(child: done ? NoorIcon.fromEmoji(m.emoji, size: 17) : NoorIcon.lock(size: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: done ? Colors.white : Colors.white38)),
              Text('${m.days} day streak', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: done ? const Color(0xFFFFD700).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+${m.xpBonus} XP', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.w700,
                  color: done ? const Color(0xFFFFD700) : Colors.white24, letterSpacing: 0.4)),
            ),
          ]),
        );
      }),
    ]),
  );
}
