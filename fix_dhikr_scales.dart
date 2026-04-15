import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('lib/screens/dhikr_screen.dart');
  String text = file.readAsStringSync(encoding: utf8);

  final startI = text.indexOf('// ?? Unparalleled');
  final endI = text.indexOf('// ?? Sunrise Glory');
  
  if (startI != -1 && endI != -1 && startI < endI) {
    // We need to keep the Sunrise Glory line, so we find the start of its block:
    final realEnd = text.lastIndexOf('// =================================', endI);

    final before = text.substring(0, startI);
    final after = text.substring(realEnd != -1 ? realEnd : endI);

    final String freedSlavesCode = """// ?? Released Slaves (????? ????) — 10 slaves freed
// =============================================================================
class _FreedSlaves extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _FreedSlaves({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_FreedSlaves> createState() => _FreedSlavesState();
}

class _FreedSlavesState extends State<_FreedSlaves> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _growCtrl;
  late Animation<double> _grow;
  double _prevProgress = 0.0;
  late AnimationController _starCtrl;
  late AnimationController _pCtrl;
  late Animation<double> _pAnim;
  int _prevTap = 0;
  late AnimationController _punchCtrl;
  late Animation<double> _punch;
  late AnimationController _shockCtrl;
  late Animation<double> _shock;

  final List<_Particle> _particles = List.generate(16, (i) => _Particle(seed: i + 2000));

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress;
    _growCtrl.value = widget.progress;
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100))..repeat(reverse: true);
    _pCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _pAnim = CurvedAnimation(parent: _pCtrl, curve: Curves.easeOut);
    _prevTap = widget.tapCount;
    _punchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punch = TweenSequence<double>([TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10).chain(CurveTween(curve: Curves.easeOut)), weight: 40), TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 30), TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30)]).animate(_punchCtrl);
    _shockCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shock = CurvedAnimation(parent: _shockCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_FreedSlaves old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) { _growCtrl.animateTo(widget.progress); _prevProgress = widget.progress; }
    if (widget.tapCount != _prevTap) { _prevTap = widget.tapCount; for (final p in _particles) { p.reset(); } _pCtrl.forward(from: 0); _punchCtrl.forward(from: 0); _shockCtrl.forward(from: 0); }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _growCtrl.dispose(); _starCtrl.dispose(); _pCtrl.dispose(); _punchCtrl.dispose(); _shockCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _starCtrl, _pCtrl, _punchCtrl, _shockCtrl]),
      builder: (_, __) => SizedBox(height: 290, child: CustomPaint(painter: _FreedSlavesPainter(progress: _grow.value, pulse: _pulse.value, starPhase: _starCtrl.value, particlePhase: _pAnim.value, particles: _particles, isComplete: widget.isComplete, pointsToday: widget.pointsToday, punchScale: _punch.value, shockPhase: _shock.value))),
    );
  }
}

class _FreedSlavesPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double starPhase;
  final double particlePhase;
  final List<_Particle> particles;
  final bool isComplete;
  final int pointsToday;
  final double punchScale;
  final double shockPhase;

  static const _goldColor = Color(0xFFD4AF37);
  static const _soulColor = Color(0xFF38BDF8);

  const _FreedSlavesPainter({
    required this.progress, required this.pulse, required this.starPhase, required this.particlePhase, required this.particles, required this.isComplete, this.pointsToday = 0, this.punchScale = 1.0, this.shockPhase = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height; final cx = w / 2; final cy = h * 0.45;
    _paintLightBg(canvas, w, h, progress: progress);

    const starPos = [(0.10, 0.07), (0.24, 0.14), (0.40, 0.05), (0.56, 0.12), (0.72, 0.06), (0.86, 0.15), (0.48, 0.20), (0.30, 0.22), (0.66, 0.18), (0.14, 0.20)];
    final sp = Paint();
    for (int i = 0; i < starPos.length; i++) {
        final tw = 0.5 + 0.5 * math.sin(starPhase * math.pi * 2 + i * 0.8);
        final starAlpha = (0.10 + progress * 0.25 + 0.30 * tw * progress).clamp(0.0, 0.6);
        sp.color = Colors.white.withValues(alpha: starAlpha);
        canvas.drawCircle(Offset(starPos[i].\$1 * w, starPos[i].\$2 * h), 0.7 + tw * 0.9, sp);
    }

    canvas.save(); canvas.translate(cx, cy); canvas.scale(punchScale, punchScale); canvas.translate(-cx, -cy);
    _drawCage(canvas, cx, cy, w);
    _drawFreedSouls(canvas, cx, cy, w);
    canvas.restore();

    if (shockPhase > 0 && shockPhase < 1) {
        final ringA = (1.0 - shockPhase) * 0.35;
        canvas.drawCircle(Offset(cx, cy), w * 0.38 * shockPhase, Paint()..color = _soulColor.withValues(alpha: ringA)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1.0 - shockPhase));
    }

    if (particlePhase > 0 && particlePhase < 1) {
        for (final p in particles) {
            final t = (particlePhase / p.speed).clamp(0.0, 1.0); if (t <= 0) continue;
            final angle = p.x * math.pi * 2; final dist = 15 + t * w * 0.28;
            final px = cx + math.cos(angle) * dist, py = cy + math.sin(angle) * dist * 0.7 - t * 15;
            final a = (1.0 - t) * 0.70; final pSize = p.size * (1.0 - t * 0.3);
            canvas.drawCircle(Offset(px, py), pSize + 2, Paint()..color = _soulColor.withValues(alpha: a * 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
            canvas.drawCircle(Offset(px, py), pSize, Paint()..color = _soulColor.withValues(alpha: a));
            canvas.drawCircle(Offset(px, py), pSize * 0.35, Paint()..color = Colors.white.withValues(alpha: a * 0.6));
        }
    }

    final pct = (progress * 100).round();
    final label = isComplete ? '????????? ?????????' : '\$pct%';
    final tp2 = TextPainter(text: TextSpan(text: label, style: _illusArabic(14, isComplete ? _soulColor : const Color(0xFF5A6570))), textDirection: TextDirection.rtl)..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, h * 0.76));

    if (pointsToday > 0) {
      final tp3 = TextPainter(text: TextSpan(text: '+\$pointsToday pts', style: const TextStyle(color: _soulColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, shadows: [Shadow(color: _soulColor, blurRadius: 6)])), textDirection: TextDirection.ltr)..layout();
      final bx = cx - (tp3.width + 28) / 2, by = h * 0.76 + tp2.height + 4;
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, tp3.width + 28, tp3.height + 14), const Radius.circular(10));
      canvas.drawRRect(rr, Paint()..color = _soulColor.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(rr, Paint()..color = _soulColor.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 0.7);
      tp3.paint(canvas, Offset(bx + 14, by + 4));
    }
  }

  void _drawCage(Canvas canvas, double cx, double cy, double w) {
    final cageAlpha = 0.50 + progress * 0.30;
    final paint = Paint()..color = _goldColor.withValues(alpha: cageAlpha)..style = PaintingStyle.stroke..strokeWidth = 2.0;

    final cageW = w * 0.22;
    final cageH = 65.0;
    final baseY = cy + 25;

    canvas.drawCircle(Offset(cx, baseY - cageH/2), cageH, Paint()..color = _goldColor.withValues(alpha: 0.08 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    canvas.drawLine(Offset(cx - cageW / 2 - 5, baseY), Offset(cx + cageW / 2 + 5, baseY), paint..strokeWidth = 4.0);

    final numBars = 5;
    for (int i=0; i<numBars; i++) {
        final bx = cx - cageW/2 + (cageW / (numBars - 1)) * i;
        if (i == 2) continue; 
        canvas.drawLine(Offset(bx, baseY - 2), Offset(bx, baseY - cageH * 0.6), paint..strokeWidth = 2.0);
    }

    final domePath = Path()..moveTo(cx - cageW / 2, baseY - cageH * 0.5)..quadraticBezierTo(cx, baseY - cageH * 1.3, cx + cageW / 2, baseY - cageH * 0.5);
    canvas.drawPath(domePath, paint..strokeWidth = 2.5);

    canvas.drawLine(Offset(cx - cageW/2, baseY - cageH * 0.5), Offset(cx + cageW/2, baseY - cageH * 0.5), paint..strokeWidth = 2.0);
    canvas.drawLine(Offset(cx - cageW/2, baseY - cageH * 0.25), Offset(cx + cageW/2, baseY - cageH * 0.25), paint..strokeWidth = 1.0);
    canvas.drawCircle(Offset(cx, baseY - cageH * 0.95 - 6), 6, paint..strokeWidth = 2.0);

    canvas.save();
    canvas.translate(cx - cageW * 0.15, baseY);
    final doorOpenPhase = (progress * 3.0).clamp(0.0, 1.0);
    final doorAngle = -math.pi * 0.75 * doorOpenPhase;
    canvas.scale(1.0, 1.0); 
    // Just rotate
    canvas.rotate(doorAngle * 0.6);
    canvas.drawRect(Rect.fromLTWH(0, -cageH * 0.5, cageW * 0.3, cageH * 0.5), paint..strokeWidth = 1.5);
    canvas.restore();
  }

  void _drawFreedSouls(Canvas canvas, double cx, double cy, double w) {
    for (int i = 0; i < 10; i++) {
        final spawnP = i / 11.0; 
        if (progress <= spawnP) continue;
        final flyP = ((progress - spawnP) / (1.0 - spawnP)).clamp(0.0, 1.0);
        
        final startX = cx; final startY = cy + 15; 
        final targetAngle = -3.14159/2 + (i - 4.5) * 0.18; 
        final maxDist = 90.0 + (i % 3) * 20.0;
        final dist = maxDist * (math.sin(flyP * math.pi / 2));

        final floatWobbleX = math.sin(starPhase * math.pi * 2 + i) * 6.0;
        final floatWobbleY = math.cos(starPhase * math.pi * 2 + i) * 4.0;

        final px = startX + math.cos(targetAngle) * dist + floatWobbleX * flyP;
        final py = startY + math.sin(targetAngle) * dist - flyP * 40.0 + floatWobbleY * flyP;

        final alpha = (flyP < 0.1 ? flyP * 10 : 1.0) * (isComplete ? pulse : 1.0) * 0.8;

        canvas.drawCircle(Offset(px, py), 4 + 1.5 * pulse, Paint()..color = _soulColor.withValues(alpha: alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        canvas.drawCircle(Offset(px, py), 2, Paint()..color = Colors.white.withValues(alpha: alpha));

        final flap = math.sin(starPhase * math.pi * 12 + i * 1.5) * 6.0 + 2.0; 
        final wingSpan = 7.0 + flyP * 3.0;
        final wingPath = Path()
          ..moveTo(px - wingSpan, py - flap)
          ..quadraticBezierTo(px - wingSpan/2, py + 2, px, py)
          ..quadraticBezierTo(px + wingSpan/2, py + 2, px + wingSpan, py - flap);
        
        canvas.drawPath(wingPath, Paint()..color = Colors.white.withValues(alpha: alpha * 0.9)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_FreedSlavesPainter o) => o.progress != progress || o.pulse != pulse || o.starPhase != starPhase || o.particlePhase != particlePhase || o.isComplete != isComplete || o.pointsToday != pointsToday || o.punchScale != punchScale || o.shockPhase != shockPhase;
}
""";
    
    text = before + freedSlavesCode + "\n" + after;
    file.writeAsStringSync(text, encoding: utf8);
    print('Successfully found and replaced Unparalleled Scales');
  } else {
    print('Could not find Unparalleled Scales. startI = $startI, endI = $endI');
  }
}
