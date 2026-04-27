// lib/widgets/noor_offline.dart
//
// NoorOffline — gorgeous "no internet / loading" widget
// Features a tasbih bead animation: beads drop one by one onto a curved string,
// a gentle crescent crown at the top, and soft pulsing text below.
// Pure Flutter — no external packages needed.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Public API ────────────────────────────────────────────────────────────────

enum NoorOfflineMode {
  noInternet,   // "No internet connection"
  loading,      // "Loading…"  — used for slow / delayed data fetch
  error,        // "Something went wrong"
}

class NoorOfflineWidget extends StatefulWidget {
  final NoorOfflineMode mode;
  final String? customMessage;
  final VoidCallback? onRetry;
  final Color? accentColor;

  const NoorOfflineWidget({
    super.key,
    this.mode = NoorOfflineMode.noInternet,
    this.customMessage,
    this.onRetry,
    this.accentColor,
  });

  @override
  State<NoorOfflineWidget> createState() => _NoorOfflineWidgetState();
}

class _NoorOfflineWidgetState extends State<NoorOfflineWidget>
    with TickerProviderStateMixin {
  // Main bead drop controller — drives the whole sequence
  late AnimationController _beadCtrl;
  // Gentle sway for the whole tasbih after drop
  late AnimationController _swayCtrl;
  // Pulse for the glow aura
  late AnimationController _glowCtrl;
  // Text fade
  late AnimationController _textCtrl;
  // Retry button pulse
  late AnimationController _btnCtrl;

  // Each bead has its own progress (0.0 → 1.0)
  static const _totalBeads = 11;

  @override
  void initState() {
    super.initState();

    _beadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _swayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Once beads finish dropping, start the sway and reveal text
    _beadCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _swayCtrl.repeat(reverse: true);
        _textCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _beadCtrl.dispose();
    _swayCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Color get _accent =>
      widget.accentColor ??
      (widget.mode == NoorOfflineMode.error
          ? const Color(0xFFE53935)
          : const Color(0xFFC9921A)); // Y4 honey-deep

  String get _title {
    if (widget.customMessage != null) return widget.customMessage!;
    switch (widget.mode) {
      case NoorOfflineMode.noInternet:
        return 'No Internet Connection';
      case NoorOfflineMode.loading:
        return 'Connecting…';
      case NoorOfflineMode.error:
        return 'Something Went Wrong';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case NoorOfflineMode.noInternet:
        return 'This feature needs internet.\nCheck your Wi-Fi or mobile data.';
      case NoorOfflineMode.loading:
        return 'Fetching your data…\nHanging on for a moment';
      case NoorOfflineMode.error:
        return 'An unexpected error occurred.\nTap retry to try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tasbih animation ───────────────────────────────────────────
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([_beadCtrl, _swayCtrl, _glowCtrl]),
              builder: (_, __) => CustomPaint(
                painter: _TasbihPainter(
                  beadProgress: _beadCtrl.value,
                  swayProgress: _swayCtrl.value,
                  glowPulse: _glowCtrl.value,
                  accent: _accent,
                  totalBeads: _totalBeads,
                ),
                size: const Size(double.infinity, 220),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title ──────────────────────────────────────────────────────
          FadeTransition(
            opacity: _textCtrl,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _textCtrl,
                curve: Curves.easeOut,
              )),
              child: Column(children: [
                Text(
                  _title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1C1E),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF8E8E93),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),

          if (widget.onRetry != null) ...[
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textCtrl,
              child: AnimatedBuilder(
                animation: _btnCtrl,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 + _btnCtrl.value * 0.03,
                  child: child,
                ),
                child: GestureDetector(
                  onTap: widget.onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _accent,
                          _accent.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Custom Painter ─────────────────────────────────────────────────────────────

class _TasbihPainter extends CustomPainter {
  final double beadProgress; // 0.0 → 1.0  (drives bead drop sequencing)
  final double swayProgress; // 0.0 → 1.0  (pendulum sway after drop)
  final double glowPulse;    // 0.0 → 1.0  (aura pulsing)
  final Color accent;
  final int totalBeads;

  _TasbihPainter({
    required this.beadProgress,
    required this.swayProgress,
    required this.glowPulse,
    required this.accent,
    required this.totalBeads,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topY = 28.0;

    // ── Sway angle ─────────────────────────────────────────────────────
    // Damped pendulum: amplitude fades as beadProgress was completed
    final swayAngle =
        math.sin(swayProgress * math.pi) * 0.06;

    canvas.save();
    // Pivot at the crown tip
    canvas.translate(cx, topY);
    canvas.rotate(swayAngle);
    canvas.translate(-cx, -topY);

    _drawCrown(canvas, size, cx, topY);
    _drawString(canvas, size, cx, topY);
    _drawBeads(canvas, size, cx, topY);
    _drawDecorBead(canvas, size, cx, topY); // The large oval bead at the knot

    canvas.restore();
  }

  // ── Crescent / moon crown at top ────────────────────────────────────
  void _drawCrown(Canvas canvas, Size size, double cx, double topY) {
    final glowR = 18.0 + glowPulse * 6;
    // Outer glow
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.15 + glowPulse * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, topY + 4), glowR, glowPaint);

    // Main circle (gold/teal gradient)
    final centerOval = Offset(cx, topY + 4);
    final circlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE08A),
          accent,
          accent.withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.55, 1.0],
        center: const Alignment(-0.3, -0.4),
      ).createShader(Rect.fromCircle(center: centerOval, radius: 14));
    canvas.drawCircle(centerOval, 13, circlePaint);

    // Crescent cutout (white filled slightly offset circle)
    final cutPaint = Paint()..color = const Color(0xFFF7F3EE);
    canvas.drawCircle(Offset(cx + 5, topY + 1), 10, cutPaint);

    // Star dot
    final starPaint = Paint()
      ..color = const Color(0xFFFFE08A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + 9, topY + 7), 2.5, starPaint);

    // Hook line connecting crown to string
    final hookPaint = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, topY + 17),
      Offset(cx, topY + 30),
      hookPaint,
    );
  }

  // ── Curved string/thread ────────────────────────────────────────────
  void _drawString(Canvas canvas, Size size, double cx, double topY) {

    // How many beads have arrived — used to draw string only as far as dropped
    final beadsDone = (beadProgress * totalBeads).floor();
    final partialFrac = (beadProgress * totalBeads) - beadsDone;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < beadsDone; i++) {
      final t0 = i / totalBeads;
      final t1 = (i + 1) / totalBeads;
      final p0 = _beadPos(t0, cx, topY, size);
      final p1 = _beadPos(t1, cx, topY, size);

      // Gradient thread color
      paint.shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.6),
          accent.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromPoints(p0, p1));

      canvas.drawLine(p0, p1, paint);
    }

    // Partial last segment (the bead currently falling)
    if (beadsDone < totalBeads && partialFrac > 0) {
      final t0 = beadsDone / totalBeads;
      final t1 = (beadsDone + partialFrac) / totalBeads;
      final p0 = _beadPos(t0, cx, topY, size);
      final p1 = _beadPos(t0 + (t1 - t0) * partialFrac, cx, topY, size);
      paint.shader = null;
      paint.color = accent.withValues(alpha: 0.25);
      canvas.drawLine(p0, p1, paint);
    }
  }

  // ── Individual beads ────────────────────────────────────────────────
  void _drawBeads(Canvas canvas, Size size, double cx, double topY) {

    for (int i = 0; i < totalBeads; i++) {
      // Each bead starts dropping when its "slot" opens
      final beadStart = i / totalBeads;
      final beadEnd = (i + 1) / totalBeads;
      if (beadProgress < beadStart) break;

      // Local progress of this bead's drop (0→1)
      final local =
          ((beadProgress - beadStart) / (beadEnd - beadStart)).clamp(0.0, 1.0);

      // Ease-out bounce for each bead
      final eased = _bounceOut(local);

      // Final resting position
      final t = (i + 0.5) / totalBeads;
      final restPos = _beadPos(t, cx, topY, size);

      // Drop from above the crown
      final dropStartY = topY - 60.0;
      final dy = restPos.dy - dropStartY;
      final currentPos = Offset(restPos.dx, dropStartY + dy * eased);

      final radius = _beadRadius(i);
      _drawSingleBead(canvas, currentPos, radius, i, local);
    }
  }

  void _drawSingleBead(Canvas canvas, Offset center, double r, int index, double alpha) {
    // Glow
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.18 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, r + 4, glowPaint);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
        Rect.fromCenter(
            center: center.translate(0, r * 0.7),
            width: r * 1.4,
            height: r * 0.5),
        shadowPaint);

    // Bead body — alternating warm pearl and accent
    final isAccent = (index % 3 == 0);
    final beadPaint = Paint()
      ..shader = RadialGradient(
        colors: isAccent
            ? [
                const Color(0xFFFFEEAA),
                accent,
                accent.withValues(alpha: 0.85),
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFE8DECC),
                const Color(0xFFB8A898),
              ],
        stops: const [0.0, 0.5, 1.0],
        center: const Alignment(-0.4, -0.45),
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, beadPaint);

    // Specular highlight
    final hiPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center.translate(-r * 0.28, -r * 0.28), r * 0.22, hiPaint);
  }

  // ── The decorative large oval bead at the knot (bottom) ─────────────
  void _drawDecorBead(Canvas canvas, Size size, double cx, double topY) {
    if (beadProgress < 0.9) return;
    final alpha = ((beadProgress - 0.9) / 0.1).clamp(0.0, 1.0);
    final pos = _beadPos(1.0, cx, topY, size);
    final r = 13.0;

    // Oval (wider than tall)
    final rect = Rect.fromCenter(center: pos, width: r * 2.2, height: r * 1.5);

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.3 * alpha + glowPulse * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(rect.inflate(6), glowPaint);

    final beadPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFEEAA),
          accent,
          accent.withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.45, 1.0],
        center: const Alignment(-0.3, -0.35),
      ).createShader(rect);
    canvas.drawOval(rect, beadPaint);

    // Calligraphy-style line pattern (simplified dots)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 * alpha);
    for (int d = 0; d < 3; d++) {
      canvas.drawCircle(
          pos.translate(-8.0 + d * 8.0, 0), 1.8, dotPaint);
    }
  }

  // ── Utility: position on the tasbih loop ────────────────────────────
  // Maps t ∈ [0, 1] to a curved teardrop/loop path
  Offset _beadPos(double t, double cx, double topY, Size size) {
    // Simple oval teardrop loop
    const loopWidth = 80.0;
    const loopHeight = 155.0;
    final originY = topY + 44.0;

    // t=0 → top of loop, t=0.5 → bottom, t=1 → back to top (knot bead)
    final angle = (t * math.pi * 2) - math.pi / 2;
    final x = cx + loopWidth * math.cos(angle);
    final y = originY + loopHeight * 0.5 * math.sin(angle) +
        loopHeight * 0.35;

    return Offset(x, y);
  }

  double _beadRadius(int index) {
    if (index % 5 == 0) return 10.0; // Marker beads (larger)
    return 7.5;
  }

  // ── Ease: bounce-out ────────────────────────────────────────────────
  static double _bounceOut(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      final t2 = t - 1.5 / d1;
      return n1 * t2 * t2 + 0.75;
    } else if (t < 2.5 / d1) {
      final t2 = t - 2.25 / d1;
      return n1 * t2 * t2 + 0.9375;
    } else {
      final t2 = t - 2.625 / d1;
      return n1 * t2 * t2 + 0.984375;
    }
  }

  @override
  bool shouldRepaint(_TasbihPainter old) =>
      old.beadProgress != beadProgress ||
      old.swayProgress != swayProgress ||
      old.glowPulse != glowPulse;
}

// ── Convenience scaffold wrapper ───────────────────────────────────────────────
// Drop this in any Scaffold body for a full-screen offline state

class NoorOfflineScreen extends StatelessWidget {
  final NoorOfflineMode mode;
  final String? message;
  final VoidCallback? onRetry;

  const NoorOfflineScreen({
    super.key,
    this.mode = NoorOfflineMode.noInternet,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: NoorOfflineWidget(
              mode: mode,
              customMessage: message,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inline loader — for use inside cards/sections ─────────────────────────────
// Shows a compact tasbih shimmer with a single pulsing bead on a thread

class NoorInlineLoader extends StatefulWidget {
  final double height;
  final Color? color;
  final String? label;

  const NoorInlineLoader({
    super.key,
    this.height = 120,
    this.color,
    this.label,
  });

  @override
  State<NoorInlineLoader> createState() => _NoorInlineLoaderState();
}

class _NoorInlineLoaderState extends State<NoorInlineLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? const Color(0xFFC9921A); // Y4 honey-deep
    return SizedBox(
      height: widget.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _InlineBeadPainter(progress: _ctrl.value, accent: accent),
              size: const Size(160, 40),
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.label!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineBeadPainter extends CustomPainter {
  final double progress;
  final Color accent;
  const _InlineBeadPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const beadCount = 9;
    const spacing = 16.0;
    final startX = (size.width - (beadCount - 1) * spacing) / 2;

    // Thread line removed — beads float freely

    for (int i = 0; i < beadCount; i++) {
      final x = startX + i * spacing;
      // Wave ripple: each bead offset in phase
      final phase = (progress - i / beadCount * 0.7) % 1.0;
      final lift = math.sin(phase * math.pi * 2) * 7.0;

      final isAccent = (i % 4 == 0);
      final r = isAccent ? 7.0 : 5.5;

      // Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, cy + r * 0.9), width: r * 1.2, height: r * 0.4),
        Paint()..color = Colors.black.withValues(alpha: 0.10)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      final beadPaint = Paint()
        ..shader = RadialGradient(
          colors: isAccent
              ? [const Color(0xFFFFE8A0), accent, accent.withValues(alpha: 0.75)]
              : [const Color(0xFFFFF3CC), const Color(0xFFE8D48A), const Color(0xFFC9A84C)],
          stops: const [0.0, 0.5, 1.0],
          center: const Alignment(-0.3, -0.4),
        ).createShader(Rect.fromCircle(center: Offset(x, cy - lift), radius: r));

      canvas.drawCircle(Offset(x, cy - lift), r, beadPaint);
      // Highlight
      canvas.drawCircle(
        Offset(x - r * 0.3, cy - lift - r * 0.3),
        r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_InlineBeadPainter old) => old.progress != progress;
}
