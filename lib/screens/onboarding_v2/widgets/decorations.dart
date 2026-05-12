// lib/screens/onboarding_v2/widgets/decorations.dart
//
// Smaller decorative pieces — seed-flow animation (S2), Donor/Reader/Charity
// glyphs (S6), Sabiq garden icon (S8).

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'onboarding_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Animated seeds flowing left → right between Quran mini and aid photo (S2).
// ─────────────────────────────────────────────────────────────────────────────
class SeedFlow extends StatefulWidget {
  final int count;
  const SeedFlow({super.key, this.count = 9});

  @override
  State<SeedFlow> createState() => _SeedFlowState();
}

class _SeedFlowState extends State<SeedFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_SeedSpec> _seeds;

  @override
  void initState() {
    super.initState();
    _seeds = List.generate(widget.count, (i) {
      return _SeedSpec(
        topPct: 0.18 + (i % 4) * 0.10,
        delay: i * 0.5,
        dur: 4 + (i % 3),
      );
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final now = _ctrl.value * 7.0; // seconds-equivalent
        return Stack(
          children: _seeds.map((s) {
            final localT = ((now - s.delay) / s.dur) % 1.0;
            if (localT < 0 || localT > 1) {
              return const SizedBox.shrink();
            }
            final opacity = (localT < 0.15)
                ? localT / 0.15
                : (localT > 0.85)
                    ? (1.0 - localT) / 0.15
                    : 1.0;
            final scale = (localT < 0.15 || localT > 0.85) ? 0.6 : 1.0;
            return Positioned(
              top: s.topPct * 230,
              left: 8 + localT * 64, // 8 → 72 (within an 80px band)
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: _SeedDot(),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SeedSpec {
  final double topPct;
  final double delay;
  final double dur;
  _SeedSpec({required this.topPct, required this.delay, required this.dur});
}

class _SeedDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFE493), OnbTok.gold, OnbTok.goldDeep],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: OnbTok.gold.withValues(alpha: 0.65),
            blurRadius: 14,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed gold arrow for the seed flow (Quran → aid).
// ─────────────────────────────────────────────────────────────────────────────
class DashedArrow extends StatefulWidget {
  final double width;
  final double height;
  const DashedArrow({super.key, this.width = 80, this.height = 20});

  @override
  State<DashedArrow> createState() => _DashedArrowState();
}

class _DashedArrowState extends State<DashedArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _DashedArrowPainter(offset: _ctrl.value * 16),
      ),
    );
  }
}

class _DashedArrowPainter extends CustomPainter {
  final double offset;
  _DashedArrowPainter({required this.offset});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OnbTok.goldDeep
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashOn = 4.0;
    const dashOff = 4.0;
    final y = size.height / 2;
    double x = -offset;
    while (x < size.width - 10) {
      final start = math.max(x, 0.0);
      final end = math.min(x + dashOn, size.width - 10);
      if (end > start) {
        canvas.drawLine(Offset(start, y), Offset(end, y), paint);
      }
      x += dashOn + dashOff;
    }
    // Arrow head
    final head = Path()
      ..moveTo(size.width - 10, y - 5)
      ..lineTo(size.width, y)
      ..lineTo(size.width - 10, y + 5)
      ..close();
    canvas.drawPath(head, Paint()..color = OnbTok.goldDeep);
  }

  @override
  bool shouldRepaint(covariant _DashedArrowPainter old) => old.offset != offset;
}

// ─────────────────────────────────────────────────────────────────────────────
// Trust diagram glyphs (S6).
// ─────────────────────────────────────────────────────────────────────────────
class DonorGlyph extends StatelessWidget {
  final double size;
  const DonorGlyph({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.volunteer_activism_rounded,
        size: size, color: Colors.white);
  }
}

class ReaderGlyph extends StatelessWidget {
  final double size;
  const ReaderGlyph({super.key, this.size = 38});
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.menu_book_rounded, size: size, color: Colors.white);
  }
}

class CharityGlyph extends StatelessWidget {
  final double size;
  const CharityGlyph({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.favorite_rounded, size: size, color: Colors.white);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sabiq garden icon for Screen 8 — sun + seed + leaf.
// ─────────────────────────────────────────────────────────────────────────────
class SabiqGardenIcon extends StatelessWidget {
  final double size;
  const SabiqGardenIcon({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GardenIconPainter()),
    );
  }
}

class _GardenIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // Sun halo
    canvas.drawCircle(c, r, Paint()..color = OnbTok.goldLight);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF1B8),
          OnbTok.goldLight.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, glow);

    // Ground (golden mound)
    final ground = Path()
      ..moveTo(0, r * 1.4)
      ..quadraticBezierTo(r, r * 1.25, size.width, r * 1.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = OnbTok.goldDeep);

    // Seed body (egg shape)
    final seed = Path()
      ..moveTo(r, r * 0.7)
      ..cubicTo(r * 1.15, r * 0.85, r * 1.3, r * 0.95, r * 1.3, r * 1.2)
      ..cubicTo(r * 1.3, r * 1.4, r * 1.15, r * 1.5, r, r * 1.5)
      ..cubicTo(r * 0.85, r * 1.5, r * 0.7, r * 1.4, r * 0.7, r * 1.2)
      ..cubicTo(r * 0.7, r * 0.95, r * 0.85, r * 0.85, r, r * 0.7)
      ..close();
    canvas.drawPath(seed, Paint()..color = OnbTok.gold);

    // Center vein
    final vein = Paint()
      ..color = OnbTok.goldDeep
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(r, r * 0.8), Offset(r, r * 1.45), vein);

    // Sage leaf
    final leaf = Path()
      ..moveTo(r, r * 0.9)
      ..quadraticBezierTo(r * 1.2, r * 0.8, r * 1.25, r * 0.95)
      ..quadraticBezierTo(r * 1.15, r * 1.05, r, r * 1.0)
      ..close();
    canvas.drawPath(leaf, Paint()..color = OnbTok.teal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
