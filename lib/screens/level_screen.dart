// lib/screens/level_screen.dart
// Full pts / Levels / Badges / Challenges / History screen

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/xp_service.dart';
import '../services/streak_service.dart';
import '../widgets/noor_icons.dart';
import '../widgets/noor_offline.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../theme/y4_theme.dart';
import '../l10n/app_localizations.dart';
import '../config/feature_flags.dart';

// ── Palette (reads from admin-controlled AppConfig) ─────────────────────────
AppConfig get _lcfg => SettingsService.instance.config;

Color get _kBg => _lcfg.dashBg;
const _kWhite = Colors.white;
Color get _kText => _lcfg.dashText;
Color get _kSub =>
    _lcfg.dashBg.computeLuminance() > 0.5
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9CA3AF);
Color get _kGold => _lcfg.donationColor;
Color get _kPurple => _lcfg.secondaryColor;
Color get _kGreen => _lcfg.dashTeal;

// ── Level tier colours ────────────────────────────────────────────────────────
Color _tierColor(String title) {
  switch (title) {
    case 'Seeker':
      return const Color(0xFF78C1F3);
    case 'Believer':
      return const Color(0xFF4CAF50);
    case 'Devoted':
      return const Color(0xFFAB47BC);
    case 'Champion':
      return const Color(0xFFF5A623);
    case 'Legend':
      return const Color(0xFFE53935);
    default:
      return _kSub;
  }
}

Widget _tierIcon(String title, {double size = 32}) {
  switch (title) {
    case 'Seeker':
      return NoorIcon.seedling(size: size);
    case 'Believer':
      return NoorIcon.star(size: size);
    case 'Devoted':
      return NoorIcon.heart(size: size);
    case 'Champion':
      return NoorIcon.trophy(size: size);
    case 'Legend':
      return NoorIcon.crown(size: size);
    default:
      return NoorIcon.sparkles(size: size);
  }
}

// Localize tier title from the English key stored in data
String _localTierTitle(BuildContext context, String title) {
  final l = AppLocalizations.of(context)!;
  switch (title) {
    case 'Seeker':
      return l.levelSeeker;
    case 'Believer':
      return l.levelBeliever;
    case 'Devoted':
      return l.levelDevoted;
    case 'Champion':
      return l.levelChampion;
    case 'Legend':
      return l.levelLegend;
    default:
      return title;
  }
}

// Activity type → readable label + emoji + colour
({String label, Widget icon, Color color}) _activityMeta(
  BuildContext context,
  String type,
) {
  final l = AppLocalizations.of(context)!;
  switch (type) {
    case 'login':
      return (
        label: l.dailyLogin,
        icon: NoorIcon.sunrise(size: 22),
        color: const Color(0xFF00897B),
      );
    case 'validate':
      return (
        label: l.validateAndSupport,
        icon: NoorIcon.check(size: 22),
        color: const Color(0xFF6B4EBB),
      );
    case 'quran':
      return (
        label: l.readQuran,
        icon: NoorIcon.book(size: 22),
        color: const Color(0xFF1565C0),
      );
    case 'dhikr':
      return (
        label: l.dhikarAndDua,
        icon: NoorIcon.beads(size: 22),
        color: const Color(0xFF558B2F),
      );
    case 'tafsir':
      return (
        label: l.listenTafsir,
        icon: NoorIcon.headphones(size: 22),
        color: const Color(0xFFAD1457),
      );
    case 'challenge':
      return (
        label: l.challenge,
        icon: NoorIcon.medal(size: 22),
        color: const Color(0xFFF5A623),
      );
    default:
      return (label: type, icon: NoorIcon.star(size: 22), color: _kSub);
  }
}

// Period labels (localized)
List<String> _pLabels(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [l.today, l.thisWeek, l.thisMonth, l.allTime];
}

// ─────────────────────────────────────────────────────────────────────────────
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});
  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  final _xp = XpService.instance;
  final _sb = Supabase.instance.client;

  // Profile
  int _currentXp = 0;
  int _currentLevel = 1;
  int _streak = 0;
  LevelInfo? _levelInfo;
  List<Map<String, dynamic>> _allLevels = [];
  List<BadgeInfo> _badges = [];
  List<Map<String, dynamic>> _challenges = [];
  StreakSnapshot? _streakSnap;
  bool _loading = true;
  // Captures any thrown error from _loadAll so the UI can show a retry
  // instead of getting stuck on the spinner (the "blank Journey page" bug).
  Object? _loadError;

  /// Number of tabs currently shown. The Challenges tab is gated on the
  /// `challengesTab` remote feature flag, so this can change at runtime.
  int get _desiredTabCount => FeatureFlags.challengesTab ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _desiredTabCount, vsync: this);
    _loadAll();
  }

  /// Keeps [_tabs] in sync with [_desiredTabCount].
  ///
  /// `challengesTab` is a remote flag that can flip AFTER initState — the
  /// app config loads asynchronously at startup and refreshes over
  /// Realtime. When it flips, build() emits a different number of tabs
  /// than the controller's length; TabBar/TabBarView then throw and the
  /// whole Journey screen renders blank. Recreating the controller on a
  /// length change keeps them consistent. Requires TickerProviderStateMixin
  /// (not Single…) so a fresh controller can allocate a new ticker.
  void _syncTabController() {
    if (_tabs.length == _desiredTabCount) return;
    final keepIndex = _tabs.index.clamp(0, _desiredTabCount - 1);
    _tabs.dispose();
    _tabs = TabController(
      length: _desiredTabCount,
      vsync: this,
      initialIndex: keepIndex,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      // Run all fetches in parallel — total time = max(t1..t5) not the sum
      final results = await Future.wait([
        _xp.loadProfile(),
        _xp.loadLevels(),
        _xp.loadBadges(),
        _xp.loadChallenges(),
        StreakService.instance.loadSnapshot(),
      ]);

      final profile = results[0] as ({int pts, int level, int streak});
      _currentXp = profile.pts;
      _currentLevel = profile.level;
      _streak = profile.streak;
      _allLevels = results[1] as List<Map<String, dynamic>>;
      _badges = results[2] as List<BadgeInfo>;
      _challenges = results[3] as List<Map<String, dynamic>>;
      _streakSnap = results[4] as StreakSnapshot;
      _levelInfo = _xp.resolveLevelInfo(_currentXp, _currentLevel, _allLevels);
    } catch (e, st) {
      // Without this, any one failing parallel fetch (transient network,
      // auth-token refresh race, RLS hiccup, cold-start profile row) left
      // _loading stuck true forever and the tab rendered as blank.
      debugPrint('LevelScreen load failed: $e\n$st');
      if (mounted) _loadError = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Resync before using _tabs — the Challenges tab's remote flag may
    // have flipped since initState (see _syncTabController). Without this
    // the tab count and controller length diverge and the screen blanks.
    _syncTabController();
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Y4.bg,
        surfaceTintColor: Y4.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Y4.ink,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.journey,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Y4.ink,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Y4.honeyDeep,
          unselectedLabelColor: Y4.inkSoft,
          indicatorColor: Y4.honeyDeep,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: '🔥 ${l.tabStreaks}'),
            Tab(text: '📈 ${l.tabProgress}'),
            Tab(text: '🏅 ${l.tabBadges}'),
            if (FeatureFlags.challengesTab)
              Tab(text: '⚡ ${l.tabChallenges}'),
          ],
        ),
      ),
      body:
          _loading
              ? Center(child: NoorInlineLoader(color: Y4.honeyDeep))
              : _loadError != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Y4.inkSoft,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Couldn't load your Journey",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Y4.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Y4.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadAll,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : TabBarView(
                controller: _tabs,
                children: [
                  _StreaksTab(initialSnap: _streakSnap),
                  _ProgressTab(
                    pts: _currentXp,
                    level: _currentLevel,
                    streak: _streak,
                    levelInfo: _levelInfo,
                    allLevels: _allLevels,
                    supabase: _sb,
                  ),
                  _BadgesTab(badges: _badges),
                  if (FeatureFlags.challengesTab)
                    _ChallengesTab(
                      challenges: _challenges,
                      onRefresh: _loadAll,
                    ),
                ],
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — PROGRESS  (includes embedded activity history at bottom)
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressTab extends StatefulWidget {
  final int pts, level, streak;
  final LevelInfo? levelInfo;
  final List<Map<String, dynamic>> allLevels;
  final SupabaseClient supabase;
  const _ProgressTab({
    required this.pts,
    required this.level,
    required this.streak,
    required this.levelInfo,
    required this.allLevels,
    required this.supabase,
  });
  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  // ── History state ──────────────────────────────────────────────────────────
  int _period = 0;
  bool _histLoading = true;
  bool _showAllActivity = false;
  bool _showAllXpGuide = false;
  List<Map<String, dynamic>> _rows = [];

  static const _periods = ['today', 'week', 'month', 'all'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _histLoading = true);
    try {
      final data = await widget.supabase.rpc(
        'get_activity_history',
        params: {'period': _periods[_period]},
      );
      _rows = (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _rows = [];
    }
    if (mounted) setState(() => _histLoading = false);
  }

  void _switchPeriod(int i) {
    if (_period == i) return;
    setState(() {
      _period = i;
      _showAllActivity = false;
    });
    _loadHistory();
  }

  int get _totalPts =>
      _rows.fold(0, (s, r) => s + ((r['points_earned'] as num?)?.toInt() ?? 0));
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
    final l = AppLocalizations.of(context)!;
    final info = widget.levelInfo;
    final color = info != null ? _tierColor(info.title) : _kPurple;
    final lvProgress = info?.progress(widget.pts) ?? 0.0;
    final toNext = info?.ptsToNextLevel(widget.pts) ?? 0;
    final pLabels = _pLabels(context);

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // SPLIT HERO — Level (left) + pts Period (right) in one premium card
          // ═══════════════════════════════════════════════════════════════════
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.92),
                  color.withValues(alpha: 0.65),
                  Y4.primaryDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Column(
              children: [
                // ── Period selector tabs ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: List.generate(pLabels.length, (i) {
                        final sel = _period == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _switchPeriod(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                pLabels[i],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? color : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // ── Split: Level | pts ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left half — Level ──────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  info != null
                                      ? _tierIcon(info.title, size: 28)
                                      : NoorIcon.seedling(size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    info != null
                                        ? _localTierTitle(context, info.title)
                                        : l.levelSeeker,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${l.level} ${widget.level}',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${l.dayStreak(widget.streak.toString())} 🔥',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // pts progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: lvProgress),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOut,
                                  builder:
                                      (_, v, __) => LinearProgressIndicator(
                                        value: v,
                                        minHeight: 8,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.15),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.ptsToLevel(
                                  toNext.toString(),
                                  (widget.level + 1).toString(),
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),

                        // Right half — Period pts ──────────────────────────────────
                        Flexible(
                          flex: 2,
                          child:
                              _histLoading
                                  ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFC9921A),
                                            ),
                                      ),
                                    ),
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pLabels[_period],
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.white60,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TweenAnimationBuilder<int>(
                                        tween: IntTween(
                                          begin: 0,
                                          end: _totalPts,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 900,
                                        ),
                                        curve: Curves.easeOut,
                                        builder:
                                            (_, v, __) => Text(
                                              '$v Seeds',
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.1,
                                              ),
                                            ),
                                      ),
                                      Text(
                                        '$_totalActions action${_totalActions == 1 ? '' : 's'}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.white60,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_byType.isNotEmpty)
                                        SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: CustomPaint(
                                            painter: _DonutPainter(
                                              byType: _byType,
                                              total: _byType.values.fold(
                                                0,
                                                (a, b) => a + b,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Breakdown chips ────────────────────────────────────────────────
          if (!_histLoading && _byType.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.breakdown,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _byType.entries.map((e) {
                          final meta = _activityMeta(context, e.key);
                          return _BreakdownChip(
                            icon: meta.icon,
                            label: meta.label,
                            pts: e.value,
                            color: meta.color,
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // ── Activity Log ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_histLoading && _rows.isNotEmpty) ...[
                  Text(
                    l.activityLog,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Show 2 rows by default, all rows when expanded
                  for (final row
                      in (_showAllActivity ? _rows : _rows.take(2).toList()))
                    _ActivityRow(row),
                  // See More / Show Less button
                  if (_rows.length > 2) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap:
                          () => setState(
                            () => _showAllActivity = !_showAllActivity,
                          ),
                      child: Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _kPurple.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _kPurple.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showAllActivity
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: _kPurple,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showAllActivity
                                  ? l.showLess
                                  : '${l.seeMore}  (${_rows.length - 2} more)',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ] else if (!_histLoading && _rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          NoorIcon.moon(size: 44),
                          const SizedBox(height: 10),
                          Text(
                            l.noActivity(pLabels[_period].toLowerCase()),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.startEarningPts,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _kSub,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── How to Earn pts ─────────────────────────────────────────────
                Text(
                  l.howToEarnPts,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 14),
                _XpRow(
                  NoorIcon.book(size: 20),
                  l.readOneAyah,
                  '+${PointReward.ayahRead} Seeds',
                ),
                _XpRow(
                  NoorIcon.books(size: 20),
                  l.completeOneJuz,
                  '+${PointReward.juzComplete} Seeds',
                ),
                if (_showAllXpGuide) ...[
                  _XpRow(
                    NoorIcon.beads(size: 20),
                    'SubhanAllah x33',
                    '+${PointReward.dhikr} Seeds',
                  ),
                  _XpRow(
                    NoorIcon.beads(size: 20),
                    'La ilaha illallah x100',
                    '+${PointReward.dhikr} Seeds',
                  ),
                  _XpRow(
                    NoorIcon.sunrise(size: 20),
                    l.dailyLogin,
                    '+${PointReward.dailyLogin} Seeds',
                  ),
                  _XpRow(
                    NoorIcon.sparkles(size: 20),
                    l.validateAndSupport,
                    '+${PointReward.validate} Seeds',
                  ),
                ],
                GestureDetector(
                  onTap:
                      () => setState(() => _showAllXpGuide = !_showAllXpGuide),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _kPurple.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _kPurple.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAllXpGuide
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _kPurple,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAllXpGuide
                              ? l.showLess
                              : '${l.seeMore}  (4 more)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Level Tiers ────────────────────────────────────────────────
                const SizedBox(height: 28),
                Text(
                  l.levelTiers,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 14),
                for (final tier in _tierGroups)
                  _TierCard(tier: tier, currentLevel: widget.level),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _tierGroups = [
    (
      title: 'Seeker',
      emoji: '🌱',
      range: '1–5',
      pts: '0–500 Seeds',
      color: Color(0xFF78C1F3),
      unlocks: 'Basic features',
    ),
    (
      title: 'Believer',
      emoji: '🌟',
      range: '6–10',
      pts: '500–1,500 Seeds',
      color: Color(0xFF4CAF50),
      unlocks: 'Custom profile themes',
    ),
    (
      title: 'Devoted',
      emoji: '💜',
      range: '11–20',
      pts: '1,500–5,000 Seeds',
      color: Color(0xFFAB47BC),
      unlocks: 'Leaderboard badge',
    ),
    (
      title: 'Champion',
      emoji: '🏆',
      range: '21–50',
      pts: '5,000–20,000 Seeds',
      color: Color(0xFFF5A623),
      unlocks: 'Exclusive voting rights',
    ),
    (
      title: 'Legend',
      emoji: '👑',
      range: '50+',
      pts: '20,000+ Seeds',
      color: Color(0xFFE53935),
      unlocks: 'Hall of Fame listing',
    ),
  ];
}

class _XpRow extends StatelessWidget {
  final Widget icon;
  final String label, reward;
  const _XpRow(this.icon, this.label, this.reward);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: _kWhite,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
      ],
    ),
    child: Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            reward,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kPurple,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TierCard extends StatelessWidget {
  final ({
    String title,
    String emoji,
    String range,
    String pts,
    Color color,
    String unlocks,
  })
  tier;
  final int currentLevel;
  const _TierCard({required this.tier, required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final levelNum =
        int.tryParse(tier.range.split('–').first.replaceAll('+', '')) ?? 1;
    final isActive = _isInTier(currentLevel, tier.range);
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
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: tier.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                  ),
                ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: _tierIcon(tier.title, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _localTierTitle(context, tier.title),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isUnlocked ? tier.color : _kSub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lv ${tier.range}',
                      style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tier.pts,
                  style: GoogleFonts.outfit(fontSize: 12, color: _kSub),
                ),
                const SizedBox(height: 3),
                Text(
                  'Unlocks: ${tier.unlocks}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? tier.color : _kSub,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tier.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.now,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          else if (!isUnlocked)
            Icon(Icons.lock_rounded, color: _kSub, size: 20),
        ],
      ),
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
// TAB 2 — BADGES  (Premium gaming « Trophy Vault » redesign)
// ─────────────────────────────────────────────────────────────────────────────

// Per-badge accent color derived from the badge emoji / category
Color _badgeColor(String emoji) {
  switch (emoji) {
    case '📖':
      return const Color(0xFF3B82F6);
    case '🌟':
      return const Color(0xFFF5A623);
    case '🔥':
      return const Color(0xFFEF4444);
    case '💎':
      return const Color(0xFF06B6D4);
    case '🏆':
      return const Color(0xFFD4AF37);
    case '🌙':
      return const Color(0xFF818CF8);
    case '☀️':
      return const Color(0xFFFBBF24);
    case '💜':
      return const Color(0xFF9B59B6);
    case '🤝':
      return const Color(0xFF10B981);
    case '🎯':
      return const Color(0xFFEC4899);
    case '⚡':
      return Y4.butter;
    case '🌱':
      return const Color(0xFF4CAF50);
    case '👑':
      return const Color(0xFFFF6B6B);
    default:
      return Y4.honeyDeep;
  }
}

class _BadgesTab extends StatelessWidget {
  final List<BadgeInfo> badges;
  const _BadgesTab({required this.badges});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final earned = badges.where((b) => b.earned).toList();
    final locked = badges.where((b) => !b.earned).toList();
    final pct = badges.isEmpty ? 0.0 : earned.length / badges.length;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trophy Vault Header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Y4.honey, Y4.amberY],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Column(
              children: [
                // Glowing trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.white, Y4.cream, Y4.honey],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.trophyVault,
                  style: GoogleFonts.rajdhani(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Y4.ink,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.badgesCollected(
                    earned.length.toString(),
                    badges.length.toString(),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Y4.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Y4.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder:
                        (_, v, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: v,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Y4.ink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.percentComplete((pct * 100).round().toString()),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Y4.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.toUnlock((badges.length - earned.length).toString()),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Y4.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Earned badges ───────────────────────────────────────────────────
          if (earned.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Y4.butter, Color(0xFFFF8C00)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.earned,
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1C1C1E),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Y4.butter.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Y4.butter.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${earned.length}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF8C00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: earned.map((b) => _BadgeCard(b, true)).toList(),
              ),
            ),
          ],

          // ── Locked badges ───────────────────────────────────────────────────
          if (locked.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E8E93).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.locked,
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8E8E93),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E8E93).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${locked.length}',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: locked.map((b) => _BadgeCard(b, false)).toList(),
              ),
            ),
          ],
          const SizedBox(height: 110),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeInfo badge;
  final bool earned;
  const _BadgeCard(this.badge, this.earned);

  @override
  Widget build(BuildContext context) {
    final accent = _badgeColor(badge.emoji);
    return Container(
      decoration: BoxDecoration(
        color: earned ? Y4.cream : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              earned
                  ? Y4.honeyDeep.withValues(alpha: 0.3)
                  : const Color(0xFFE5E5EA),
          width: earned ? 1.5 : 1.0,
        ),
        boxShadow:
            earned
                ? [
                  BoxShadow(
                    color: Y4.honeyDeep.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Badge icon ──────────────────────────────────────────────────
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    earned
                        ? Y4.honey.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.08),
                border:
                    earned
                        ? Border.all(
                          color: Y4.honeyDeep.withValues(alpha: 0.4),
                          width: 2,
                        )
                        : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (earned)
                    Text(badge.emoji, style: const TextStyle(fontSize: 32))
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.grey.shade400,
                          size: 26,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Badge name ──────────────────────────────────────────────────
            Text(
              badge.name,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: earned ? Y4.ink : const Color(0xFF8E8E93),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // ── pts reward chip ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    earned
                        ? Y4.honey.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    earned
                        ? Border.all(
                          color: Y4.honeyDeep.withValues(alpha: 0.35),
                        )
                        : null,
              ),
              child: Text(
                earned
                    ? '+${badge.ptsReward} Seeds ✓'
                    : '+${badge.ptsReward} Seeds',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: earned ? Y4.honeyDeep : const Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final l = AppLocalizations.of(context)!;
    final weekly = challenges.where((c) => c['type'] == 'weekly').toList();
    final seasonal = challenges.where((c) => c['type'] == 'seasonal').toList();
    final special = challenges.where((c) => c['type'] == 'special').toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: _kPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RamadanBanner(),
            if (seasonal.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(l.seasonalEvents, NoorIcon.kaaba(size: 18)),
              const SizedBox(height: 12),
              for (final c in seasonal) _ChallengeCard(c),
            ],
            if (weekly.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(l.weeklyChallenges, NoorIcon.calendar(size: 18)),
              const SizedBox(height: 12),
              for (final c in weekly) _ChallengeCard(c),
            ],
            if (special.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(l.specialEvents, NoorIcon.star(size: 18)),
              const SizedBox(height: 12),
              for (final c in special) _ChallengeCard(c),
            ],
            if (challenges.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      NoorIcon.moon(size: 56),
                      const SizedBox(height: 16),
                      Text(
                        l.noActiveChallenges,
                        style: GoogleFonts.outfit(fontSize: 16, color: _kSub),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.checkBackChallenges,
                        style: GoogleFonts.outfit(fontSize: 13, color: _kSub),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final Widget? icon;
  const _SectionHeader(this.text, [this.icon]);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[icon!, const SizedBox(width: 8)],
      Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _kText,
        ),
      ),
    ],
  );
}

class _RamadanBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Y4.primaryDeep, Y4.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Y4.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          NoorIcon.moon(size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.ramadanChallenge,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.ramadanChallengeDesc,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    l.comingSoonStayConsistent,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  const _ChallengeCard(this.challenge);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = challenge['title'] as String? ?? '';
    final description = challenge['description'] as String? ?? '';
    final emoji = challenge['emoji'] as String? ?? '⭐';
    final ptsReward = (challenge['xp_reward'] as num?)?.toInt() ?? 0;
    final coinReward = (challenge['coin_reward'] as num?)?.toInt() ?? 0;
    final multiplier = (challenge['xp_multiplier'] as num?)?.toDouble() ?? 1.0;
    final endDate = challenge['end_date'] as String? ?? '';
    final progress = (challenge['user_progress'] as num?)?.toInt() ?? 0;
    final goalTarget = (challenge['goal_target'] as num?)?.toInt() ?? 1;
    final completed = challenge['completed'] as bool? ?? false;
    final pct = goalTarget > 0 ? (progress / goalTarget).clamp(0.0, 1.0) : 0.0;

    Color cardColor = _kPurple;
    if (multiplier > 1.0) cardColor = const Color(0xFFF5A623);
    if (completed) cardColor = _kGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kText,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.outfit(fontSize: 12, color: _kSub),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l.done,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (goalTarget > 1) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: cardColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(cardColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$progress / $goalTarget',
              style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (ptsReward > 0) _RewardChip('+$ptsReward Seeds', cardColor),
              if (coinReward > 0) _RewardChip('+$coinReward Seeds', _kGold),
              if (multiplier > 1.0)
                _RewardChip(
                  '${multiplier.toStringAsFixed(0)}× Seeds Boost',
                  Colors.orange,
                ),
              if (endDate.isNotEmpty)
                _RewardChip('Ends ${endDate.substring(0, 10)}', _kSub),
            ],
          ),
        ],
      ),
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
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

// ── Mini donut chart ──────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final Map<String, int> byType;
  final int total;
  _DonutPainter({required this.byType, required this.total});

  static const _colors = [
    Y4.butter,
    Color(0xFF4FC3F7),
    Color(0xFFAED581),
    Color(0xFFFF8A65),
    Color(0xFFCE93D8),
    Color(0xFF80CBC4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final innerR = r * 0.55;
    double startAngle = -math.pi / 2;
    int colorIdx = 0;

    for (final entry in byType.entries) {
      final sweep = 2 * math.pi * entry.value / total;
      final paint =
          Paint()
            ..color = _colors[colorIdx % _colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = r - innerR
            ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: (r + innerR) / 2),
        startAngle,
        sweep - 0.04,
        false,
        paint,
      );
      startAngle += sweep;
      colorIdx++;
    }

    // White centre circle
    canvas.drawCircle(
      Offset(cx, cy),
      innerR,
      Paint()..color = Colors.transparent,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.byType != byType;
}

// ── Breakdown chip ────────────────────────────────────────────────────────────
class _BreakdownChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final int pts;
  final Color color;
  const _BreakdownChip({
    required this.icon,
    required this.label,
    required this.pts,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              Text(
                '+$pts Seeds',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Individual activity row ───────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _ActivityRow(this.row);

  @override
  Widget build(BuildContext context) {
    final type = row['activity_type'] as String? ?? 'other';
    final pts = (row['points_earned'] as num?)?.toInt() ?? 0;
    final tsRaw = row['created_at'] as String? ?? '';
    final meta = _activityMeta(context, type);

    DateTime? ts;
    try {
      ts = DateTime.parse(tsRaw).toLocal();
    } catch (_) {}

    final timeStr =
        ts != null
            ? '${_pad(ts.hour)}:${_pad(ts.minute)}  ${ts.day}/${ts.month}/${ts.year}'
            : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meta.color.withValues(alpha: 0.1),
            ),
            child: Center(child: meta.icon),
          ),
          const SizedBox(width: 12),
          // Label + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: GoogleFonts.outfit(fontSize: 11, color: _kSub),
                  ),
              ],
            ),
          ),
          // pts badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+$pts Seeds',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: meta.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAKS TAB — embedded in Journey screen (formerly standalone StreakScreen)
// ─────────────────────────────────────────────────────────────────────────────
class _StreaksTab extends StatefulWidget {
  final StreakSnapshot? initialSnap;
  const _StreaksTab({this.initialSnap});
  @override
  State<_StreaksTab> createState() => _StreaksTabState();
}

class _StreaksTabState extends State<_StreaksTab>
    with TickerProviderStateMixin {
  late StreakSnapshot _snap;
  bool _loading = true;

  late AnimationController _flameCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _orbCtrl;
  late Animation<double> _flameScale;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _flameScale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.initialSnap != null) {
      // Data already loaded by parent — render immediately, no network call
      _snap = widget.initialSnap!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final snap = await StreakService.instance.loadSnapshot();
    if (mounted)
      setState(() {
        _snap = snap;
        _loading = false;
      });
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
    final l = AppLocalizations.of(context)!;
    final best = [
      _snap.login,
      _snap.dhikr,
      _snap.quran,
    ].reduce((a, b) => a > b ? a : b);
    final milestone = nextMilestone(best);
    final lastM = lastMilestone(best);

    return Container(
      color: Y4.bg, // honey wash, matches dashboard
      child: Stack(
        children: [
          // Animated aura background — softened for light theme
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _orbCtrl,
              builder:
                  (_, __) => CustomPaint(
                    painter: _StreakAuraPainter(phase: _orbCtrl.value),
                  ),
            ),
          ),
          if (_loading)
            Center(
              child: NoorInlineLoader(
                height: 120,
                color: Y4.honeyDeep,
                label: l.loadingStreaks,
              ),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: Column(
                children: [
                  // ── Hero flame ───────────────────────────────────────────────
                  _StreakHeroFlame(
                    streak: best,
                    flameScale: _flameScale,
                    pulse: _pulse,
                    milestone: lastM,
                  ),
                  const SizedBox(height: 24),

                  // ── 3 flame cards (Login / Dhikr / Quran) ───────────────────
                  Row(
                    children:
                        StreakType.values
                            .map(
                              (t) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: t == StreakType.login ? 0 : 6,
                                    right: t == StreakType.quran ? 0 : 6,
                                  ),
                                  child: _StreakFlameCard(
                                    type: t,
                                    streak: _snap.streakFor(t),
                                    best: _snap.bestFor(t),
                                    pulse: _pulse,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── 7-day calendar ───────────────────────────────────────────
                  _StreakCalendar(snap: _snap),
                  const SizedBox(height: 20),

                  // ── Milestone progress bar ───────────────────────────────────
                  if (milestone != null) ...[
                    _StreakMilestoneProgress(
                      current: best,
                      milestone: milestone,
                      lastM: lastM,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── All milestones ───────────────────────────────────────────
                  _StreakMilestoneList(streak: best),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Aura background painter ───────────────────────────────────────────────────
// On honey-wash bg we want a very subtle warm glow — not visible noise.
class _StreakAuraPainter extends CustomPainter {
  final double phase;
  const _StreakAuraPainter({required this.phase});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final p1 =
        Paint()
          ..shader = RadialGradient(
            colors: [Y4.honey.withValues(alpha: 0.30), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(cx, size.height * 0.25),
              radius: 240,
            ),
          );
    canvas.drawCircle(Offset(cx, size.height * 0.25), 240, p1);
    final ang = phase * 2 * math.pi;
    final p2 =
        Paint()
          ..shader = RadialGradient(
            colors: [Y4.butter.withValues(alpha: 0.25), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                cx + math.cos(ang) * 50,
                size.height * 0.32 + math.sin(ang) * 30,
              ),
              radius: 160,
            ),
          );
    canvas.drawCircle(
      Offset(cx + math.cos(ang) * 50, size.height * 0.32 + math.sin(ang) * 30),
      160,
      p2,
    );
  }

  @override
  bool shouldRepaint(_StreakAuraPainter o) => o.phase != phase;
}

// ── Hero flame widget ─────────────────────────────────────────────────────────
class _StreakHeroFlame extends StatelessWidget {
  final int streak;
  final Animation<double> flameScale, pulse;
  final StreakMilestone? milestone;
  const _StreakHeroFlame({
    required this.streak,
    required this.flameScale,
    required this.pulse,
    required this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([flameScale, pulse]),
      builder:
          (_, __) => Column(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Y4.honeyDeep.withValues(alpha: pulse.value * 0.4),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.scale(
                    scale: flameScale.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Y4.butter, Y4.honey, Y4.honeyDeep],
                          stops: [0.0, 0.55, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Y4.honeyDeep.withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NoorIcon.fire(size: 32),
                            Text(
                              '$streak',
                              style: GoogleFonts.rajdhani(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'day${streak == 1 ? '' : 's'}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                streak == 0
                    ? l.startStreak
                    : streak >= 100
                    ? l.centurion
                    : l.currentBestStreak,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Y4.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (streak > 0 && milestone != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Y4.honeyDeep, Y4.honey],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Next: ${milestone!.label} (${milestone!.days} days)',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}

// ── Flame card (one per streak type) ─────────────────────────────────────────
class _StreakFlameCard extends StatelessWidget {
  final StreakType type;
  final int streak, best;
  final Animation<double> pulse;
  const _StreakFlameCard({
    required this.type,
    required this.streak,
    required this.best,
    required this.pulse,
  });

  Color get _color => switch (type) {
    StreakType.login => Y4.honeyDeep,
    StreakType.dhikr => Y4.primary,
    StreakType.quran => const Color(
      0xFF6B5BA8,
    ), // muted plum that fits honey/sage
  };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder:
        (_, __) => Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Y4.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: streak > 0 ? _color.withValues(alpha: 0.5) : Y4.border,
            ),
            boxShadow:
                streak > 0
                    ? [
                      BoxShadow(
                        color: _color.withValues(alpha: pulse.value * 0.18),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Y4.ink.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Column(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                '$streak',
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: streak > 0 ? _color : Y4.muted,
                  height: 1.0,
                ),
              ),
              Text(
                'day${streak == 1 ? '' : 's'}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Y4.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Best $best',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: Y4.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
  );
}

// ── 7-day calendar ────────────────────────────────────────────────────────────
class _StreakCalendar extends StatelessWidget {
  final StreakSnapshot snap;
  const _StreakCalendar({required this.snap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - (6 - i)),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Y4.border),
        boxShadow: [
          BoxShadow(
            color: Y4.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.last7Days,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Y4.inkSoft,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children:
                days.map((day) {
                  final isToday =
                      day.day == today.day &&
                      day.month == today.month &&
                      day.year == today.year;
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          [
                            'Mo',
                            'Tu',
                            'We',
                            'Th',
                            'Fr',
                            'Sa',
                            'Su',
                          ][day.weekday - 1],
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Y4.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: isToday ? Y4.ink : Y4.inkSoft,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...StreakType.values.map((t) {
                          final on = snap
                              .historyFor(t)
                              .any(
                                (d) =>
                                    d.day == day.day &&
                                    d.month == day.month &&
                                    d.year == day.year,
                              );
                          final col = switch (t) {
                            StreakType.login => Y4.honeyDeep,
                            StreakType.dhikr => Y4.primary,
                            StreakType.quran => const Color(0xFF6B5BA8),
                          };
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    on ? col : Y4.ink.withValues(alpha: 0.10),
                                border:
                                    on
                                        ? null
                                        : Border.all(
                                          color: Y4.ink.withValues(alpha: 0.15),
                                          width: 0.5,
                                        ),
                                boxShadow:
                                    on
                                        ? [
                                          BoxShadow(
                                            color: col.withValues(alpha: 0.4),
                                            blurRadius: 5,
                                          ),
                                        ]
                                        : [],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                StreakType.values.map((t) {
                  final col = switch (t) {
                    StreakType.login => Y4.honeyDeep,
                    StreakType.dhikr => Y4.primary,
                    StreakType.quran => const Color(0xFF6B5BA8),
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.label,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Y4.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Milestone progress bar ────────────────────────────────────────────────────
class _StreakMilestoneProgress extends StatelessWidget {
  final int current;
  final StreakMilestone milestone;
  final StreakMilestone? lastM;
  const _StreakMilestoneProgress({
    required this.current,
    required this.milestone,
    required this.lastM,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final start = lastM?.days ?? 0;
    final pct = ((current - start) / (milestone.days - start)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Y4.border),
        boxShadow: [
          BoxShadow(
            color: Y4.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.nextMilestone,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Y4.inkSoft,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '+${milestone.ptsBonus} Seeds',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Y4.honeyDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Y4.ink,
                  ),
                ),
              ),
              Text(
                '$current / ${milestone.days} days',
                style: GoogleFonts.outfit(fontSize: 11, color: Y4.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder:
                (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: Y4.track,
                    valueColor: const AlwaysStoppedAnimation(Y4.honeyDeep),
                  ),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${milestone.days - current} more day${milestone.days - current == 1 ? '' : 's'} to go!',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Y4.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full milestone list ───────────────────────────────────────────────────────
class _StreakMilestoneList extends StatelessWidget {
  final int streak;
  const _StreakMilestoneList({required this.streak});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Y4.border),
        boxShadow: [
          BoxShadow(
            color: Y4.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.allMilestones,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Y4.inkSoft,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...kStreakMilestones.map((m) {
            final done = streak >= m.days;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          done
                              ? Y4.honeyDeep.withValues(alpha: 0.18)
                              : Y4.track,
                      border: Border.all(
                        color:
                            done
                                ? Y4.honeyDeep.withValues(alpha: 0.7)
                                : Y4.border,
                      ),
                      boxShadow:
                          done
                              ? [
                                BoxShadow(
                                  color: Y4.honeyDeep.withValues(alpha: 0.20),
                                  blurRadius: 10,
                                ),
                              ]
                              : [],
                    ),
                    child: Center(
                      child:
                          done
                              ? NoorIcon.fromEmoji(m.emoji, size: 17)
                              : NoorIcon.lock(size: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: done ? Y4.ink : Y4.muted,
                          ),
                        ),
                        Text(
                          '${m.days} day streak',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Y4.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: done ? Y4.honey.withValues(alpha: 0.20) : Y4.track,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${m.ptsBonus} Seeds',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: done ? Y4.honeyDeep : Y4.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
