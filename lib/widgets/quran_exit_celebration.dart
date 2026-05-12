// lib/widgets/quran_exit_celebration.dart
//
// Mirror of dhikr_exit_celebration but tuned for the Quran reader.
// Shown when the user exits after either:
//   • ≥ 60 s in Mushaf mode, or
//   • at least one ayah read in Ayat mode.
//
// Stats card surfaces three real numbers — Seeds earned this session,
// ayahs read, and minutes spent — beneath a calligraphic headline.

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/y4_theme.dart';
import 'sabiq_coin.dart';

/// Show the Quran-exit celebration. Awaits user dismissal (tap CTA, back,
/// or barrier tap). Caller is responsible for `Navigator.pop` after this
/// returns.
Future<void> showQuranExitCelebration(
  BuildContext context, {
  required int pointsEarned,
  required int ayahsRead,
  required int durationSeconds,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'quran_exit_celebration',
    barrierColor: Y4.ink.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (ctx, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curve, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _QuranExitCelebrationBody(
      pointsEarned: pointsEarned,
      ayahsRead: ayahsRead,
      durationSeconds: durationSeconds,
    ),
  );
}

class _QuranExitCelebrationBody extends StatefulWidget {
  final int pointsEarned;
  final int ayahsRead;
  final int durationSeconds;
  const _QuranExitCelebrationBody({
    required this.pointsEarned,
    required this.ayahsRead,
    required this.durationSeconds,
  });

  @override
  State<_QuranExitCelebrationBody> createState() =>
      _QuranExitCelebrationBodyState();
}

class _QuranExitCelebrationBodyState extends State<_QuranExitCelebrationBody>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _ptsCtrl;
  late final Animation<int> _ptsAnim;
  late final AnimationController _hero;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 900),
    );
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

  String _formatMinutes(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final hasPoints = widget.pointsEarned > 0;
    final headlineArabic = hasPoints ? 'بارك الله فيك' : 'الحمد لله';
    final subhead = hasPoints ? 'Beautiful recitation.' : 'Every moment counts.';

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
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
                          color: Y4.ink.withValues(alpha: 0.25),
                          blurRadius: 50,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BookEmblem(animation: _hero),
                        const SizedBox(height: 18),
                        Text(
                          headlineArabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Y4.ink,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Y4.honeyDeep.withValues(alpha: 0.18),
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
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: Y4.honeyDeep,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _QuranStatsRow(
                          pointsAnim: _ptsAnim,
                          ayahsRead: widget.ayahsRead,
                          duration: _formatMinutes(widget.durationSeconds),
                          hasPoints: hasPoints,
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
                                  color:
                                      Y4.honeyDeep.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(context).maybePop(),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                blastDirection: math.pi / 2,
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
// Hero emblem — open book in honey + sage with a gentle pulse.
// ─────────────────────────────────────────────────────────────────────────────
class _BookEmblem extends StatelessWidget {
  final Animation<double> animation;
  const _BookEmblem({required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          size: const Size(104, 104),
          painter: _BookPainter(pulse: animation.value),
        ),
      ),
    );
  }
}

class _BookPainter extends CustomPainter {
  final double pulse;
  _BookPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Soft halo behind the book.
    canvas.drawCircle(
      c,
      r,
      Paint()..color = Y4.butter.withValues(alpha: 0.55 + 0.1 * pulse),
    );
    canvas.drawCircle(
      c,
      r * 0.82,
      Paint()..color = Y4.cream.withValues(alpha: 0.9),
    );

    // Open-book silhouette — two leaves meeting at a central spine,
    // tilted up slightly at the outer corners to look held open.
    final bookLeft = Path()
      ..moveTo(c.dx, c.dy + r * 0.05)
      ..lineTo(c.dx - r * 0.55, c.dy + r * 0.40)
      ..lineTo(c.dx - r * 0.55, c.dy - r * 0.35)
      ..lineTo(c.dx, c.dy - r * 0.10)
      ..close();
    final bookRight = Path()
      ..moveTo(c.dx, c.dy + r * 0.05)
      ..lineTo(c.dx + r * 0.55, c.dy + r * 0.40)
      ..lineTo(c.dx + r * 0.55, c.dy - r * 0.35)
      ..lineTo(c.dx, c.dy - r * 0.10)
      ..close();

    final leafFill = Paint()..color = Colors.white;
    final leafStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Y4.honeyDeep.withValues(alpha: 0.7);

    canvas.drawPath(bookLeft, leafFill);
    canvas.drawPath(bookLeft, leafStroke);
    canvas.drawPath(bookRight, leafFill);
    canvas.drawPath(bookRight, leafStroke);

    // Ruled lines on each leaf to suggest text.
    final linePaint = Paint()
      ..color = Y4.honeyDeep.withValues(alpha: 0.30)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final dy = c.dy - r * 0.18 + i * (r * 0.12);
      // Left page
      canvas.drawLine(
        Offset(c.dx - r * 0.45, dy),
        Offset(c.dx - r * 0.10, dy - r * 0.02),
        linePaint,
      );
      // Right page
      canvas.drawLine(
        Offset(c.dx + r * 0.10, dy - r * 0.02),
        Offset(c.dx + r * 0.45, dy),
        linePaint,
      );
    }

    // Spine highlight.
    canvas.drawLine(
      Offset(c.dx, c.dy - r * 0.10),
      Offset(c.dx, c.dy + r * 0.05),
      Paint()
        ..color = Y4.honeyDeep
        ..strokeWidth = 2,
    );

    // Gentle glow on top of the open book.
    canvas.drawCircle(
      c.translate(0, -r * 0.32),
      r * 0.18 + 4 * pulse,
      Paint()
        ..color = Y4.honey.withValues(alpha: 0.45 + 0.15 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _BookPainter old) => old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// Three-stat row — Seeds Earned · Ayahs · Time. Honey-deep card,
// matches the dhikr exit celebration's visual rhythm.
// ─────────────────────────────────────────────────────────────────────────────
class _QuranStatsRow extends StatelessWidget {
  final Animation<int> pointsAnim;
  final int ayahsRead;
  final String duration;
  final bool hasPoints;
  const _QuranStatsRow({
    required this.pointsAnim,
    required this.ayahsRead,
    required this.duration,
    required this.hasPoints,
  });

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: Colors.white,
        ),
      );

  Widget _value(String text) => Text(
        text,
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: -0.3,
          height: 1.0,
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.white.withValues(alpha: 0.18),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Y4.honeyDeep,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Y4.honeyDeep.withValues(alpha: 0.28),
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
                _label('SEEDS'),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: pointsAnim,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SabiqCoin(size: 18),
                      const SizedBox(width: 5),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _value(
                            hasPoints ? '+${pointsAnim.value}' : '+0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _label('AYAHS'),
                const SizedBox(height: 4),
                _value(ayahsRead.toString()),
              ],
            ),
          ),
          _divider(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    _label('TIME'),
                  ],
                ),
                const SizedBox(height: 4),
                _value(duration),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
