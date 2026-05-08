// lib/screens/impact_report_screen.dart
//
// Akhirah Balance — a premium Islamic banking-style dashboard showing
// the user's spiritual portfolio: deeds, streaks, and earnings.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/streak_service.dart';
import '../services/donation_service.dart';
import '../widgets/noor_icons.dart';
import '../widgets/noor_offline.dart';
import '../widgets/project_media_carousel.dart';
import '../services/settings_service.dart';
import '../models/app_config.dart';
import '../theme/y4_theme.dart';

// ── Palette (reads from admin-controlled AppConfig) ─────────────────────────
AppConfig get _icfg => SettingsService.instance.config;

class _C {
  static Color get bg => _icfg.dashBg;
  static Color get darkGreen => _icfg.primaryColor;
  static Color get teal => _icfg.dashTeal;
  static Color get gold => _icfg.donationColor;
  static Color get card =>
      _icfg.dashBg.computeLuminance() > 0.5
          ? Colors.white
          : const Color(0xFF1F2937);
  static Color get text => _icfg.dashText;
  static Color get sub =>
      _icfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFF8E8E93)
          : const Color(0xFF9CA3AF);
  static Color get border =>
      _icfg.dashBg.computeLuminance() > 0.5
          ? const Color(0xFFE8E8EC)
          : const Color(0xFF374151);
  static Color get rose => const Color(0xFFE05C6A);
  static Color get purple => _icfg.secondaryColor;
}

class ImpactReportScreen extends StatefulWidget {
  final bool isTab;
  final int visitCount;
  const ImpactReportScreen({
    super.key,
    this.isTab = false,
    this.visitCount = 0,
  });
  @override
  State<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends State<ImpactReportScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;

  // Profile
  int _totalPts = 0;
  int _noorPoints = 0;
  int _level = 1;
  String _levelTitle = 'Seeker';

  // Activity
  int _totalDonated = 0;
  int _todayPoints = 0;
  int _weekPoints = 0;
  int _sessionSec = 0;

  // Streaks
  StreakSnapshot _snap = StreakSnapshot.empty;

  // Derived "Akhirah holdings" — computed from points
  // Trees planted = every 100 noor points = 1 tree (symbolic)
  // Total Dhikr   = dhikr streak * 33 repetitions per day (symbolic)
  // Slaves freed  = every 1000 points = 1 equivalent reward

  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _sb
            .from('profiles')
            .select('display_name, total_xp, level, noor_points')
            .eq('id', uid)
            .maybeSingle(),
        _sb
            .from('user_analytics')
            .select('session_duration_sec, noor_coins_earned')
            .eq('user_id', uid)
            .maybeSingle(),
        DonationService.instance.getUserTotalDonations(),
        _sb.rpc('get_today_points'),
        _sb.rpc('get_week_points'),
        StreakService.instance.loadSnapshot(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final analytics = results[1] as Map<String, dynamic>?;

      _totalPts = (profile?['total_xp'] as num?)?.toInt() ?? 0;
      _level = (profile?['level'] as num?)?.toInt() ?? 1;
      _noorPoints = (profile?['noor_points'] as num?)?.toInt() ?? 0;
      _totalDonated = results[2] as int;
      _todayPoints = (results[3] as num?)?.toInt() ?? 0;
      _weekPoints = (results[4] as num?)?.toInt() ?? 0;
      _sessionSec = (analytics?['session_duration_sec'] as num?)?.toInt() ?? 0;
      _snap = results[5] as StreakSnapshot;

      // Level title from xp_levels
      try {
        final lv =
            await _sb
                .from('xp_levels')
                .select('title')
                .eq('level', _level)
                .maybeSingle();
        _levelTitle = (lv?['title'] as String?) ?? _fallbackTitle(_level);
      } catch (_) {
        _levelTitle = _fallbackTitle(_level);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  String _fallbackTitle(int lv) {
    if (lv >= 51) return 'Legend';
    if (lv >= 21) return 'Champion';
    if (lv >= 11) return 'Devoted';
    if (lv >= 6) return 'Believer';
    return 'Seeker';
  }

  // ── Derived spiritual holdings ─────────────────────────────────────────────
  int get _hasanaat => _totalPts * 15 + _noorPoints * 5;
  int get _treesPlanted => (_snap.dhikr * 25) + (_snap.login * 2);
  int get _sinsWiped => (_snap.dhikr * 50) + (_snap.login * 5);
  int get _treasures => (_snap.dhikr * 5) + (_snap.quran * 2);
  int get _slavesFreed => _snap.dhikr * 2;
  int get _palacesBuilt => _snap.quran > 0 ? math.max(1, _snap.quran ~/ 3) : 0;
  int get _bestStreak => [
    _snap.bestLogin,
    _snap.bestDhikr,
    _snap.bestQuran,
  ].reduce((a, b) => a > b ? a : b);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body:
          _loading
              ? Center(
                child: NoorInlineLoader(
                  height: double.infinity,
                  label:
                      AppLocalizations.of(context)?.loadingYourReport ??
                      'Loading your report…',
                ),
              )
              : FadeTransition(
                opacity: _fade,
                child: CustomScrollView(
                  slivers: [
                    _buildHero(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 20),
                          _buildMiniStats(),
                          const SizedBox(height: 24),
                          _buildHoldingsSection(),
                          const SizedBox(height: 24),
                          _buildActivityCard(),
                          const SizedBox(height: 24),
                          _buildRewardsCard(),
                          const SizedBox(height: 30),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // ── Hero / Balance Card ────────────────────────────────────────────────────
  Widget _buildHero() => SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        // Honey wash hero matching dashboard aesthetic
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Y4.cream, Y4.honey.withValues(alpha: 0.30), Y4.bg],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative arcs (subtle honey/sage on light bg)
            Positioned(
              top: -40,
              right: -40,
              child: _Arc(160, Y4.honey.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -20,
              left: -30,
              child: _Arc(120, Y4.primary.withValues(alpha: 0.08)),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: _Arc(60, Y4.honeyDeep.withValues(alpha: 0.10)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      if (!widget.isTab)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Y4.ink,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32),
                        ),
                      if (!widget.isTab) const Spacer(),
                      if (widget.isTab)
                        Text(
                          AppLocalizations.of(context)?.akhirahBalance ??
                              'Akhirah Balance',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Y4.ink,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Y4.honey.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Y4.honeyDeep.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: Y4.honeyDeep,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Lvl $_level · $_levelTitle',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Y4.honeyDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Label
                  Text(
                    'AKHIRAH BALANCE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Y4.inkSoft,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Main value (Fraunces serif for "Priceless")
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.priceless ?? 'Priceless',
                        style: Y4.display(
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                          color: Y4.ink,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Y4.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: Y4.primaryDeep,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '+${_todayPoints > 0 ? _todayPoints : 0} today',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Y4.primaryDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)?.beyondWorldCanHold ??
                        'Beyond what the world can hold',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Y4.inkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Today / this week badges
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _HeroBadge(
                        NoorIcon.sunrise(size: 14),
                        '+${_fmt(_todayPoints)} deeds today',
                        Y4.primary.withValues(alpha: 0.18),
                        Y4.primaryDeep,
                      ),
                      _HeroBadge(
                        NoorIcon.calendar(size: 14),
                        '+${_fmt(_weekPoints)} this week',
                        Y4.honey.withValues(alpha: 0.30),
                        Y4.honeyDeep,
                      ),
                      if (_bestStreak > 0)
                        _HeroBadge(
                          NoorIcon.fire(size: 14),
                          'Best: $_bestStreak day streak',
                          Y4.honeyDeep.withValues(alpha: 0.18),
                          Y4.honeyDeep,
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommunityImpactPage(),
                          ),
                        ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Y4.honeyDeep,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Y4.honeyDeep.withValues(alpha: 0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NoorIcon.globe(size: 16),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.donateMoreEarn ??
                                'Donate More & Earn',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ],
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
  );

  // ── Mini stat pills ────────────────────────────────────────────────────────
  Widget _buildMiniStats() => Row(
    key: ValueKey(widget.visitCount),
    children: [
      Expanded(
        child: _MiniStat(NoorIcon.star(size: 20), _hasanaat, 'DEEDS', _C.gold),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _MiniStat(
          NoorIcon.tree(size: 20),
          _treesPlanted,
          'TREES',
          const Color(0xFF2D7A45),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _MiniStat(
          NoorIcon.drop(size: 20),
          _sinsWiped,
          'FORGIVEN',
          _C.teal,
        ),
      ),
    ],
  );

  // ── Your Holdings ──────────────────────────────────────────────────────────
  Widget _buildHoldingsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)?.yourHoldings ?? 'Your Holdings',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _C.text,
            ),
          ),
          Text(
            AppLocalizations.of(context)?.seeAll ?? 'See All →',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.teal,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _buildHoldingsCard(),
    ],
  );

  Widget _buildHoldingsCard() => Container(
    key: ValueKey(widget.visitCount),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _HoldingRow(
          icon: NoorIcon.sparkles(size: 24),
          color: _C.gold,
          bgColor: const Color(0xFFFDF6E3),
          title:
              AppLocalizations.of(context)?.hasanaatEarned ?? 'Hasanaat Earned',
          subtitle:
              AppLocalizations.of(context)?.recordedInBookOfDeeds ??
              'Recorded in your Book of Deeds',
          value: _hasanaat,
          change: '+${_todayPoints * 15} today',
          positive: true,
          isFirst: true,
          isLast: false,
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
        _HoldingRow(
          icon: NoorIcon.tree(size: 24),
          color: const Color(0xFF2D7A45),
          bgColor: const Color(0xFFE8F5EC),
          title:
              AppLocalizations.of(context)?.treesInJannah ?? 'Trees in Jannah',
          subtitle:
              AppLocalizations.of(context)?.fromTasbih ??
              'From SubhanAllah & Tasbih',
          value: _treesPlanted,
          change: '+${_snap.dhikr > 0 ? 25 : 0} today',
          positive: true,
          isFirst: false,
          isLast: false,
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
        _HoldingRow(
          icon: NoorIcon.drop(size: 24),
          color: _C.teal,
          bgColor: const Color(0xFFE0F7F4),
          title: AppLocalizations.of(context)?.sinsForgiven ?? 'Sins Forgiven',
          subtitle:
              AppLocalizations.of(context)?.likeTheFoamOfSea ??
              'Like the foam of the sea',
          value: _sinsWiped,
          change: '+${_snap.dhikr > 0 ? 50 : 0} today',
          positive: true,
          isFirst: false,
          isLast: false,
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
        _HoldingRow(
          icon: NoorIcon.mosque(size: 24),
          color: const Color(0xFF4A90E2),
          bgColor: const Color(0xFFEAF2F8),
          title: AppLocalizations.of(context)?.palacesBuilt ?? 'Palaces Built',
          subtitle:
              AppLocalizations.of(context)?.surahIkhlasAndSunnahs ??
              'Surah Ikhlas & Sunnahs',
          value: _palacesBuilt,
          change: '+${_snap.quran ~/ 3} total',
          positive: true,
          isFirst: false,
          isLast: false,
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
        _HoldingRow(
          icon: NoorIcon.diamond(size: 24),
          color: const Color(0xFF9B59B6),
          bgColor: const Color(0xFFF5EEF8),
          title:
              AppLocalizations.of(context)?.treasuresOfJannah ??
              'Treasures of Jannah',
          subtitle: 'La Hawla Wa La Quwwata',
          value: _treasures,
          change: '+${_snap.dhikr > 0 ? 5 : 0} today',
          positive: true,
          isFirst: false,
          isLast: false,
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
        _HoldingRow(
          icon: NoorIcon.chains(size: 24),
          color: _C.purple,
          bgColor: const Color(0xFFEEEAF8),
          title: AppLocalizations.of(context)?.slavesFreedom ?? 'Slaves Freed',
          subtitle:
              AppLocalizations.of(context)?.equivalentReward ??
              'Equivalent reward earned',
          value: _slavesFreed,
          change: '+${_snap.dhikr > 0 ? 2 : 0} today',
          positive: true,
          isFirst: false,
          isLast: false,
        ),
        const Divider(height: 1, indent: 70, endIndent: 20),
        _HoldingRow(
          icon: NoorIcon.hands(size: 24),
          color: const Color(0xFFE67E22),
          bgColor: const Color(0xFFFEF5E7),
          title: AppLocalizations.of(context)?.sadaqahGiven ?? 'Sadaqah Given',
          subtitle:
              AppLocalizations.of(context)?.pointsDonatedToCommunity ??
              'Points donated to community',
          value: _totalDonated,
          change: AppLocalizations.of(context)?.allTimeLabel ?? 'All time',
          positive: true,
          isFirst: false,
          isLast: true,
        ),
      ],
    ),
  );

  // ── Activity card (session time) ───────────────────────────────────────────
  Widget _buildActivityCard() {
    final hours = _sessionSec ~/ 3600;
    final mins = (_sessionSec % 3600) ~/ 60;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekRatio = math.min(1.0, _weekPoints / math.max(1, 700));
    final bars = [0.3, 0.5, weekRatio * 0.7, 0.8, 1.0, weekRatio, 0.4];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.show_chart_rounded, color: _C.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.worshipActivity ??
                        'Worship Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.text,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)?.timeSpentInRemembrance ??
                        'Time spent in remembrance',
                    style: GoogleFonts.outfit(fontSize: 11, color: _C.sub),
                  ),
                ],
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${hours}h ',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _C.teal,
                      ),
                    ),
                    TextSpan(
                      text: '${mins}m',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.sub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              7,
              (i) => _DayBar(days[i], bars[i], highlight: i == 4),
            ), // Friday highlighted
          ),
        ],
      ),
    );
  }

  // â”€â”€ Rewards card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildRewardsCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Y4.primaryDeep, Y4.primary],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _C.darkGreen.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NoorIcon.sparkles(size: 22),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)?.noorPointsSummary ??
                  'Noor Points Summary',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DarkStat(
                AppLocalizations.of(context)?.totalPoints ?? 'Total Points',
                _fmt(_noorPoints),
                NoorIcon.star(size: 16),
              ),
            ),
            Container(height: 44, width: 1, color: Colors.white12),
            Expanded(
              child: _DarkStat('Level', '$_level', NoorIcon.medal(size: 16)),
            ),
            Container(height: 44, width: 1, color: Colors.white12),
            Expanded(
              child: _DarkStat(
                AppLocalizations.of(context)?.title ?? 'Title',
                _levelTitle,
                NoorIcon.crown(size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _C.teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.teal.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              '🌙  Every deed is recorded. Keep going!',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ——————————————————————————————————————————————————————————————————————————
// Community Impact Page (previously embedded _ImpactTab)
// Navigated to from the Akhirah Balance tab
// ——————————————————————————————————————————————————————————————————————————
class CommunityImpactPage extends StatefulWidget {
  final String? scrollToProjectId;
  final bool isTab;
  const CommunityImpactPage({
    super.key,
    this.scrollToProjectId,
    this.isTab = false,
  });
  @override
  State<CommunityImpactPage> createState() => _CommunityImpactPageState();
}

class _CommunityImpactPageState extends State<CommunityImpactPage> {
  List<Map<String, dynamic>> _projects = [];
  Map<String, List<ProjectMedia>> _projectMedia = {};
  int _myAvailablePoints = 0;
  bool _loading = true;
  final Map<String, GlobalKey> _projectKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      // Load all projects
      final res = await sb
          .from('community_projects')
          .select()
          .order('sort_order', ascending: true, nullsFirst: false);
      _projects = List<Map<String, dynamic>>.from(res);

      // Community totals (all users)
      final dRes = await sb
          .from('user_donations')
          .select('project_id, points_donated');
      final Map<String, int> communityTotals = {};
      for (final d in dRes as List) {
        final pid = d['project_id'] as String;
        communityTotals[pid] =
            (communityTotals[pid] ?? 0) +
            ((d['points_donated'] as num?)?.toInt() ?? 0);
      }

      // My own donations per project
      Map<String, int> myDonations = {};
      if (uid != null) {
        final myRes = await sb
            .from('user_donations')
            .select('project_id, points_donated')
            .eq('user_id', uid);
        for (final d in myRes as List) {
          final pid = d['project_id'] as String;
          myDonations[pid] =
              (myDonations[pid] ?? 0) +
              ((d['points_donated'] as num?)?.toInt() ?? 0);
        }
        // Available points
        final profile =
            await sb
                .from('profiles')
                .select('noor_points')
                .eq('id', uid)
                .maybeSingle();
        _myAvailablePoints = (profile?['noor_points'] as num?)?.toInt() ?? 0;
      }

      for (var p in _projects) {
        final real = communityTotals[p['id']] ?? 0;
        p['current_points'] = real;
        p['my_points'] = myDonations[p['id']] ?? 0;
        p['is_completed'] =
            real >= ((p['target_points'] as num?)?.toInt() ?? 1);
      }

      final pids = _projects.map((p) => p['id'] as String).toList();
      _projectMedia = await DonationService.instance.getMediaForProjects(pids);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      // Scroll to specific project if requested
      if (widget.scrollToProjectId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _projectKeys[widget.scrollToProjectId];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: 0.1,
            );
          }
        });
      }
    }
  }

  String _fmt(num n) =>
      n >= 1000000
          ? '${(n / 1000000).toStringAsFixed(1)}M'
          : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)}k'
          : '$n';

  void _showDonateSheet(Map<String, dynamic> project) {
    int selected = 50;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    top: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${project['title'] ?? ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your available: ${_fmt(_myAvailablePoints)} pts',
                        style: GoogleFonts.outfit(fontSize: 13, color: _C.sub),
                      ),
                      const SizedBox(height: 20),
                      // Quick amount chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children:
                            [50, 100, 250, 500, 1000].map((amt) {
                              final sel = selected == amt;
                              return GestureDetector(
                                onTap: () => setLocal(() => selected = amt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel ? Y4.honeyDeep : _C.bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel ? Y4.honeyDeep : _C.border,
                                    ),
                                  ),
                                  child: Text(
                                    '$amt pts',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : _C.text,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Y4.butter, Y4.honey],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Y4.honeyDeep.withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Y4.ink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                _myAvailablePoints < selected
                                    ? null
                                    : () async {
                                      Navigator.pop(ctx);
                                      try {
                                        final sb = Supabase.instance.client;
                                        final uid = sb.auth.currentUser?.id;
                                        if (uid == null) return;
                                        await sb.rpc(
                                          'donate_to_project',
                                          params: {
                                            'p_user_id': uid,
                                            'p_project_id': project['id'],
                                            'p_amount': selected,
                                          },
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'JazakAllah! ${_fmt(selected)} pts donated 🤲',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              backgroundColor: Y4.honeyDeep,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                          setState(() => _loading = true);
                                          await _load();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed: $e'),
                                              backgroundColor: _C.rose,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            child: Text(
                              _myAvailablePoints < selected
                                  ? 'Insufficient Points'
                                  : 'Donate $selected Points 🤲',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Y4.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: Y4.honeyDeep,
        foregroundColor: Colors.white,
        title: Text(
          'Every Recitation Can\nChange a Life',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 14,
          ),
          maxLines: 2,
        ),
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: NoorInlineLoader())
              : ListView.separated(
                padding: EdgeInsets.only(bottom: widget.isTab ? 100 : 0),
                itemCount: _projects.length,
                separatorBuilder:
                    (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                itemBuilder: (ctx, i) {
                  final p = _projects[i];
                  final cur = (p['current_points'] as num?)?.toInt() ?? 0;
                  final tgt = (p['target_points'] as num?)?.toInt() ?? 1;
                  final myPts = (p['my_points'] as num?)?.toInt() ?? 0;
                  final pct = (cur / tgt).clamp(0.0, 1.0);
                  final myPct = (myPts / tgt).clamp(0.0, 1.0);
                  final done = p['is_completed'] == true;
                  final pid = p['id'] as String;
                  _projectKeys.putIfAbsent(pid, () => GlobalKey());
                  return Container(
                    key: _projectKeys[pid],
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            _ImpactProjectCover(project: p),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${p['title']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _C.text,
                                ),
                              ),
                            ),
                            if (done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _C.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '✅ Funded',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _C.gold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${p['description'] ?? ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A1A),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        if ((_projectMedia[p['id']] ?? []).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ProjectMediaCarousel(
                                media: _projectMedia[p['id']]!,
                                height: 180,
                              ),
                            ),
                          ),

                        // Community progress bar
                        Row(
                          children: [
                            Text(
                              'Community Progress',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.sub,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                '${_fmt(cur)} / ${_fmt(tgt)} pts  •  ${(pct * 100).toStringAsFixed(0)}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: done ? _C.gold : Y4.honeyDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 9,
                            backgroundColor: Y4.honey.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(
                              done ? _C.gold : Y4.honey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // My contribution row
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Y4.honey.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Y4.honey.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🤲',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        'My contribution: ${_fmt(myPts)} pts',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Y4.honeyDeep,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Donate button
                        if (!done)
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Y4.butter, Y4.honey],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Y4.honeyDeep.withValues(alpha: 0.30),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Y4.ink,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => _showDonateSheet(p),
                                icon: const Text(
                                  '🤲',
                                  style: TextStyle(fontSize: 14),
                                ),
                                label: Text(
                                  'Donate & Earn Reward',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Y4.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Arc extends StatelessWidget {
  final double size;
  final Color color;
  const _Arc(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _HeroBadge extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color bg, fg;
  const _HeroBadge(this.icon, this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final Widget icon;
  final String label;
  final int value;
  final Color color;
  const _MiniStat(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
      ],
    ),
    child: Column(
      children: [
        icon,
        const SizedBox(height: 6),
        _AnimatedNumText(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _C.sub,
            letterSpacing: 0.8,
          ),
        ),
      ],
    ),
  );
}

class _AnimatedNumText extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _AnimatedNumText(this.value, {required this.style});

  static String fmt(num n) =>
      n >= 1000000
          ? '${(n / 1000000).toStringAsFixed(1)}M'
          : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)}k'
          : n.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOutExpo,
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      builder: (context, val, child) {
        return Text(fmt(val), style: style);
      },
    );
  }
}

class _HoldingRow extends StatelessWidget {
  final Widget icon;
  final String title, subtitle, change;
  final int value;
  final Color color, bgColor;
  final bool positive, isFirst, isLast;
  const _HoldingRow({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.change,
    required this.positive,
    required this.isFirst,
    required this.isLast,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.text,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(fontSize: 11, color: _C.sub),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AnimatedNumText(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _C.text,
              ),
            ),
            Text(
              change,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: positive ? const Color(0xFF2D7A45) : _C.rose,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DarkStat extends StatelessWidget {
  final String label;
  final dynamic value;
  final Widget icon;
  const _DarkStat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      icon,
      const SizedBox(height: 4),
      value is int
          ? _AnimatedNumText(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          )
          : Text(
            value.toString(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
      Text(
        label,
        style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _DayBar extends StatelessWidget {
  final String day;
  final double value;
  final bool highlight;
  const _DayBar(this.day, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    const maxH = 64.0;
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            height: (value * maxH).clamp(4.0, maxH),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    highlight
                        ? [const Color(0xFFF59E0B), const Color(0xFFD4783A)]
                        : [_C.teal.withValues(alpha: 0.7), _C.teal],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            day,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              color: highlight ? _C.gold : _C.sub,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Project cover for impact-report list (loads first media item or explicit dp_url) ──
class _ImpactProjectCover extends StatefulWidget {
  final Map<String, dynamic> project;
  const _ImpactProjectCover({required this.project});

  @override
  State<_ImpactProjectCover> createState() => _ImpactProjectCoverState();
}

class _ImpactProjectCoverState extends State<_ImpactProjectCover> {
  static final Map<String, ProjectMedia?> _cache = {};
  ProjectMedia? _cover;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final dpUrl = widget.project['dp_url'] as String?;
    if (dpUrl != null && dpUrl.isNotEmpty) {
      _loading = false;
      return;
    }

    final projectId = widget.project['id'] as String;
    if (_cache.containsKey(projectId)) {
      _cover = _cache[projectId];
      _loading = false;
    } else {
      _load(projectId);
    }
  }

  Future<void> _load(String projectId) async {
    final list = await DonationService.instance.getProjectMedia(projectId);
    final cover = list.isNotEmpty ? list.first : null;
    _cache[projectId] = cover;
    if (!mounted) return;
    setState(() {
      _cover = cover;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double s = 48; // increased size for DP visibility
    final radius = BorderRadius.circular(12);

    final dpUrl = widget.project['dp_url'] as String?;
    if (dpUrl != null && dpUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: dpUrl,
          width: s,
          height: s,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallbackCover(s, radius),
        ),
      );
    }

    if (_loading) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F4),
          borderRadius: radius,
        ),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFC9921A),
              ),
            ),
          ),
        ),
      );
    }
    if (_cover == null) return _fallbackCover(s, radius);

    if (_cover!.isVideo) {
      return Container(
        width: s,
        height: s,
        decoration: BoxDecoration(color: Colors.black, borderRadius: radius),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: _cover!.url,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackCover(s, radius),
      ),
    );
  }

  Widget _fallbackCover(double s, BorderRadius r) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      color: Y4.honey.withValues(alpha: 0.12),
      borderRadius: r,
    ),
    child: Icon(
      Icons.volunteer_activism_rounded,
      size: 24,
      color: Y4.honeyDeep,
    ),
  );
}
