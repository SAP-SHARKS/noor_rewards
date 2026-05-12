// lib/screens/onboarding_v2/phase1_screens.dart
//
// Phase 1 — Story (screens 1–7). All seven screens are designed to be
// rendered inside a PageView managed by [OnboardingFlow]. Each is given
// an [onNext] callback that advances the page or, on screen 7, completes
// Phase 1 and routes to the existing StartJourneyScreen (Google login).
// [onSkip] short-circuits the story and goes straight to login.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'widgets/akhirah_mini.dart';
import 'widgets/decorations.dart';
import 'widgets/door_scales.dart';
import 'widgets/onboarding_components.dart';
import 'widgets/onboarding_tokens.dart';
import 'widgets/quran_mini.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — The Hook
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen1 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen1({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  const PhotoSlot(slotKey: 'onb_hero_1'),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: 90,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              OnbTok.cream.withValues(alpha: 0),
                              OnbTok.cream,
                            ],
                            stops: const [0.0, 0.92],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Container(
                color: OnbTok.cream,
                padding: const EdgeInsets.fromLTRB(26, 14, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Wordmark(size: 20),
                    const SizedBox(height: 18),
                    OnbHeading(
                      first: l.onbV2_1_TitleA,
                      accent: l.onbV2_1_TitleB,
                      fontSize: 34,
                    ),
                    const SizedBox(height: 14),
                    Text(l.onbV2_1_Sub, style: OnbTok.sans()),
                    const Spacer(),
                    ScreenFooter(
                      dotsIdx: 0,
                      child: CTA(label: l.onbV2_1_Cta, onPressed: onNext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — The Mechanism (animated seed flow)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen2({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 30, 26, 10),
                child: Wordmark(size: 20),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Text(l.onbV2_2_Title,
                    style: OnbTok.serif(fontSize: 30)),
              ),
              const SizedBox(height: 24),
              // Flow box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    color: OnbTok.creamWarm,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Left: Quran mini
                      Positioned(
                        left: 18,
                        top: 24,
                        width: 88,
                        height: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: PhotoSlot(
                            slotKey: 'onb_quran_2',
                            fallback: _MiniQuranCard(),
                          ),
                        ),
                      ),
                      // Right: aid photo
                      Positioned(
                        right: 18,
                        top: 24,
                        width: 88,
                        height: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: const PhotoSlot(
                            slotKey: 'onb_aid_2',
                            placeholderText:
                                'aid photo\nhands receiving',
                          ),
                        ),
                      ),
                      // Dashed arrow (centered horizontally between cards)
                      const Positioned(
                        left: 120,
                        right: 120,
                        top: 105,
                        child: DashedArrow(height: 20),
                      ),
                      // Seeds flowing
                      const Positioned(
                        left: 115,
                        top: 0,
                        width: 80,
                        height: 230,
                        child: SeedFlow(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: _MechanicLine(),
              ),
              const Spacer(),
              ScreenFooter(
                dotsIdx: 1,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

class _MechanicLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Text(
      l.onbV2_2_Body,
      style: OnbTok.sans(
        fontSize: 15.5,
        color: OnbTok.brownSoft,
        height: 1.45,
      ),
    );
  }
}

class _MiniQuranCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Al-Baqarah',
            style: OnbTok.sans(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: OnbTok.brown,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: OnbTok.creamWarm),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'بِسْمِ اللَّهِ',
              textAlign: TextAlign.right,
              style: OnbTok.arabic(fontSize: 13, color: OnbTok.brown),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'In the name of Allah, the Most Gracious…',
            style: OnbTok.sans(fontSize: 6, color: OnbTok.brownSoft),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3 — Quran Earns Seeds
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen3 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen3({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          // Radial gold gradient bg
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.24),
                  radius: 0.6,
                  colors: [
                    OnbTok.goldLight.withValues(alpha: 0.55),
                    OnbTok.cream.withValues(alpha: 0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 30, 26, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wordmark(size: 20),
                ),
              ),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Curved gold arrow + "earned today" label
                      Positioned(
                        right: 24,
                        top: 80,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(painter: _CurveArrowPainter()),
                        ),
                      ),
                      Positioned(
                        right: 38,
                        top: 70,
                        child: Text(
                          l.onbV2_3_BannerLabel,
                          style: OnbTok.serif(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: OnbTok.goldDeep,
                            height: 1.0,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      // Quran mockup (or admin-uploaded screenshot)
                      PhotoSlot(
                        slotKey: 'onb_quran_3',
                        fallback: const QuranMini(
                          width: 210,
                          tilt: -4,
                          showSeedBanner: true,
                          pulseBanner: true,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_3_TitleA,
                      accent: l.onbV2_3_TitleB,
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_3_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              ScreenFooter(
                dotsIdx: 2,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

class _CurveArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = OnbTok.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(110, 12)
      ..cubicTo(70, 20, 40, 30, 28, 70);
    canvas.drawPath(path, p);

    // Arrow head at end
    final head = Path()
      ..moveTo(20, 64)
      ..lineTo(28, 70)
      ..lineTo(34, 60)
      ..close();
    canvas.drawPath(head, Paint()..color = OnbTok.goldDeep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 4 — Azkaar Animations (door ↔ scales)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen4 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen4({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.creamWarm,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 30, 26, 0),
                child: Wordmark(size: 20),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: PhotoSlot(
                  slotKey: 'onb_zikr_4',
                  fallback: const DoorScalesAnim(),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_4_TitleA,
                      accent: l.onbV2_4_TitleB,
                    ),
                    const SizedBox(height: 14),
                    Text(l.onbV2_4_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              const Spacer(),
              ScreenFooter(
                dotsIdx: 3,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 5 — Real-World Impact
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen5 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen5({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 60,
              child: Stack(
                children: [
                  const PhotoSlot(slotKey: 'onb_impact_5'),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              OnbTok.goldDeep.withValues(alpha: 0),
                              OnbTok.goldDeep.withValues(alpha: 0.18),
                              OnbTok.cream,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 40,
              child: Container(
                color: OnbTok.cream,
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_5_TitleA,
                      accent: l.onbV2_5_TitleB,
                    ),
                    const SizedBox(height: 14),
                    Text(l.onbV2_5_Sub, style: OnbTok.sans()),
                    const Spacer(),
                    ScreenFooter(
                      dotsIdx: 4,
                      child: CTA(label: l.onbV2Next, onPressed: onNext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 6 — Trust (3-step diagram)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen6 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen6({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 30, 26, 0),
                child: Wordmark(size: 20),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_6_TitleA,
                      accent: l.onbV2_6_TitleB,
                      trailing: l.onbV2_6_TitleC,
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_6_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Stack(
                    children: [
                      // Connector arrows behind icons
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _ConnectorPainter()),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _StepIcon(
                            size: 62,
                            bg: OnbTok.goldDeep,
                            glyph: const DonorGlyph(),
                            label: l.onbV2_6_Donor,
                            sub: l.onbV2_6_DonorSub,
                          ),
                          _StepIcon(
                            size: 88,
                            bg: OnbTok.gold,
                            big: true,
                            glyph: const ReaderGlyph(),
                            label: l.onbV2_6_You,
                            sub: l.onbV2_6_YouSub,
                          ),
                          _StepIcon(
                            size: 62,
                            bg: OnbTok.goldDeep,
                            glyph: const CharityGlyph(),
                            label: l.onbV2_6_Charity,
                            sub: l.onbV2_6_CharitySub,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: OnbTok.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: OnbTok.teal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.onbV2_6_TrustBadge,
                        style: OnbTok.sans(
                          fontSize: 11.5,
                          color: OnbTok.tealDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ScreenFooter(
                dotsIdx: 5,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final double size;
  final Color bg;
  final Widget glyph;
  final String label;
  final String sub;
  final bool big;
  const _StepIcon({
    required this.size,
    required this.bg,
    required this.glyph,
    required this.label,
    required this.sub,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              boxShadow: big
                  ? [
                      BoxShadow(
                        color: OnbTok.gold.withValues(alpha: 0.18),
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: OnbTok.gold.withValues(alpha: 0.6),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                        spreadRadius: -14,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: glyph),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: OnbTok.serif(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OnbTok.brown,
              height: 1.0,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: OnbTok.sans(
              fontSize: 11,
              color: OnbTok.brownSoft,
              height: 1.3,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter();
  @override
  void paint(Canvas canvas, Size size) {
    // Two arrows arcing across the row, behind the icons. Anchor to the
    // top portion (Y ≈ 95 on the original 220-tall canvas; we scale).
    final y = size.height * 0.43; // matches y=95/220 from prototype
    final apexLift = size.height * 0.09;
    final w = size.width;

    final paint = Paint()
      ..color = OnbTok.brownSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final headPaint = Paint()..color = OnbTok.brownSoft;

    // Left arrow: from ~24% to ~47%
    final leftStart = Offset(w * 0.24, y);
    final leftEnd = Offset(w * 0.47, y);
    final leftMid =
        Offset((leftStart.dx + leftEnd.dx) / 2, y - apexLift);
    final leftPath = Path()
      ..moveTo(leftStart.dx, leftStart.dy)
      ..quadraticBezierTo(leftMid.dx, leftMid.dy, leftEnd.dx, leftEnd.dy);
    canvas.drawPath(leftPath, paint);
    _drawHead(canvas, leftEnd, headPaint);

    // Right arrow: from ~56% to ~77%
    final rightStart = Offset(w * 0.56, y);
    final rightEnd = Offset(w * 0.77, y);
    final rightMid =
        Offset((rightStart.dx + rightEnd.dx) / 2, y - apexLift);
    final rightPath = Path()
      ..moveTo(rightStart.dx, rightStart.dy)
      ..quadraticBezierTo(rightMid.dx, rightMid.dy, rightEnd.dx, rightEnd.dy);
    canvas.drawPath(rightPath, paint);
    _drawHead(canvas, rightEnd, headPaint);
  }

  void _drawHead(Canvas canvas, Offset tip, Paint p) {
    final head = Path()
      ..moveTo(tip.dx - 5, tip.dy - 3)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 5, tip.dy + 3)
      ..close();
    canvas.drawPath(head, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 7 — Akhirah Account (teal-dominant)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen7 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen7({super.key, required this.onNext, required this.onSkip});

  @override
  State<Phase1Screen7> createState() => _Phase1Screen7State();
}

class _Phase1Screen7State extends State<Phase1Screen7>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle;
  late final List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _sparkles = List.generate(14, (_) {
      return _Sparkle(
        leftPct: 0.06 + rng.nextDouble() * 0.88,
        topPct: 0.08 + rng.nextDouble() * 0.70,
        delay: rng.nextDouble() * 4,
        dur: 3 + rng.nextDouble() * 3,
        size: 4 + rng.nextDouble() * 4,
      );
    });
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          // Radial teal wash
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.16),
                  radius: 0.7,
                  colors: [
                    OnbTok.teal.withValues(alpha: 0.16),
                    OnbTok.cream.withValues(alpha: 0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 30, 26, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wordmark(size: 20),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Teal halo
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              OnbTok.teal.withValues(alpha: 0.22),
                              OnbTok.teal.withValues(alpha: 0),
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                      // Sparkles
                      ..._sparkles.map((s) {
                        return AnimatedBuilder(
                          animation: _sparkle,
                          builder: (_, __) {
                            final now = _sparkle.value * 6.0;
                            final t = ((now - s.delay) / s.dur) % 1.0;
                            double opacity = 0;
                            double y = 0;
                            double scale = 0.6;
                            if (t >= 0 && t <= 1) {
                              if (t < 0.4) {
                                opacity = t / 0.4;
                                y = -6 * (t / 0.4);
                                scale = 0.6 + 0.4 * (t / 0.4);
                              } else if (t < 0.6) {
                                opacity = 1;
                                y = -6 - 4 * ((t - 0.4) / 0.2);
                                scale = 1.0;
                              } else {
                                opacity = (1.0 - t) / 0.4;
                                y = -10 + 10 * ((t - 0.6) / 0.4);
                                scale = 1.0 - 0.4 * ((t - 0.6) / 0.4);
                              }
                            }
                            return Positioned(
                              left: s.leftPct * c.maxWidth,
                              top: s.topPct * c.maxHeight + y,
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: scale,
                                  child: CustomPaint(
                                    size: Size(s.size, s.size),
                                    painter: _TealStarPainter(),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      // Akhirah mockup (or admin-uploaded screenshot)
                      PhotoSlot(
                        slotKey: 'onb_akhirah_7',
                        fallback: const AkhirahMini(width: 210, tilt: 3),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_7_TitleA,
                      accent: l.onbV2_7_TitleB,
                      accentColor: OnbTok.tealDark,
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_7_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              ScreenFooter(
                dotsIdx: 6,
                teal: true,
                child: CTA(label: l.onbV2Next, onPressed: widget.onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: widget.onSkip),
        ],
      ),
    );
  }
}

class _Sparkle {
  final double leftPct;
  final double topPct;
  final double delay;
  final double dur;
  final double size;
  _Sparkle({
    required this.leftPct,
    required this.topPct,
    required this.delay,
    required this.dur,
    required this.size,
  });
}

class _TealStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = OnbTok.teal;
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.5, 0)
      ..lineTo(s * 0.6, s * 0.4)
      ..lineTo(s, s * 0.5)
      ..lineTo(s * 0.6, s * 0.6)
      ..lineTo(s * 0.5, s)
      ..lineTo(s * 0.4, s * 0.6)
      ..lineTo(0, s * 0.5)
      ..lineTo(s * 0.4, s * 0.4)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
