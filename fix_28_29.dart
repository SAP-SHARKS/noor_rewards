import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  var content = f.readAsStringSync();

  // ── 1. Fix #29 background (light) ──
  const oldBg29 = '                    colors: isDark\r\n                        ? [const Color(0xFF0D1B2A), const Color(0xFF1A3A4A)]\r\n                        : [const Color(0xFF0C3547), const Color(0xFF0D6B52)],';
  const newBg29 = '                    colors: isDark\r\n                        ? [const Color(0xFF1A2E3A), const Color(0xFF1E3D30)]\r\n                        : [const Color(0xFFF0F7FF), const Color(0xFFE8F5F0)],';
  if (content.contains(oldBg29)) {
    content = content.replaceFirst(oldBg29, newBg29);
    print('Fixed #29 background');
  } else {
    print('WARNING: bg29 not found - checking for CR/LF issues');
    // Try without \r
    final oldBg29n = '                    colors: isDark\n                        ? [const Color(0xFF0D1B2A), const Color(0xFF1A3A4A)]\n                        : [const Color(0xFF0C3547), const Color(0xFF0D6B52)],';
    final newBg29n = '                    colors: isDark\n                        ? [const Color(0xFF1A2E3A), const Color(0xFF1E3D30)]\n                        : [const Color(0xFFF0F7FF), const Color(0xFFE8F5F0)],';
    if (content.contains(oldBg29n)) {
      content = content.replaceFirst(oldBg29n, newBg29n);
      print('Fixed #29 background (LF)');
    } else {
      print('ERROR: bg29 truly not found');
    }
  }

  // ── 2. Update text coloring logic in _buildLine ──
  final oldText = '''    } else if (lineIndex == 0) {\r\n      textColor = Colors.white.withValues(alpha: lineProgress);\r\n      fontSize = 22;\r\n    } else {\r\n      textColor = Colors.white.withValues(alpha: lineProgress * 0.85);\r\n      fontSize = isBig ? 19 : 15;\r\n    }''';
  final newText = '''    } else if (lineIndex == 0) {\r\n      textColor = isDark\r\n          ? Colors.white.withValues(alpha: lineProgress)\r\n          : const Color(0xFF0C3547).withValues(alpha: lineProgress);\r\n      fontSize = 22;\r\n    } else {\r\n      textColor = isDark\r\n          ? Colors.white.withValues(alpha: lineProgress * 0.85)\r\n          : const Color(0xFF0C4A3E).withValues(alpha: lineProgress * 0.85);\r\n      fontSize = isBig ? 19 : 15;\r\n    }''';
  if (content.contains(oldText)) {
    content = content.replaceFirst(oldText, newText);
    print('Fixed #29 text colors');
  } else {
    // Try LF
    final oldTextN = oldText.replaceAll('\r\n', '\n');
    final newTextN = newText.replaceAll('\r\n', '\n');
    if (content.contains(oldTextN)) {
      content = content.replaceFirst(oldTextN, newTextN);
      print('Fixed #29 text colors (LF)');
    } else {
      print('WARNING: text color block not found');
    }
  }

  // ── 3. pass isDark to _buildLine ──
  final oldCall = '                        isComplete: widget.isComplete,\r\n                      ),';
  final newCall = '                        isComplete: widget.isComplete,\r\n                        isDark: isDark,\r\n                      ),';
  if (content.contains(oldCall)) {
    content = content.replaceFirst(oldCall, newCall);
    print('Added isDark param to _buildLine call');
  }

  final oldSig = '    required bool isComplete,\r\n  }) {\r\n    // Each line reveals when progress passes its threshold';
  final newSig = '    required bool isComplete,\r\n    bool isDark = false,\r\n  }) {\r\n    // Each line reveals when progress passes its threshold';
  if (content.contains(oldSig)) {
    content = content.replaceFirst(oldSig, newSig);
    print('Added isDark param to _buildLine signature');
  } else {
    final oldSigN = oldSig.replaceAll('\r\n', '\n');
    final newSigN = newSig.replaceAll('\r\n', '\n');
    if (content.contains(oldSigN)) {
      content = content.replaceFirst(oldSigN, newSigN);
      print('Added isDark param (LF)');
    } else {
      print('WARNING: _buildLine signature not found');
    }
  }

  // ── 4. Replace _ThreeVessels with text-based widget ──
  // Find start/end markers
  String? startMarker;
  for (final candidate in [
    '// =============================================================================\r\n// 💧 Three Vessels',
    '// =============================================================================\n// 💧 Three Vessels',
  ]) {
    if (content.contains(candidate)) { startMarker = candidate; break; }
  }

  String? endMarker;
  final endCandidates = [
    '  bool shouldRepaint(_ThreeVesselsPainter o) =>\r\n      o.progress != progress || o.pulse != pulse ||\r\n      o.starPhase != starPhase || o.particlePhase != particlePhase ||\r\n      o.isComplete != isComplete || o.pointsToday != pointsToday ||\r\n      o.punchScale != punchScale || o.shockPhase != shockPhase ||\r\n      o.flowPhase != flowPhase;\r\n}',
    '  bool shouldRepaint(_ThreeVesselsPainter o) =>\n      o.progress != progress || o.pulse != pulse ||\n      o.starPhase != starPhase || o.particlePhase != particlePhase ||\n      o.isComplete != isComplete || o.pointsToday != pointsToday ||\n      o.punchScale != punchScale || o.shockPhase != shockPhase ||\n      o.flowPhase != flowPhase;\n}',
  ];
  for (final c in endCandidates) {
    if (content.contains(c)) { endMarker = c; break; }
  }

  if (startMarker == null) { print('ERROR: ThreeVessels start marker not found'); }
  else if (endMarker == null) { print('ERROR: ThreeVessels end marker not found'); }
  else {
    final startIdx = content.indexOf(startMarker!);
    final endIdx   = content.indexOf(endMarker!);
    final removeEnd = endIdx + endMarker!.length;

    final newWidget = '''// =============================================================================
// 💚 Body Hearing Sight — Allah's gift of wellbeing (morning_28 / evening_28)
// =============================================================================
class _ThreeVessels extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final int tapCount;
  final int pointsToday;

  const _ThreeVessels({
    required this.progress, required this.isComplete,
    required this.tapCount, this.pointsToday = 0,
  });

  @override
  State<_ThreeVessels> createState() => _ThreeVesselsState();
}

class _ThreeVesselsState extends State<_ThreeVessels> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _growCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _grow = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _prevProgress = widget.progress; _growCtrl.value = widget.progress;
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_ThreeVessels old) {
    super.didUpdateWidget(old);
    if (widget.progress != _prevProgress) {
      _growCtrl.animateTo(widget.progress);
      _prevProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _growCtrl.dispose(); _glowCtrl.dispose();
    super.dispose();
  }

  // [title, subtitle, accentHex, isWellbeing]
  static const _rows = [
    ('Wellbeing',   'in your body',                       0xFF0D8A6A, true),
    ('Wellbeing',   'in your hearing',                    0xFF1565C0, true),
    ('Wellbeing',   'in your sight',                      0xFF6A1B9A, true),
    ('Protection',  'from disbelief and poverty',         0xFFC84B31, false),
    ('Protection',  'from the punishment of the grave',   0xFF8B4513, false),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _growCtrl, _glowCtrl]),
      builder: (_, __) {
        final progress = _grow.value;
        return SizedBox(
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Light background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF1A2030), const Color(0xFF1A2828)]
                        : [const Color(0xFFF5F9FF), const Color(0xFFEDF8F3)],
                  ),
                ),
              ),

              // Subtle dot pattern
              CustomPaint(painter: _DotGridPainter(isDark: isDark)),

              // Rows of blessings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _rows.length; i++) ...[
                      _buildRow(
                        context,
                        rowIdx: i,
                        total: _rows.length,
                        progress: progress,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),

              // Completion glow bar
              if (widget.isComplete)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        const Color(0xFF26C485).withValues(alpha: _glow.value * 0.85),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, {
    required int rowIdx, required int total,
    required double progress, required bool isDark,
  }) {
    final (title, subtitle, accentHex, isWellbeing) = _rows[rowIdx];
    final accent = Color(accentHex);
    final threshold = rowIdx / total;
    final rowProgress = ((progress - threshold) * total).clamp(0.0, 1.0);

    return AnimatedOpacity(
      opacity: rowProgress.clamp(0.0, 1.0),
      duration: const Duration(milliseconds: 350),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.11 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: rowProgress * (isDark ? 0.9 : 0.75)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: isWellbeing ? 'Wellbeing  ' : 'Protection  ',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? accent.withValues(alpha: rowProgress)
                          : accent.withValues(alpha: rowProgress * 0.9),
                    ),
                  ),
                  TextSpan(
                    text: subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white70.withValues(alpha: rowProgress)
                          : const Color(0xFF2D3748).withValues(alpha: rowProgress * 0.75),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  const _DotGridPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF0D6B52))
          .withValues(alpha: isDark ? 0.04 : 0.05);
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_DotGridPainter o) => o.isDark != isDark;
}''';

    content = content.substring(0, startIdx) + newWidget + content.substring(removeEnd);
    print('Replaced _ThreeVessels (${removeEnd - startIdx} chars → ${newWidget.length} chars)');
  }

  f.writeAsStringSync(content);
  print('\nAll done!');
}
