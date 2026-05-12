// lib/widgets/sabiq_coin.dart
//
// The Sabiq Seed coin — the app's currency symbol.
//
// Outer honey-gold ring (with 12 decorative dots and a top-left sheen),
// inner emerald disc, and a bold italic gold "S" centered on it. The S
// echoes "Sabiq" (سابق — racing ahead) and the italic slant carries the
// motion that name implies.
//
// Two variants:
//   • SabiqCoin()           — standard coin (Option 1 from the brief).
//   • SabiqCoin(sprouting:) — same coin with a tiny green leaf sprout
//                              off the top-right (Option 4). Reserved for
//                              hero placements (home garden card,
//                              seal-day celebration) where the seed
//                              metaphor most needs the visual hook.
//
// Renders crisply at any size — used at 14 px in pills, 40 px in cards,
// and 180 px on the seal-day stage.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class SabiqCoin extends StatelessWidget {
  /// Pixel size (width = height).
  final double size;

  /// When true, paints a small emerald leaf sprouting from the top-right
  /// of the gold ring — the "Sprouting S" variant for hero contexts.
  final bool sprouting;

  const SabiqCoin({super.key, this.size = 40, this.sprouting = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SabiqCoinPainter(sprouting: sprouting)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — locked to the Sabiq Seed brand. These don't follow the existing
// Y4 honey theme exactly; the coin is its own identity (emerald + deep gold).
// ─────────────────────────────────────────────────────────────────────────────
class _Pal {
  static const goldBright = Color(0xFFFFE89A);
  static const goldPrimary = Color(0xFFE8B84A);
  static const goldDeep = Color(0xFF8B6420);
  static const goldHilite = Color(0xFFFFFAEC);

  static const emeraldLight = Color(0xFF7FCFA8);
  static const emerald = Color(0xFF4A9B8E);
  static const emeraldDeep = Color(0xFF1F4F3D);

  static const brownStroke = Color(0xFF5C3A0A);
  static const sStrokeBrown = Color(0xFF5C3A0A);

  static const sGoldTop = Color(0xFFFFFAEC);
  static const sGoldMid = Color(0xFFFFD662);
  static const sGoldBottom = Color(0xFFA37520);
}

class _SabiqCoinPainter extends CustomPainter {
  final bool sprouting;
  _SabiqCoinPainter({required this.sprouting});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);
    final c = Offset(w / 2, h / 2);

    // Geometry scaled relative to a 180-unit reference (matches the
    // brief's SVG viewBox), so every detail keeps proportion at any size.
    double rel(double v) => v * (s / 180.0);

    final goldR = rel(86); // outer ring radius
    final innerR = rel(62); // emerald disc radius

    // Strokes get a sensible floor so they don't disappear on tiny chips.
    final goldStroke = math.max(0.6, rel(2.5));
    final emeraldStroke = math.max(0.4, rel(1.5));

    // ── Outer gold ring (radial gradient + brown stroke) ───────────────
    final goldRect = Rect.fromCircle(center: c, radius: goldR);
    canvas.drawCircle(
      c,
      goldR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [_Pal.goldBright, _Pal.goldPrimary, _Pal.goldDeep],
          stops: [0.0, 0.55, 1.0],
        ).createShader(goldRect),
    );
    canvas.drawCircle(
      c,
      goldR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = goldStroke
        ..color = _Pal.brownStroke,
    );

    // Decorative dots — 12, evenly spaced around the gold ring.
    final dotPaint = Paint()
      ..color = _Pal.brownStroke.withValues(alpha: 0.5);
    final dotR = math.max(0.4, rel(1.8));
    final dotOrbit = goldR - rel(10);
    for (var i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * (math.pi * 2 / 12);
      final p = Offset(
        c.dx + dotOrbit * math.cos(angle),
        c.dy + dotOrbit * math.sin(angle),
      );
      canvas.drawCircle(p, dotR, dotPaint);
    }

    // Top-left sheen on the gold ring.
    final sheenCenter = Offset(c.dx - rel(30), c.dy - rel(35));
    final sheenRect = Rect.fromCenter(
      center: sheenCenter,
      width: rel(44),
      height: rel(24),
    );
    canvas.save();
    canvas.translate(sheenCenter.dx, sheenCenter.dy);
    canvas.scale(rel(22) / rel(12)); // mild squash for ellipse feel
    canvas.translate(-sheenCenter.dx, -sheenCenter.dy);
    canvas.drawOval(
      sheenRect,
      Paint()..color = _Pal.goldHilite.withValues(alpha: 0.45),
    );
    canvas.restore();

    // ── Inner emerald disc ─────────────────────────────────────────────
    final emeraldRect = Rect.fromCircle(center: c, radius: innerR);
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [_Pal.emeraldLight, _Pal.emerald, _Pal.emeraldDeep],
          stops: [0.0, 0.5, 1.0],
        ).createShader(emeraldRect),
    );
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = emeraldStroke
        ..color = _Pal.emeraldDeep,
    );

    // Emerald top-left sheen.
    final eSheenCenter = Offset(c.dx - rel(18), c.dy - rel(18));
    canvas.drawOval(
      Rect.fromCenter(
        center: eSheenCenter,
        width: rel(40),
        height: rel(22),
      ),
      Paint()..color = const Color(0xFFA8E0C5).withValues(alpha: 0.5),
    );

    // ── Bold italic Fraunces "S" in gold gradient ──────────────────────
    // The serif S is the brand mark. We render it twice: once with a
    // gold gradient + brown stroke (the body), once with a faint cream
    // overlay (top-light highlight) to give it depth.
    final sFontSize = rel(108);
    final sStroke = math.max(0.6, rel(1.2));

    void drawS({
      required Shader fillShader,
      required double strokeWidth,
      Color? strokeColor,
      double opacity = 1.0,
    }) {
      final paint = Paint()..shader = fillShader;
      final tp = TextPainter(
        text: TextSpan(
          text: 'S',
          style: TextStyle(
            fontFamily: 'Fraunces',
            // Bundled fonts may be missing on some platforms; the system
            // serif fallback is fine and reads correctly italicised.
            fontFamilyFallback: const ['serif'],
            fontSize: sFontSize,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            height: 1.0,
            foreground: paint..color = paint.color.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(c.dx - tp.width / 2, c.dy - tp.height / 2),
      );
      if (strokeColor != null && strokeWidth > 0) {
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = strokeColor.withValues(alpha: opacity);
        final stp = TextPainter(
          text: TextSpan(
            text: 'S',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontFamilyFallback: const ['serif'],
              fontSize: sFontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1.0,
              foreground: strokePaint,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        stp.paint(
          canvas,
          Offset(c.dx - stp.width / 2, c.dy - stp.height / 2),
        );
      }
    }

    final sRect = Rect.fromCircle(center: c, radius: rel(48));
    drawS(
      fillShader: const LinearGradient(
        begin: Alignment(-0.6, -1.0),
        end: Alignment(0.6, 1.0),
        colors: [_Pal.sGoldTop, _Pal.sGoldMid, _Pal.sGoldBottom],
        stops: [0.0, 0.5, 1.0],
      ).createShader(sRect),
      strokeWidth: sStroke,
      strokeColor: _Pal.sStrokeBrown,
    );
    // Cream highlight pass — subtle, gives the serif depth.
    drawS(
      fillShader: LinearGradient(
        begin: const Alignment(-0.6, -1.0),
        end: const Alignment(0.6, 1.0),
        colors: [
          _Pal.goldHilite.withValues(alpha: 0.6),
          _Pal.goldHilite.withValues(alpha: 0.0),
        ],
      ).createShader(sRect),
      strokeWidth: 0,
      opacity: 0.4,
    );

    // ── Optional leaf sprout (Option 4 — "Sprouting S") ────────────────
    if (sprouting) {
      canvas.save();
      // Anchor near the top-right of the gold ring.
      final leafAnchor = Offset(c.dx + rel(20), c.dy - rel(48));
      canvas.translate(leafAnchor.dx, leafAnchor.dy);
      canvas.rotate(25 * math.pi / 180);

      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(rel(12), -rel(3), rel(14), -rel(10))
        ..quadraticBezierTo(rel(8), -rel(8), 0, 0)
        ..close();

      canvas.drawPath(
        leafPath,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFA8E0C5), _Pal.emerald],
          ).createShader(
            Rect.fromLTWH(0, -rel(10), rel(14), rel(10)),
          ),
      );
      canvas.drawPath(
        leafPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.4, rel(1.0))
          ..color = _Pal.emeraldDeep,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SabiqCoinPainter old) =>
      old.sprouting != sprouting;
}
