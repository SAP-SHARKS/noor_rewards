// lib/screens/onboarding_v2/widgets/door_scales.dart
//
// Animated door ↔ scales crossfade on a golden warm background. Used as
// fallback for the onb_zikr_4 slot on Phase 1 Screen 4.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'onboarding_tokens.dart';

class DoorScalesAnim extends StatefulWidget {
  const DoorScalesAnim({super.key});

  @override
  State<DoorScalesAnim> createState() => _DoorScalesAnimState();
}

class _DoorScalesAnimState extends State<DoorScalesAnim>
    with TickerProviderStateMixin {
  late final AnimationController _cycle;
  late final AnimationController _rays;

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _cycle.dispose();
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OnbTok.goldLight, OnbTok.creamWarm],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: OnbTok.goldDeep.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing rays background
            AnimatedBuilder(
              animation: _rays,
              builder: (_, __) {
                final t = _rays.value;
                final alpha = 0.35 + 0.25 * math.sin(t * math.pi * 2);
                return CustomPaint(
                  size: const Size.fromHeight(240),
                  painter: _RaysPainter(alpha: alpha),
                );
              },
            ),
            // Door ↔ scales crossfade
            AnimatedBuilder(
              animation: _cycle,
              builder: (_, __) {
                final t = _cycle.value; // 0..1
                // 0..0.4 → door visible; 0.5..0.9 → scales visible
                final doorOpacity =
                    (t < 0.4 ? 1.0 : (t < 0.5 ? (0.5 - t) / 0.1 : 0.0));
                final scalesOpacity =
                    (t < 0.4 ? 0.0 : (t < 0.5 ? (t - 0.4) / 0.1 : 1.0));
                final scalesFinal = t > 0.9 ? (1.0 - t) / 0.1 : scalesOpacity;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: doorOpacity.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 120,
                        height: 170,
                        child: CustomPaint(painter: _DoorPainter()),
                      ),
                    ),
                    Opacity(
                      opacity: scalesFinal.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(painter: _ScalesPainter()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final double alpha;
  _RaysPainter({required this.alpha});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF1B8).withValues(alpha: 0.9 * alpha),
          const Color(0xFFF5DC8C).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawRect(Offset.zero & size, glow);

    final rayPaint = Paint()
      ..color = const Color(0xFFFFF1B8).withValues(alpha: 0.18 * alpha)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 9; i++) {
      final angle = (i * math.pi) / 9 + math.pi;
      final p = Offset(
        center.dx + math.cos(angle) * 220,
        center.dy + math.sin(angle) * 220,
      );
      canvas.drawLine(center, p, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.alpha != alpha;
}

class _DoorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Arched door — deep gold outer, gold inner
    final outer = Path()
      ..moveTo(20, 160)
      ..lineTo(20, 60)
      ..quadraticBezierTo(60, 20, 100, 60)
      ..lineTo(100, 160)
      ..close();
    canvas.drawPath(outer, Paint()..color = OnbTok.goldDeep);

    final inner = Path()
      ..moveTo(28, 158)
      ..lineTo(28, 64)
      ..quadraticBezierTo(60, 30, 92, 64)
      ..lineTo(92, 158)
      ..close();
    canvas.drawPath(inner, Paint()..color = OnbTok.gold);

    // Centre divide
    final divide = Paint()
      ..color = OnbTok.goldDeep
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(60, 38), const Offset(60, 158), divide);

    // Knobs
    final knob = Paint()..color = OnbTok.brown;
    canvas.drawCircle(const Offset(52, 100), 2.5, knob);
    canvas.drawCircle(const Offset(68, 100), 2.5, knob);

    // Inner rectangle panels (decorative)
    final panel = Paint()
      ..color = OnbTok.goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final r in [
      const Rect.fromLTWH(36, 60, 20, 36),
      const Rect.fromLTWH(64, 60, 20, 36),
      const Rect.fromLTWH(36, 110, 20, 36),
      const Rect.fromLTWH(64, 110, 20, 36),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(2)),
        panel,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ScalesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final beam = Paint()
      ..color = OnbTok.goldDeep
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // pole
    canvas.drawLine(const Offset(80, 20), const Offset(80, 140), beam);
    // crossbeam
    canvas.drawLine(const Offset(20, 40), const Offset(140, 40), beam);
    // ropes
    final rope = Paint()
      ..color = OnbTok.goldDeep
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(30, 40), const Offset(30, 70), rope);
    canvas.drawLine(const Offset(130, 40), const Offset(130, 70), rope);

    // dishes
    final dish = Paint()..color = OnbTok.gold;
    final dishStroke = Paint()
      ..color = OnbTok.goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final leftDish = Path()
      ..moveTo(14, 70)
      ..quadraticBezierTo(30, 90, 46, 70)
      ..close();
    canvas.drawPath(leftDish, dish);
    canvas.drawPath(leftDish, dishStroke);

    final rightDish = Path()
      ..moveTo(114, 70)
      ..quadraticBezierTo(130, 86, 146, 70)
      ..close();
    canvas.drawPath(rightDish, dish);
    canvas.drawPath(rightDish, dishStroke);

    // base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(62, 138, 36, 8),
        const Radius.circular(2),
      ),
      Paint()..color = OnbTok.goldDeep,
    );

    // sparkles on left dish (heavier)
    final spark = Paint()..color = const Color(0xFFFFF1B8);
    canvas.drawCircle(const Offset(30, 78), 2, spark);
    canvas.drawCircle(const Offset(35, 74), 1.2, spark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
