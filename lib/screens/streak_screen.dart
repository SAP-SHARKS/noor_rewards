// lib/screens/streak_screen.dart
// Full-page streak showcase — Y4 honey/cream light theme.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/streak_service.dart';
import '../theme/y4_theme.dart';
import '../widgets/noor_icons.dart';
import '../widgets/noor_offline.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});
  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with TickerProviderStateMixin {

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
    _flameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _flameScale = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut));
    _pulse = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

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
    final best = [_snap.login, _snap.dhikr, _snap.quran]
        .reduce((a, b) => a > b ? a : b);
    final milestone = nextMilestone(best);
    final lastM     = lastMilestone(best);

    return Scaffold(
      backgroundColor: Y4.bg,
      body: Stack(children: [
        // ── Subtle honey aura (light version) ─────────────────────────────
        Positioned.fill(child: AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) => CustomPaint(
            painter: _AuraPainter(phase: _orbCtrl.value),
          ),
        )),

        SafeArea(child: Column(children: [
          // ── App bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Y4.ink, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: Text('YOUR STREAKS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Y4.ink, letterSpacing: 1.5))),
              const SizedBox(width: 44),
            ]),
          ),

          Expanded(child: _loading
              ? const NoorInlineLoader(
                  height: double.infinity,
                  color: Y4.honeyDeep,
                  label: 'Loading streaks…',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(children: [
                    // ── Hero flame ───────────────────────────────────────
                    _HeroFlame(
                      streak: best,
                      flameScale: _flameScale,
                      pulse: _pulse,
                      milestone: lastM,
                    ),
                    const SizedBox(height: 28),

                    // ── 3 flame cards ─────────────────────────────────────
                    Row(children: StreakType.values.map((t) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left:  t == StreakType.login  ? 0 : 6,
                          right: t == StreakType.quran  ? 0 : 6,
                        ),
                        child: _FlameCard(
                          type: t,
                          streak: _snap.streakFor(t),
                          best:   _snap.bestFor(t),
                          pulse:  _pulse,
                        ),
                      ),
                    )).toList()),
                    const SizedBox(height: 24),

                    // ── 7-day calendar ────────────────────────────────────
                    _SevenDayCalendar(snap: _snap),
                    const SizedBox(height: 24),

                    // ── Milestone progress ────────────────────────────────
                    if (milestone != null)
                      _MilestoneProgress(
                        current:   best,
                        milestone: milestone,
                        lastM:     lastM,
                      ),
                    const SizedBox(height: 24),

                    // ── All milestones list ───────────────────────────────
                    _MilestoneList(streak: best),
                  ]),
                )),
        ])),
      ]),
    );
  }
}

// ── Background aura painter — light honey version ─────────────────────────────
class _AuraPainter extends CustomPainter {
  final double phase;
  const _AuraPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final p1 = Paint()
      ..shader = RadialGradient(colors: [
        Y4.honey.withValues(alpha: 0.20),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
          center: Offset(cx, size.height * 0.25), radius: 260));
    canvas.drawCircle(Offset(cx, size.height * 0.25), 260, p1);

    final ang = phase * 2 * math.pi;
    final ox  = math.cos(ang) * 60;
    final oy  = math.sin(ang) * 40;
    final p2 = Paint()
      ..shader = RadialGradient(colors: [
        Y4.amberY.withValues(alpha: 0.10),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(
          center: Offset(cx + ox, size.height * 0.32 + oy), radius: 180));
    canvas.drawCircle(Offset(cx + ox, size.height * 0.32 + oy), 180, p2);
  }

  @override bool shouldRepaint(_AuraPainter o) => o.phase != phase;
}

// ── Hero flame widget ─────────────────────────────────────────────────────────
class _HeroFlame extends StatelessWidget {
  final int streak;
  final Animation<double> flameScale, pulse;
  final StreakMilestone? milestone;
  const _HeroFlame({
    required this.streak, required this.flameScale,
    required this.pulse,  required this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    final label = milestone?.label ?? 'Legend';
    return AnimatedBuilder(
      animation: Listenable.merge([flameScale, pulse]),
      builder: (_, __) => Column(children: [
        // Outer glow ring
        Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Y4.honey.withValues(alpha: pulse.value * 0.35),
                blurRadius: 50, spreadRadius: 12,
              ),
            ],
          ),
          child: Center(child: Transform.scale(
            scale: flameScale.value,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFFE07A), Y4.honey, Y4.honeyDeep],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Y4.honeyDeep.withValues(alpha: 0.40),
                    blurRadius: 30, spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NoorIcon.fire(size: 36),
                  Text('$streak',
                      style: GoogleFonts.rajdhani(
                          fontSize: 38, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.0)),
                  Text('day${streak == 1 ? '' : 's'}',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ],
              )),
            ),
          )),
        ),
        const SizedBox(height: 14),
        Text(
          streak == 0
              ? 'Start your streak today!'
              : streak >= 100
                  ? 'Centurion — Masha\'Allah!'
                  : 'Current best streak',
          style: GoogleFonts.outfit(
              fontSize: 14, color: Y4.inkSoft,
              fontWeight: FontWeight.w500),
        ),
        if (streak > 0 && milestone != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Y4.amberY, Y4.honeyDeep]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Next: ${milestone!.label} (${milestone!.days} days)',
                style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.4)),
          ),
        ],
        if (streak >= 100) ...[
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.rajdhani(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: Y4.honeyDeep)),
        ],
      ]),
    );
  }
}

// ── Individual flame card (one per streak type) ───────────────────────────────
class _FlameCard extends StatelessWidget {
  final StreakType type;
  final int streak, best;
  final Animation<double> pulse;
  const _FlameCard({
    required this.type, required this.streak,
    required this.best, required this.pulse,
  });

  Color get _color {
    switch (type) {
      case StreakType.login:  return Y4.amberY;
      case StreakType.dhikr: return Y4.primary;
      case StreakType.quran: return const Color(0xFF5856D6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Y4.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: streak > 0
                ? _color.withValues(alpha: 0.35)
                : Y4.border,
          ),
          boxShadow: streak > 0 ? [
            BoxShadow(
              color: _color.withValues(alpha: pulse.value * 0.12),
              blurRadius: 16, spreadRadius: 2,
            ),
          ] : [],
        ),
        child: Column(children: [
          Text(type.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text('$streak',
              style: GoogleFonts.rajdhani(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: streak > 0 ? _color : Y4.muted,
                  height: 1.0)),
          Text('day${streak == 1 ? '' : 's'}',
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Y4.inkSoft,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Best $best',
                style: GoogleFonts.outfit(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _color)),
          ),
          const SizedBox(height: 6),
          Text(type.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Y4.inkSoft,
                  fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ── 7-day calendar ────────────────────────────────────────────────────────────
class _SevenDayCalendar extends StatelessWidget {
  final StreakSnapshot snap;
  const _SevenDayCalendar({required this.snap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) =>
        DateTime(today.year, today.month, today.day - (6 - i)));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Y4.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LAST 7 DAYS',
            style: GoogleFonts.rajdhani(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Y4.inkSoft, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        Row(children: days.map((day) {
          final isToday = day.day == today.day &&
              day.month == today.month && day.year == today.year;
          return Expanded(child: Column(children: [
            Text(
              ['Mo','Tu','We','Th','Fr','Sa','Su'][day.weekday - 1],
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Y4.muted,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('${day.day}',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isToday ? Y4.honeyDeep : Y4.inkSoft,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w400)),
            const SizedBox(height: 8),
            _DotRow(day: day, snap: snap),
          ]));
        }).toList()),
        const SizedBox(height: 16),
        // Legend
        Row(mainAxisAlignment: MainAxisAlignment.center,
            children: StreakType.values.map((t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(
                    color: _dotColor(t), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(t.label,
                style: GoogleFonts.outfit(
                    fontSize: 10, color: Y4.inkSoft)),
          ]),
        )).toList()),
      ]),
    );
  }

  Color _dotColor(StreakType t) {
    switch (t) {
      case StreakType.login:  return Y4.amberY;
      case StreakType.dhikr: return Y4.primary;
      case StreakType.quran: return const Color(0xFF5856D6);
    }
  }
}

class _DotRow extends StatelessWidget {
  final DateTime day;
  final StreakSnapshot snap;
  const _DotRow({required this.day, required this.snap});

  bool _active(StreakType t) => snap.historyFor(t).any((d) =>
      d.day == day.day && d.month == day.month && d.year == day.year);

  Color _col(StreakType t) {
    switch (t) {
      case StreakType.login:  return Y4.amberY;
      case StreakType.dhikr: return Y4.primary;
      case StreakType.quran: return const Color(0xFF5856D6);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: StreakType.values.map((t) {
      final on = _active(t);
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? _col(t) : Y4.track,
            boxShadow: on ? [BoxShadow(
                color: _col(t).withValues(alpha: 0.35), blurRadius: 6)] : [],
          ),
        ),
      );
    }).toList(),
  );
}

// ── Milestone progress bar ────────────────────────────────────────────────────
class _MilestoneProgress extends StatelessWidget {
  final int current;
  final StreakMilestone milestone;
  final StreakMilestone? lastM;
  const _MilestoneProgress({
    required this.current, required this.milestone, required this.lastM,
  });

  @override
  Widget build(BuildContext context) {
    final start = lastM?.days ?? 0;
    final end   = milestone.days;
    final pct   = ((current - start) / (end - start)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Y4.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('NEXT MILESTONE',
              style: GoogleFonts.rajdhani(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Y4.inkSoft, letterSpacing: 1.2)),
          const Spacer(),
          Text('+${milestone.ptsBonus} pts',
              style: GoogleFonts.rajdhani(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Y4.honeyDeep)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(milestone.label,
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Y4.ink))),
          Text('$current / ${milestone.days} days',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: Y4.inkSoft)),
        ]),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: v, minHeight: 12,
              backgroundColor: Y4.track,
              valueColor: const AlwaysStoppedAnimation(Y4.honeyDeep),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${milestone.days - current} more day${milestone.days - current == 1 ? '' : 's'} to go — keep it up!',
          style: GoogleFonts.outfit(
              fontSize: 12, color: Y4.inkSoft,
              fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}

// ── Full milestone list ───────────────────────────────────────────────────────
class _MilestoneList extends StatelessWidget {
  final int streak;
  const _MilestoneList({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Y4.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Y4.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALL MILESTONES',
            style: GoogleFonts.rajdhani(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Y4.inkSoft, letterSpacing: 1.2)),
        const SizedBox(height: 14),
        ...kStreakMilestones.map((m) {
          final done = streak >= m.days;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? Y4.honey.withValues(alpha: 0.20)
                      : Y4.track,
                  border: Border.all(
                    color: done
                        ? Y4.honeyDeep.withValues(alpha: 0.6)
                        : Y4.border,
                  ),
                  boxShadow: done ? [BoxShadow(
                      color: Y4.honey.withValues(alpha: 0.25),
                      blurRadius: 10)] : [],
                ),
                child: Center(child: done
                    ? NoorIcon.fromEmoji(m.emoji, size: 18)
                    : NoorIcon.lock(size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label,
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: done ? Y4.ink : Y4.muted)),
                  Text('${m.days} day streak',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: Y4.inkSoft)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: done
                      ? Y4.honey.withValues(alpha: 0.15)
                      : Y4.track,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+${m.ptsBonus} pts',
                    style: GoogleFonts.rajdhani(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: done ? Y4.honeyDeep : Y4.muted,
                        letterSpacing: 0.5)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
