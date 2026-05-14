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
// Hero emblem — illuminated Mushaf with a gentle Noor glow.
// ─────────────────────────────────────────────────────────────────────────────
class _BookEmblem extends StatelessWidget {
  final Animation<double> animation;
  const _BookEmblem({required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          size: const Size(120, 120),
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

    // ── Layered halo: outer butter glow → inner cream disc → gold ring ─────
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Y4.honey.withValues(alpha: 0.32 + 0.10 * pulse),
          Y4.honey.withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, haloPaint);

    canvas.drawCircle(
      c,
      r * 0.84,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFAEB), Y4.cream],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.84)),
    );
    canvas.drawCircle(
      c,
      r * 0.84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Y4.honeyDeep.withValues(alpha: 0.35),
    );

    // ── Crescent ornament above the book ────────────────────────────────────
    final crescentCenter = Offset(c.dx, c.dy - r * 0.50);
    final crescentR = r * 0.085;
    canvas.saveLayer(
      Rect.fromCircle(center: crescentCenter, radius: crescentR * 1.4),
      Paint(),
    );
    canvas.drawCircle(
      crescentCenter,
      crescentR,
      Paint()..color = Y4.honeyDeep,
    );
    canvas.drawCircle(
      Offset(crescentCenter.dx + crescentR * 0.45, crescentCenter.dy - crescentR * 0.10),
      crescentR * 0.85,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // ── Open mushaf: curved pages meeting at a gold spine ──────────────────
    final pageTopY = c.dy - r * 0.30;
    final pageBottomY = c.dy + r * 0.38;
    final pageOuterDx = r * 0.58;
    final spineTop = Offset(c.dx, pageTopY + r * 0.04);
    final spineBottom = Offset(c.dx, pageBottomY - r * 0.02);

    Path leafPath({required bool isLeft}) {
      final sign = isLeft ? -1.0 : 1.0;
      final outerTop = Offset(c.dx + sign * pageOuterDx, pageTopY + r * 0.14);
      final outerBottom =
          Offset(c.dx + sign * pageOuterDx, pageBottomY - r * 0.02);
      return Path()
        ..moveTo(spineTop.dx, spineTop.dy)
        // Top edge curves out to the outer top corner (page lifts away
        // from the spine like a real open page).
        ..cubicTo(
          c.dx + sign * pageOuterDx * 0.35,
          pageTopY - r * 0.02,
          c.dx + sign * pageOuterDx * 0.85,
          pageTopY + r * 0.04,
          outerTop.dx,
          outerTop.dy,
        )
        // Outer edge runs down the page.
        ..lineTo(outerBottom.dx, outerBottom.dy)
        // Bottom edge curves back to the spine.
        ..cubicTo(
          c.dx + sign * pageOuterDx * 0.70,
          pageBottomY + r * 0.02,
          c.dx + sign * pageOuterDx * 0.30,
          pageBottomY - r * 0.02,
          spineBottom.dx,
          spineBottom.dy,
        )
        ..close();
    }

    final leftPath = leafPath(isLeft: true);
    final rightPath = leafPath(isLeft: false);

    // Subtle drop shadow under each page.
    final shadow = Paint()
      ..color = Y4.honeyDeep.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(leftPath, shadow);
    canvas.drawPath(rightPath, shadow);
    canvas.restore();

    // Page fill — cream gradient that hints at the gutter being deeper.
    Paint pageFill({required bool isLeft}) {
      final start = isLeft ? Alignment.centerRight : Alignment.centerLeft;
      final end = isLeft ? Alignment.centerLeft : Alignment.centerRight;
      return Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFFFFFCF1), Color(0xFFFFFFFF)],
          begin: start,
          end: end,
          stops: const [0.0, 0.55],
        ).createShader(leftPath.getBounds().expandToInclude(rightPath.getBounds()));
    }

    canvas.drawPath(leftPath, pageFill(isLeft: true));
    canvas.drawPath(rightPath, pageFill(isLeft: false));

    // Page edges — fine gold stroke.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Y4.honeyDeep.withValues(alpha: 0.85);
    canvas.drawPath(leftPath, edge);
    canvas.drawPath(rightPath, edge);

    // ── Calligraphic strokes hinting at Arabic baseline on each page ───────
    final scriptPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Y4.honeyDeep.withValues(alpha: 0.55);
    for (int i = 0; i < 3; i++) {
      final y = pageTopY + r * 0.18 + i * (r * 0.16);

      // Left page baseline + a short loop above it.
      final leftBase = Path()
        ..moveTo(c.dx - pageOuterDx * 0.82, y)
        ..quadraticBezierTo(
          c.dx - pageOuterDx * 0.42,
          y + r * 0.03,
          c.dx - r * 0.06,
          y,
        );
      canvas.drawPath(leftBase, scriptPaint);
      // A tiny ascending stroke to suggest letterforms.
      final leftAsc = Path()
        ..moveTo(c.dx - pageOuterDx * 0.55, y - r * 0.04)
        ..lineTo(c.dx - pageOuterDx * 0.55, y);
      canvas.drawPath(leftAsc, scriptPaint);

      // Right page (mirror).
      final rightBase = Path()
        ..moveTo(c.dx + r * 0.06, y)
        ..quadraticBezierTo(
          c.dx + pageOuterDx * 0.42,
          y + r * 0.03,
          c.dx + pageOuterDx * 0.82,
          y,
        );
      canvas.drawPath(rightBase, scriptPaint);
      final rightAsc = Path()
        ..moveTo(c.dx + pageOuterDx * 0.55, y - r * 0.04)
        ..lineTo(c.dx + pageOuterDx * 0.55, y);
      canvas.drawPath(rightAsc, scriptPaint);
    }

    // ── Gold spine — gradient ribbon along the gutter ───────────────────────
    final spineRect = Rect.fromLTWH(
      c.dx - r * 0.022,
      spineTop.dy,
      r * 0.044,
      spineBottom.dy - spineTop.dy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(spineRect, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Y4.honey, Y4.honeyDeep, Y4.honey],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
        ).createShader(spineRect),
    );

    // ── Noor radiating from the spine — top-down beam ───────────────────────
    final beamCenter = Offset(c.dx, pageTopY - r * 0.08);
    final beamGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Y4.honey.withValues(alpha: 0.65 + 0.18 * pulse),
          Y4.honey.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: beamCenter,
        radius: r * (0.26 + 0.04 * pulse),
      ))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(beamCenter, r * (0.26 + 0.04 * pulse), beamGlow);

    // Six-rayed star at the beam center (Islamic geometric motif).
    final star = Path();
    const points = 6;
    final outerR = r * 0.07;
    final innerR = r * 0.03;
    for (int i = 0; i < points * 2; i++) {
      final angle = -math.pi / 2 + i * math.pi / points;
      final rr = i.isEven ? outerR : innerR;
      final p = Offset(
        beamCenter.dx + rr * math.cos(angle),
        beamCenter.dy + rr * math.sin(angle),
      );
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()..color = Y4.honeyDeep.withValues(alpha: 0.92),
    );

    // ── Twinkles around the halo (pulsing) ──────────────────────────────────
    final twinklePaint = Paint()
      ..color = Y4.honey.withValues(alpha: 0.85 - 0.2 * pulse);
    final twinklePositions = <Offset>[
      Offset(c.dx - r * 0.78, c.dy - r * 0.20),
      Offset(c.dx + r * 0.80, c.dy - r * 0.08),
      Offset(c.dx - r * 0.05, c.dy - r * 0.86),
      Offset(c.dx + r * 0.62, c.dy + r * 0.62),
      Offset(c.dx - r * 0.66, c.dy + r * 0.58),
    ];
    for (int i = 0; i < twinklePositions.length; i++) {
      final tw = twinklePositions[i];
      final sz = 1.6 + (i.isEven ? 0.6 : 0.2) + 0.5 * pulse;
      _drawSparkle(canvas, tw, sz, twinklePaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    // Four-point sparkle (☆-style).
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
          center.dx + radius * 0.2, center.dy - radius * 0.2,
          center.dx + radius, center.dy)
      ..quadraticBezierTo(
          center.dx + radius * 0.2, center.dy + radius * 0.2,
          center.dx, center.dy + radius)
      ..quadraticBezierTo(
          center.dx - radius * 0.2, center.dy + radius * 0.2,
          center.dx - radius, center.dy)
      ..quadraticBezierTo(
          center.dx - radius * 0.2, center.dy - radius * 0.2,
          center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
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
