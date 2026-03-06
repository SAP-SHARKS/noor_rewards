// lib/screens/impact_report_screen.dart
//
// Akhirah Balance — a premium Islamic banking-style dashboard showing
// the user's spiritual portfolio: deeds, streaks, and earnings.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/streak_service.dart';
import '../services/donation_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF0F4F0);
  static const darkGreen  = Color(0xFF0D2B1F);
  static const teal       = Color(0xFF2BAE99);
  static const gold       = Color(0xFFD4AF37);
  static const card       = Colors.white;
  static const text       = Color(0xFF1C1C1E);
  static const sub        = Color(0xFF8E8E93);
  static const border     = Color(0xFFE8E8EC);
  static const rose       = Color(0xFFE05C6A);
  static const purple     = Color(0xFF6B4EBB);
}

class ImpactReportScreen extends StatefulWidget {
  final bool isTab;
  const ImpactReportScreen({super.key, this.isTab = false});
  @override State<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends State<ImpactReportScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;

  // Profile
  int    _totalXp     = 0;
  int    _noorPoints  = 0;
  int    _level       = 1;
  String _levelTitle  = 'Seeker';

  // Activity
  int _totalDonated   = 0;
  int _todayPoints    = 0;
  int _weekPoints     = 0;
  int _sessionSec     = 0;

  // Streaks
  StreakSnapshot _snap = StreakSnapshot.empty;

  // Derived "Akhirah holdings" — computed from points/xp
  // Trees planted = every 100 noor points = 1 tree (symbolic)
  // Total Dhikr   = dhikr streak * 33 repetitions per day (symbolic)
  // Slaves freed  = every 1000 xp = 1 equivalent reward

  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }

    try {
      final results = await Future.wait<dynamic>([
        _sb.from('profiles')
            .select('display_name, total_xp, level, noor_points')
            .eq('id', uid)
            .maybeSingle(),
        _sb.from('user_analytics')
            .select('session_duration_sec, noor_coins_earned')
            .eq('user_id', uid)
            .maybeSingle(),
        DonationService.instance.getUserTotalDonations(),
        _sb.rpc('get_today_points'),
        _sb.rpc('get_week_points'),
        StreakService.instance.loadSnapshot(),
      ]);

      final profile   = results[0] as Map<String, dynamic>?;
      final analytics = results[1] as Map<String, dynamic>?;

      _totalXp     = (profile?['total_xp']    as num?)?.toInt() ?? 0;
      _level       = (profile?['level']       as num?)?.toInt() ?? 1;
      _noorPoints  = (profile?['noor_points'] as num?)?.toInt() ?? 0;
      _totalDonated = results[2] as int;
      _todayPoints  = (results[3] as num?)?.toInt() ?? 0;
      _weekPoints   = (results[4] as num?)?.toInt() ?? 0;
      _sessionSec   = (analytics?['session_duration_sec'] as num?)?.toInt() ?? 0;
      _snap         = results[5] as StreakSnapshot;

      // Level title from xp_levels
      try {
        final lv = await _sb.from('xp_levels')
            .select('title').eq('level', _level).maybeSingle();
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
    if (lv >= 6)  return 'Believer';
    return 'Seeker';
  }

  // ── Derived spiritual holdings ─────────────────────────────────────────────
  int get _treesPlanted   => math.max(1, _noorPoints ~/ 100);
  int get _totalDhikr     => (_snap.dhikr * 33) + (_snap.quran * 20) + (_snap.login * 10);
  int get _slavesFreed    => math.max(0, _totalXp ~/ 1000);
  int get _bestStreak     => [_snap.bestLogin, _snap.bestDhikr, _snap.bestQuran]
                                .reduce((a, b) => a > b ? a : b);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.teal))
          : FadeTransition(
              opacity: _fade,
              child: CustomScrollView(
                slivers: [
                  _buildHero(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                    sliver: SliverList(delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildStreakBanner(),
                      const SizedBox(height: 20),
                      _buildMiniStats(),
                      const SizedBox(height: 24),
                      _buildHoldingsSection(),
                      const SizedBox(height: 24),
                      _buildStreakDetailCards(),
                      const SizedBox(height: 24),
                      _buildActivityCard(),
                      const SizedBox(height: 24),
                      _buildRewardsCard(),
                      const SizedBox(height: 30),
                    ])),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Hero / Balance Card ────────────────────────────────────────────────────
  Widget _buildHero() => SliverToBoxAdapter(
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2318), Color(0xFF133828), Color(0xFF1A4731)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative arcs
            Positioned(top: -40, right: -40,
                child: _Arc(160, Colors.white.withValues(alpha: 0.04))),
            Positioned(bottom: -20, left: -30,
                child: _Arc(120, Colors.white.withValues(alpha: 0.03))),
            Positioned(top: 30, right: 30,
                child: _Arc(60, _C.gold.withValues(alpha: 0.08))),

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Top bar
                Row(children: [
                  if (!widget.isTab)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                  if (!widget.isTab) const Spacer(),
                  if (widget.isTab)
                    Text('Akhirah Balance',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _C.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.gold.withValues(alpha: 0.4))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: _C.gold, size: 14),
                      const SizedBox(width: 5),
                      Text('Lvl $_level · $_levelTitle',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: _C.gold)),
                    ]),
                  ),
                ]),

                const SizedBox(height: 24),

                // Label
                Text('AKHIRAH BALANCE',
                    style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white38, letterSpacing: 1.6)),
                const SizedBox(height: 6),

                // Main value
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Priceless',
                      style: GoogleFonts.outfit(
                          fontSize: 42, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.0)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _C.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.trending_up_rounded,
                            color: _C.teal, size: 13),
                        const SizedBox(width: 3),
                        Text('+${_todayPoints > 0 ? _todayPoints : 0} today',
                            style: GoogleFonts.outfit(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: _C.teal)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('Beyond what the world can hold',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.white54, fontStyle: FontStyle.italic)),

                const SizedBox(height: 22),

                // Today / this week badges
                Wrap(spacing: 10, runSpacing: 8, children: [
                  _HeroBadge('🌅', '+${_fmt(_todayPoints)} deeds today',
                      _C.teal.withValues(alpha: 0.25), _C.teal),
                  _HeroBadge('📅', '+${_fmt(_weekPoints)} this week',
                      Colors.white.withValues(alpha: 0.1), Colors.white70),
                  if (_bestStreak > 0)
                    _HeroBadge('🔥', 'Best: $_bestStreak day streak',
                        _C.gold.withValues(alpha: 0.15), _C.gold),
                ]),

                const SizedBox(height: 18),

                // Donate More & Earn button
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _CommunityImpactPage())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🌍', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Donate More & Earn',
                          style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 13),
                    ]),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Streak Banner ──────────────────────────────────────────────────────────
  Widget _buildStreakBanner() {
    final best = _bestStreak;
    final current = _snap.login;
    if (current == 0 && best == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.gold.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(
            color: _C.gold.withValues(alpha: 0.12),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$current Day Streak',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w900, color: _C.text)),
          Text('Keep it going — consistency is key!',
              style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Best', style: GoogleFonts.outfit(fontSize: 10, color: _C.sub)),
          Text('$best 🏆', style: GoogleFonts.outfit(
              fontSize: 15, fontWeight: FontWeight.w800, color: _C.gold)),
        ]),
      ]),
    );
  }

  // ── Mini stat pills ────────────────────────────────────────────────────────
  Widget _buildMiniStats() => Row(children: [
    Expanded(child: _MiniStat('🌳', _fmt(_treesPlanted), 'TREES', const Color(0xFF2D7A45))),
    const SizedBox(width: 10),
    Expanded(child: _MiniStat('📿', _fmt(_totalDhikr), 'DHIKR', _C.teal)),
    const SizedBox(width: 10),
    Expanded(child: _MiniStat('🛡️', _fmt(_slavesFreed), 'PROTECTED', _C.purple)),
  ]);

  // ── Your Holdings ──────────────────────────────────────────────────────────
  Widget _buildHoldingsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Your Holdings',
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w900, color: _C.text)),
        Text('See All →',
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w700, color: _C.teal)),
      ]),
      const SizedBox(height: 14),
      _buildHoldingsCard(),
    ],
  );

  Widget _buildHoldingsCard() => Container(
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(children: [
      _HoldingRow(
        emoji: '🌳',
        color: const Color(0xFF2D7A45),
        bgColor: const Color(0xFFE8F5EC),
        title: 'Trees in Jannah',
        subtitle: 'Planted in Paradise',
        value: _fmt(_treesPlanted),
        change: '+${math.max(0, _todayPoints ~/ 100)} today',
        positive: true,
        isFirst: true,
        isLast: false,
      ),
      const Divider(height: 1, indent: 70, endIndent: 20),
      _HoldingRow(
        emoji: '📿',
        color: _C.teal,
        bgColor: const Color(0xFFE0F7F4),
        title: 'Total Dhikr',
        subtitle: 'Remembrances of Allah',
        value: _fmt(_totalDhikr),
        change: '+${_snap.dhikr > 0 ? _snap.dhikr * 33 : 0} today',
        positive: true,
        isFirst: false,
        isLast: false,
      ),
      const Divider(height: 1, indent: 70, endIndent: 20),
      _HoldingRow(
        emoji: '⛓️',
        color: _C.purple,
        bgColor: const Color(0xFFEEEAF8),
        title: 'Slaves Freed',
        subtitle: 'Equivalent reward earned',
        value: _fmt(_slavesFreed),
        change: '+${_totalXp ~/ 2000} this week',
        positive: true,
        isFirst: false,
        isLast: false,
      ),
      const Divider(height: 1, indent: 70, endIndent: 20),
      _HoldingRow(
        emoji: '🤲',
        color: _C.gold,
        bgColor: const Color(0xFFFDF6E3),
        title: 'Sadaqah Given',
        subtitle: 'Points donated to community',
        value: _fmt(_totalDonated),
        change: 'All time',
        positive: true,
        isFirst: false,
        isLast: true,
      ),
    ]),
  );

  // ── Streak detail cards ────────────────────────────────────────────────────
  Widget _buildStreakDetailCards() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Streak Portfolio',
          style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w900, color: _C.text)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _StreakCard('☀️', 'Daily Login', _snap.login,
            _snap.bestLogin, const Color(0xFFFF9500))),
        const SizedBox(width: 10),
        Expanded(child: _StreakCard('📿', 'Dhikr', _snap.dhikr,
            _snap.bestDhikr, _C.teal)),
        const SizedBox(width: 10),
        Expanded(child: _StreakCard('📖', 'Quran', _snap.quran,
            _snap.bestQuran, _C.purple)),
      ]),
    ],
  );

  // ── Activity card (session time) ───────────────────────────────────────────
  Widget _buildActivityCard() {
    final hours = _sessionSec ~/ 3600;
    final mins  = (_sessionSec % 3600) ~/ 60;
    // Mock weekly bars using streak history length as proxy
    final days  = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Use week points as basis for the current bar, rest are illustrative
    final weekRatio = math.min(1.0, _weekPoints / math.max(1, 700));
    final bars = [0.3, 0.5, weekRatio * 0.7, 0.8, 1.0, weekRatio, 0.4];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: _C.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.show_chart_rounded, color: _C.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Worship Activity',
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _C.text)),
            Text('Time spent in remembrance',
                style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
          ]),
          const Spacer(),
          RichText(text: TextSpan(children: [
            TextSpan(text: '${hours}h ',
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _C.teal)),
            TextSpan(text: '${mins}m',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _C.sub)),
          ])),
        ]),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) => _DayBar(days[i], bars[i],
              highlight: i == 4)), // Friday highlighted
        ),
      ]),
    );
  }

  // ── Rewards card ──────────────────────────────────────────────────────────
  Widget _buildRewardsCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D2B1F), Color(0xFF1A4731)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: _C.darkGreen.withValues(alpha: 0.4),
          blurRadius: 20, offset: const Offset(0, 6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('✨', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text('Noor Points Summary',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _DarkStat('Total Points', _fmt(_noorPoints), '🌟')),
        Container(height: 44, width: 1, color: Colors.white12),
        Expanded(child: _DarkStat('Total XP', _fmt(_totalXp), '⚡')),
        Container(height: 44, width: 1, color: Colors.white12),
        Expanded(child: _DarkStat('Level', '$_level', '🏅')),
      ]),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _C.teal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.teal.withValues(alpha: 0.3)),
        ),
        child: Center(child: Text(
          '🌙  Every deed is recorded. Keep going!',
          style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: Colors.white70),
        )),
      ),
    ]),
  );

  // ── Community impact entry card (only shown when isTab) ─────────────────────

  Widget _buildCommunityCard(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const _CommunityImpactPage())),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A4A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        const Text('🌍', style: TextStyle(fontSize: 30)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Community Impact',
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          Text('See projects your Noor Points support',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 16),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Community Impact Page (previously embedded _ImpactTab)
// Navigated to from the Akhirah Balance tab
// ─────────────────────────────────────────────────────────────────────────────
class _CommunityImpactPage extends StatefulWidget {
  const _CommunityImpactPage();
  @override State<_CommunityImpactPage> createState() => _CommunityImpactPageState();
}

class _CommunityImpactPageState extends State<_CommunityImpactPage> {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final sb = Supabase.instance.client;
      final res = await sb.from('community_projects').select().order('sort_order');
      _projects = List<Map<String, dynamic>>.from(res);
      final dRes = await sb.from('user_donations').select('project_id, points_donated');
      final Map<String, int> sums = {};
      for (final d in dRes as List) {
        final pid = d['project_id'] as String;
        sums[pid] = (sums[pid] ?? 0) + ((d['points_donated'] as num?)?.toInt() ?? 0);
      }
      for (var p in _projects) {
        final real = sums[p['id']] ?? 0;
        p['current_points'] = real;
        p['is_completed'] = real >= ((p['target_points'] as num?)?.toInt() ?? 1);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(num n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.darkGreen,
        foregroundColor: Colors.white,
        title: Text('Community Impact',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.teal))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final p = _projects[i];
                final cur = (p['current_points'] as num?)?.toInt() ?? 0;
                final tgt = (p['target_points']  as num?)?.toInt() ?? 1;
                final pct = (cur / tgt).clamp(0.0, 1.0);
                final done = p['is_completed'] == true;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
                    border: done
                        ? Border.all(color: _C.gold.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(p['emoji'] ?? '🌍',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${p['title']}',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w800, color: _C.text))),
                      if (done)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: _C.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('✅ Done',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: _C.gold)),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Text('${p['description'] ?? ''}',
                        style: GoogleFonts.outfit(fontSize: 13, color: _C.sub)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: _C.teal.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(done ? _C.gold : _C.teal),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${_fmt(cur)} / ${_fmt(tgt)} points',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _C.sub)),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: done ? _C.gold : _C.teal)),
                    ]),
                  ]),
                );
              },
            ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────

class _Arc extends StatelessWidget {
  final double size;
  final Color color;
  const _Arc(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _HeroBadge extends StatelessWidget {
  final String emoji, label;
  final Color bg, fg;
  const _HeroBadge(this.emoji, this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.outfit(
              fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _MiniStat(this.emoji, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 6),
      Text(value,
          style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(label,
          style: GoogleFonts.outfit(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: _C.sub, letterSpacing: 0.8)),
    ]),
  );
}

class _HoldingRow extends StatelessWidget {
  final String emoji, title, subtitle, value, change;
  final Color color, bgColor;
  final bool positive, isFirst, isLast;
  const _HoldingRow({
    required this.emoji, required this.color, required this.bgColor,
    required this.title, required this.subtitle,
    required this.value, required this.change,
    required this.positive, required this.isFirst, required this.isLast,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
        Text(subtitle,
            style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w900, color: _C.text)),
        Text(change,
            style: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: positive ? const Color(0xFF2D7A45) : _C.rose)),
      ]),
    ]),
  );
}

class _StreakCard extends StatelessWidget {
  final String emoji, label;
  final int current, best;
  final Color color;
  const _StreakCard(this.emoji, this.label, this.current, this.best, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 6),
      Text('$current',
          style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text('days', style: GoogleFonts.outfit(fontSize: 10, color: _C.sub)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text('Best $best',
            style: GoogleFonts.outfit(
                fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.outfit(fontSize: 10, color: _C.sub),
          textAlign: TextAlign.center),
    ]),
  );
}

class _DarkStat extends StatelessWidget {
  final String label, value, emoji;
  const _DarkStat(this.label, this.value, this.emoji);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 4),
    Text(value,
        style: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
    Text(label,
        style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38),
        textAlign: TextAlign.center),
  ]);
}

class _DayBar extends StatelessWidget {
  final String day;
  final double value;
  final bool highlight;
  const _DayBar(this.day, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    const maxH = 64.0;
    return Expanded(child: Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        height: (value * maxH).clamp(4.0, maxH),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: highlight
                ? [const Color(0xFFF59E0B), const Color(0xFFD4783A)]
                : [_C.teal.withValues(alpha: 0.7), _C.teal],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      const SizedBox(height: 5),
      Text(day, style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          color: highlight ? _C.gold : _C.sub)),
    ]));
  }
}
