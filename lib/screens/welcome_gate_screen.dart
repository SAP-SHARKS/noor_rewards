import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class WelcomeGateScreen extends StatefulWidget {
  final String name;
  final VoidCallback onComplete;
  const WelcomeGateScreen({super.key, required this.name, required this.onComplete});

  @override
  State<WelcomeGateScreen> createState() => _WelcomeGateScreenState();
}

class _WelcomeGateScreenState extends State<WelcomeGateScreen> with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _starCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _starCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.5)));

    _entryCtrl.forward();
    // Auto-advance after 4 seconds
    Future.delayed(const Duration(seconds: 4), () { if (mounted) widget.onComplete(); });
  }

  @override
  void dispose() {
    _entryCtrl.dispose(); _glowCtrl.dispose(); _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070E1A),
      body: Stack(children: [
        // Animated star field
        AnimatedBuilder(
          animation: _starCtrl,
          builder: (_, _) => Positioned.fill(child: CustomPaint(painter: _StarFieldPainter(_starCtrl.value))),
        ),
        // Masjid Gate illustration
        Positioned.fill(child: CustomPaint(painter: _MasjidGatePainter())),
        // Golden glow at the gate centre
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, _) => Center(child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [
              Color.lerp(const Color(0xFFFFAA00), const Color(0xFF00C875), _glowCtrl.value)!.withValues(alpha: 0.22 + _glowCtrl.value * 0.1),
              Colors.transparent,
            ])),
          )),
        ),
        // Main content
        FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 80),
                // Crescent + mosque icon stack
                Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFFFAA00).withValues(alpha: 0.25), Colors.transparent,
                      ]),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFAA00), Color(0xFFFFD54F)]).createShader(r),
                    child: const Icon(Icons.mosque_rounded, size: 110, color: Colors.white),
                  ),
                ]),
                const SizedBox(height: 36),
                // Arabic greeting
                Text('مَرْحَبًا', style: GoogleFonts.amiri(fontSize: 46, color: const Color(0xFFFFAA00), fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 4),
                Text('Marhaban', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white30, letterSpacing: 3)),
                const SizedBox(height: 24),
                // Name
                RichText(text: TextSpan(children: [
                  TextSpan(text: AppLocalizations.of(context)!.welcomeUser(widget.name).split(widget.name).first, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w400, color: Colors.white70)),
                  TextSpan(text: widget.name, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  TextSpan(text: ' 🌙', style: GoogleFonts.outfit(fontSize: 26)),
                ])),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.gatesOfNoor,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 15, color: Colors.white54, height: 1.7),
                ),
                const SizedBox(height: 48),
                // Enter button
                GestureDetector(
                  onTap: widget.onComplete,
                  child: Container(
                    width: double.infinity, height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(colors: [Color(0xFFFFAA00), Color(0xFFFF8F00)]),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFAA00).withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 10))],
                    ),
                    child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(AppLocalizations.of(context)!.enterTheGarden, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.black87, size: 20),
                    ])),
                  ),
                ),
              ]),
            )),
          ),
        ),
      ]),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final double t;
  _StarFieldPainter(this.t);

  static final _rng = math.Random(42);
  static final _stars = List.generate(80, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final twinkle = (math.sin(t * 2 * math.pi + i * 0.7) + 1) / 2;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.1 + twinkle * 0.5)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), 1.2 + twinkle * 1.0, paint);
    }
  }
  @override bool shouldRepaint(covariant _StarFieldPainter old) => old.t != t;
}

class _MasjidGatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF0A2E1F).withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.75, w, h * 0.25), groundPaint);

    // Wall
    final wallPaint = Paint()..color = const Color(0xFF0D2137).withValues(alpha: 0.8);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.45, w, h * 0.30), wallPaint);

    // Gold accent line on top of wall
    canvas.drawRect(Rect.fromLTWH(0, h * 0.445, w, 2.5), Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.4));

    // Left minaret
    _drawMinaret(canvas, Offset(w * 0.12, h * 0.2), w * 0.06, h * 0.55);
    // Right minaret
    _drawMinaret(canvas, Offset(w * 0.88, h * 0.2), w * 0.06, h * 0.55);

    // Central arch / gate
    _drawArch(canvas, size);

    // Small decorative arches (left and right of centre)
    _drawSmallArch(canvas, Offset(w * 0.22, h * 0.75), w * 0.12);
    _drawSmallArch(canvas, Offset(w * 0.78, h * 0.75), w * 0.12);

    // Stars above minarets
    _drawCrescent(canvas, Offset(w * 0.12, h * 0.18));
    _drawCrescent(canvas, Offset(w * 0.88, h * 0.18));
  }

  void _drawMinaret(Canvas canvas, Offset top, double width, double bottom) {
    final r = Rect.fromCenter(center: Offset(top.dx, (top.dy + bottom) / 2), width: width, height: bottom - top.dy);
    final paint = Paint()..color = const Color(0xFF0F2A40).withValues(alpha: 0.9);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), paint);
    // Gold border
    final borderPaint = Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), borderPaint);
    // Minaret tip (triangle)
    final tipPath = Path()..moveTo(top.dx - width / 2, top.dy)..lineTo(top.dx + width / 2, top.dy)..lineTo(top.dx, top.dy - width * 1.4)..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.6));
    // Balcony
    canvas.drawRect(Rect.fromCenter(center: Offset(top.dx, top.dy + (bottom - top.dy) * 0.25), width: width * 1.5, height: 4), Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.3));
  }

  void _drawArch(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = size.width * 0.44;
    final archBottom = size.height * 0.76;
    final archTop = size.height * 0.38;
    final archLeft = cx - w / 2;
    final archRight = cx + w / 2;
    final r = w / 2;

    final bgPaint = Paint()..color = const Color(0xFF061020).withValues(alpha: 0.85);
    final path = Path()
      ..moveTo(archLeft, archBottom)
      ..lineTo(archLeft, archTop + r)
      ..arcToPoint(Offset(cx, archTop - r * 0.3), radius: Radius.circular(r), clockwise: false)
      ..arcToPoint(Offset(archRight, archTop + r), radius: Radius.circular(r), clockwise: false)
      ..lineTo(archRight, archBottom)
      ..close();
    canvas.drawPath(path, bgPaint);

    // Gold glow inside arch
    final glowPaint = Paint()..shader = RadialGradient(center: Alignment.bottomCenter, colors: [
      const Color(0xFFFFAA00).withValues(alpha: 0.15), Colors.transparent,
    ]).createShader(Rect.fromLTWH(archLeft, archTop, w, archBottom - archTop));
    canvas.drawPath(path, glowPaint);

    // Gold arch border
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Geometric dots along arch
    final dotPaint = Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.5);
    for (int i = 0; i <= 10; i++) {
      final a = math.pi + i * math.pi / 10;
      final dotX = cx + (r - 6) * math.cos(a);
      final dotY = (archTop + r) + (r - 6) * math.sin(a);
      canvas.drawCircle(Offset(dotX, dotY), 2.5, dotPaint);
    }
  }

  void _drawSmallArch(Canvas canvas, Offset centre, double width) {
    final r = width / 2;
    final top = centre.dy - r * 2.2;
    final path = Path()
      ..moveTo(centre.dx - r, centre.dy)
      ..lineTo(centre.dx - r, top + r)
      ..arcToPoint(Offset(centre.dx, top - r * 0.2), radius: Radius.circular(r), clockwise: false)
      ..arcToPoint(Offset(centre.dx + r, top + r), radius: Radius.circular(r), clockwise: false)
      ..lineTo(centre.dx + r, centre.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0D2137).withValues(alpha: 0.9));
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawCrescent(Canvas canvas, Offset centre) {
    final r = 9.0;
    final paint = Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.8);
    final rect = Rect.fromCircle(center: centre, radius: r * 2);
    canvas.saveLayer(rect, Paint());
    canvas.drawCircle(centre, r, paint);
    canvas.drawCircle(Offset(centre.dx + r * 0.55, centre.dy - r * 0.1), r * 0.82, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override bool shouldRepaint(_) => false;
}
