// lib/screens/impact_report_screen.dart
//
// User-facing "Your Impact" screen — shows personal analytics stats
// in a beautiful, read-only format.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFFF7F3EE);
  static const card    = Colors.white;
  static const text    = Color(0xFF1C1C1E);
  static const sub     = Color(0xFF8E8E93);
  static const teal    = Color(0xFF2BAE99);
  static const purple  = Color(0xFF6B4EBB);
  static const gold    = Color(0xFFF59E0B);
  static const rose    = Color(0xFFE05C6A);
  static const border  = Color(0xFFE8E8EC);
}

class ImpactReportScreen extends StatefulWidget {
  const ImpactReportScreen({super.key});
  @override State<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends State<ImpactReportScreen>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _load();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }

    try {
      final results = await Future.wait([
        _sb.from('user_analytics')
            .select('country_code, device_model, session_duration_sec, noor_coins_earned, last_active_at')
            .eq('user_id', uid)
            .maybeSingle(),
        _sb.from('profiles')
            .select('display_name, total_xp, level, noor_points')
            .eq('id', uid)
            .maybeSingle(),
      ]);
      _analytics = results[0] as Map<String, dynamic>?;
      _profile   = results[1] as Map<String, dynamic>?;
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _C.teal)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _buildHeroStats(),
                const SizedBox(height: 24),
                _buildSessionCard(),
                const SizedBox(height: 16),
                _buildDeviceCard(),
                const SizedBox(height: 16),
                _buildWeeklyRhythmCard(),
                const SizedBox(height: 16),
                _buildPrivacyNote(),
              ])),
            ),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() => SliverAppBar(
    expandedHeight: 180,
    pinned: true,
    backgroundColor: _C.teal,
    automaticallyImplyLeading: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A9E8C), Color(0xFF2BAE99), Color(0xFF38C8AF)],
          ),
        ),
        child: Stack(children: [
          // Decorative circles
          Positioned(top: -30, right: -30,
            child: _Circle(100, Colors.white.withValues(alpha: 0.07))),
          Positioned(bottom: -20, left: -20,
            child: _Circle(80, Colors.white.withValues(alpha: 0.05))),
          Positioned(bottom: 20, right: 60,
            child: _Circle(40, Colors.white.withValues(alpha: 0.08))),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Impact', style: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('A private view of your worship journey',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
            ]),
          ),
        ]),
      ),
    ),
  );

  // ── Hero stats row ─────────────────────────────────────────────────────────
  Widget _buildHeroStats() {
    final xp     = (_profile?['total_xp'] as num?)?.toInt() ?? 0;
    final coins  = (_analytics?['noor_coins_earned'] as num?)?.toInt() ?? 0;
    final level  = (_profile?['level'] as num?)?.toInt() ?? 1;

    return Row(children: [
      Expanded(child: _HeroTile('⭐', 'Total XP', _fmt(xp), _C.purple)),
      const SizedBox(width: 12),
      Expanded(child: _HeroTile('🪙', 'Coins Earned', _fmt(coins), _C.gold)),
      const SizedBox(width: 12),
      Expanded(child: _HeroTile('📈', 'Level', '$level', _C.rose)),
    ]);
  }

  // ── Session time card ──────────────────────────────────────────────────────
  Widget _buildSessionCard() {
    final totalSec  = (_analytics?['session_duration_sec'] as num?)?.toInt() ?? 0;
    final hours     = totalSec ~/ 3600;
    final mins      = (totalSec % 3600) ~/ 60;
    final weekSec   = math.min<int>(totalSec, 7 * 24 * 3600);
    final weekMins  = weekSec ~/ 60;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('⏱️', 'Time in Worship'),
        const SizedBox(height: 20),
        Row(children: [
          _BigStat('$hours', 'hrs total'),
          const SizedBox(width: 32),
          _BigStat('$mins', 'min remainder'),
        ]),
        const SizedBox(height: 20),
        // Progress bar (this week estimate)
        _label('This week'),
        const SizedBox(height: 8),
        _ProgressBar(
          value: math.min(1.0, weekMins / (7 * 60.0)),  // up to 7hr/week = 100%
          label: '$weekMins min',
          color: _C.teal,
        ),
        const SizedBox(height: 8),
        Text('🕌  Keep it up! Consistent worship builds lasting habits.',
            style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
      ]),
    );
  }

  // ── Device card ───────────────────────────────────────────────────────────
  Widget _buildDeviceCard() {
    final model   = _analytics?['device_model'] as String? ?? '—';
    final country = _analytics?['country_code'] as String? ?? '—';
    final lastActive = _analytics?['last_active_at'] as String?;
    final lastFmt = lastActive != null
        ? _fmtDate(DateTime.tryParse(lastActive))
        : '—';

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('📱', 'Device & Location'),
        const SizedBox(height: 16),
        _InfoRow(Icons.phone_android_rounded, 'Device', model, _C.purple),
        const Divider(height: 20),
        _InfoRow(Icons.public_rounded, 'Country', country, _C.teal),
        const Divider(height: 20),
        _InfoRow(Icons.access_time_rounded, 'Last Active', lastFmt, _C.gold),
      ]),
    );
  }

  // ── Weekly rhythm card ────────────────────────────────────────────────────
  Widget _buildWeeklyRhythmCard() {
    // Mock day bars (replace with real per-day data when available)
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Placeholder values — in production populate from a daily_activity table
    final vals = [0.5, 0.8, 0.3, 1.0, 0.9, 0.6, 0.4];

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('📅', 'Weekly Rhythm'),
        const SizedBox(height: 8),
        Text('Your relative activity each day this week',
            style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) => _DayBar(days[i], vals[i],
              highlight: i == 3)), // Friday highlight
        ),
      ]),
    );
  }

  // ── Privacy note ───────────────────────────────────────────────────────────
  Widget _buildPrivacyNote() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _C.teal.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.teal.withValues(alpha: 0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.lock_outline_rounded, color: _C.teal, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Privacy First', style: GoogleFonts.outfit(
            fontSize: 13, fontWeight: FontWeight.w700, color: _C.teal)),
        const SizedBox(height: 4),
        Text(
          'We never store your IP address or GPS location. '
          'Country is derived anonymously from your network region. '
          'This data is used only to generate sponsor impact reports.',
          style: GoogleFonts.outfit(fontSize: 12, color: _C.sub),
        ),
      ])),
    ]),
  );

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _C.sub));
}

// ═════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════════

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
    ),
    child: child,
  );
}

class _CardTitle extends StatelessWidget {
  final String emoji, title;
  const _CardTitle(this.emoji, this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w800, color: _C.text)),
  ]);
}

class _HeroTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _HeroTile(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
    ]),
  );
}

class _BigStat extends StatelessWidget {
  final String value, label;
  const _BigStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: GoogleFonts.outfit(
        fontSize: 36, fontWeight: FontWeight.w900, color: _C.teal)),
    Text(label, style: GoogleFonts.outfit(fontSize: 12, color: _C.sub)),
  ]);
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _ProgressBar({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      )),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.outfit(
          fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    ),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: _C.sub)),
      Text(value, style: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w700, color: _C.text)),
    ]),
  ]);
}

class _DayBar extends StatelessWidget {
  final String day;
  final double value;
  final bool highlight;
  const _DayBar(this.day, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    const maxH = 80.0;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        width: 32,
        height: (value * maxH).clamp(6.0, maxH),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: highlight
                ? [const Color(0xFFF59E0B), const Color(0xFFD4783A)]
                : [_C.teal.withValues(alpha: 0.8), _C.teal],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(height: 6),
      Text(day, style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          color: highlight ? _C.gold : _C.sub)),
    ]);
  }
}
