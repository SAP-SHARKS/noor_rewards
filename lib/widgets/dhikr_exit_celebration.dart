// lib/widgets/dhikr_exit_celebration.dart
//
// Dopamine moment shown when the user exits the Daily Dhikr flow after
// counting at least one zikr. Surfaces only ACCURATE values:
//   • Points earned during this session
//   • Current dhikr streak (days)
//
// No "trees planted in Jannah" / "sins forgiven" framing — points + streak
// only, in the Y4 honey + sage palette.

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/y4_theme.dart';
import 'sabiq_coin.dart';

/// Show the Dhikr-exit celebration. Awaits user dismissal (tap CTA, back, or
/// barrier tap). Caller is responsible for `Navigator.pop` after this returns.
Future<void> showDhikrExitCelebration(
  BuildContext context, {
  required int pointsEarned,
  required int streakDays,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dhikr_exit_celebration',
    barrierColor: Y4.palette.ink.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (ctx, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curve, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _DhikrExitCelebrationBody(
      pointsEarned: pointsEarned,
      streakDays: streakDays,
    ),
  );
}

class _DhikrExitCelebrationBody extends StatefulWidget {
  final int pointsEarned;
  final int streakDays;
  const _DhikrExitCelebrationBody({
    required this.pointsEarned,
    required this.streakDays,
  });

  @override
  State<_DhikrExitCelebrationBody> createState() =>
      _DhikrExitCelebrationBodyState();
}

class _DhikrExitCelebrationBodyState extends State<_DhikrExitCelebrationBody>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _ptsCtrl;
  late final Animation<int> _ptsAnim;
  late final AnimationController _hero;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
    _ptsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _ptsAnim = IntTween(begin: 0, end: widget.pointsEarned).animate(
      CurvedAnimation(parent: _ptsCtrl, curve: Curves.easeOutCubic),
    );
    _hero = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Confetti + counter fire just after the scale-in starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _ptsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _ptsCtrl.dispose();
    _hero.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPoints = widget.pointsEarned > 0;
    final hasStreak = widget.streakDays > 0;

    // Headline rendered in elegant Arabic calligraphy.
    final headlineArabic = hasPoints ? 'ما شاء الله' : 'الحمد لله';
    final subhead = hasPoints ? 'Keep it up!' : 'Every breath counts.';

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // Tapping anywhere on the dimmed area dismisses the popup —
        // user shouldn't be forced to hit the Alhamdulillah CTA.
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                // Absorb taps on the card itself so tapping inside doesn't
                // accidentally dismiss the popup.
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Y4.cream, Y4.bg, Y4.butter],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Y4.palette.ink.withValues(alpha: 0.25),
                          blurRadius: 50,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeroEmblem(animation: _hero),
                    const SizedBox(height: 18),
                    Text(
                      headlineArabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: Y4.palette.ink,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Y4.palette.honeyDeep.withValues(alpha: 0.18),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subhead,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Y4.palette.honeyDeep,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _StatsRow(
                      pointsAnim: _ptsAnim,
                      streakDays: widget.streakDays,
                      hasPoints: hasPoints,
                      hasStreak: hasStreak,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Y4.honey, Y4.honeyDeep],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Y4.palette.honeyDeep.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'الحمد لله',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: math.pi / 2, // straight down
              numberOfParticles: 22,
              maxBlastForce: 16,
              minBlastForce: 6,
              emissionFrequency: 0.04,
              gravity: 0.18,
              shouldLoop: false,
              colors: const [
                Y4.honey,
                Y4.honeyDeep,
                Y4.butter,
                Y4.amberY,
                Y4.primary,
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero emblem — tasbih (prayer beads) ring with "الله" written in the center.
// Pulses softly. Designed to evoke remembrance rather than a generic bloom.
// ─────────────────────────────────────────────────────────────────────────────
class _HeroEmblem extends StatelessWidget {
  final Animation<double> animation;
  const _HeroEmblem({required this.animation});

  @override
  Widget build(BuildContext context) {
    const size = 104.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) => CustomPaint(
              size: const Size(size, size),
              painter: _TasbihPainter(pulse: animation.value),
            ),
          ),
          // Allah in elegant Arabic calligraphy at the center.
          Text(
            'ﷲ',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Y4.palette.ink,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Y4.palette.honey.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TasbihPainter extends CustomPainter {
  final double pulse;
  _TasbihPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer halo — soft butter glow that breathes with the pulse.
    canvas.drawCircle(
      c,
      r,
      Paint()..color = Y4.palette.butter.withValues(alpha: 0.55 + 0.10 * pulse),
    );

    // Inner cream disc — the surface the beads sit on.
    canvas.drawCircle(
      c,
      r * 0.82,
      Paint()..color = Y4.palette.cream.withValues(alpha: 0.9),
    );

    // Thread guide — faint ring that visually connects the beads.
    final beadRingR = r * 0.78;
    canvas.drawCircle(
      c,
      beadRingR,
      Paint()
        ..color = Y4.palette.honeyDeep.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 33 beads — the count of one full tasbih cycle. Spaced evenly around
    // the ring; the bead at the top is the "imam bead" (slightly larger,
    // a touch darker) — the traditional marker on a tasbih.
    const beadCount = 33;
    final beadPaint = Paint()..color = Y4.palette.honey;
    final imamPaint = Paint()..color = Y4.palette.honeyDeep;
    final beadEdgePaint = Paint()
      ..color = Y4.palette.honeyDeep.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int i = 0; i < beadCount; i++) {
      // Start at top (−π/2) and go clockwise.
      final angle = -math.pi / 2 + i * (math.pi * 2 / beadCount);
      final p = Offset(
        c.dx + beadRingR * math.cos(angle),
        c.dy + beadRingR * math.sin(angle),
      );
      final isImam = i == 0;
      final beadR = isImam ? 4.4 : 3.0;
      canvas.drawCircle(p, beadR, isImam ? imamPaint : beadPaint);
      canvas.drawCircle(p, beadR, beadEdgePaint);
    }

    // Subtle inner highlight ring to give depth around the Allah glyph.
    canvas.drawCircle(
      c,
      r * 0.42,
      Paint()..color = Y4.palette.honey.withValues(alpha: 0.18 + 0.10 * pulse),
    );
  }

  @override
  bool shouldRepaint(covariant _TasbihPainter old) => old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — animated points + streak, on a honey-deep card.
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Animation<int> pointsAnim;
  final int streakDays;
  final bool hasPoints;
  final bool hasStreak;
  const _StatsRow({
    required this.pointsAnim,
    required this.streakDays,
    required this.hasPoints,
    required this.hasStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Y4.palette.honeyDeep,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Y4.palette.honeyDeep.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SEEDS EARNED',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: pointsAnim,
                  builder: (_, __) {
                    final v = pointsAnim.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SabiqCoin(size: 20),
                        const SizedBox(width: 5),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              // The header "SEEDS EARNED" already labels
                              // the unit, so this row just shows the
                              // value to keep the card tight on small
                              // screens. Big values (e.g. +286) used to
                              // push the row past the column's width.
                              '+$v',
                              maxLines: 1,
                              style: GoogleFonts.fraunces(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: -0.4,
                                height: 1.0,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'STREAK',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Y4.palette.butter,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hasStreak
                    ? '$streakDays ${streakDays == 1 ? "day" : "days"}'
                    : 'Start today',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
