import 'dart:io';

void main() {
  final f = File('lib/screens/dhikr_screen.dart');
  var bytes = f.readAsBytesSync();
  var content = String.fromCharCodes(bytes);
  
  // Find _ThreeVesselsState start (the OLD one — with _pulseCtrl; single)
  final stateStart = content.indexOf('class _ThreeVesselsState extends State<_ThreeVessels>');
  if (stateStart == -1) { print('ERROR: ThreeVesselsState not found'); return; }
  
  // Find _ThreeVesselsPainter end — its shouldRepaint closing }
  // The painter ends with its specific fields
  final painterEnd = content.indexOf('  bool shouldRepaint(_ThreeVesselsPainter o)');
  if (painterEnd == -1) { print('ERROR: ThreeVesselsPainter shouldRepaint not found'); return; }
  
  // Find the closing } after the shouldRepaint
  var bracePos = content.indexOf('\n}', painterEnd);
  if (bracePos == -1) bracePos = content.indexOf('\r\n}', painterEnd);
  final removeEnd = bracePos + 3; // include the \r\n}
  
  print('Removing from $stateStart to $removeEnd (${removeEnd - stateStart} chars)');
  print('Starts with: ${content.substring(stateStart, stateStart + 60)}');
  print('Ends with: ${content.substring(removeEnd - 20, removeEnd)}');
  
  // Replace with new ThreeVessels implementation
  const newCode = '''class _ThreeVesselsState extends State<_ThreeVessels> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl, _growCtrl, _glowCtrl;
  late Animation<double> _pulse, _grow, _glow;
  double _prevProgress = 0.0;

  static const _rows = [
    (label: 'Wellbeing',  sub: 'in your body',                    hex: 0xFF0D8A6A, isGood: true),
    (label: 'Wellbeing',  sub: 'in your hearing',                  hex: 0xFF1565C0, isGood: true),
    (label: 'Wellbeing',  sub: 'in your sight',                    hex: 0xFF6A1B9A, isGood: true),
    (label: 'Protection', sub: 'from disbelief and poverty',       hex: 0xFFC84B31, isGood: false),
    (label: 'Protection', sub: 'from the punishment of the grave', hex: 0xFF8B4513, isGood: false),
  ];

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
              CustomPaint(painter: _VesselDotPainter(isDark: isDark)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _rows.length; i++)
                      _buildRow(rowIdx: i, total: _rows.length, progress: progress, isDark: isDark),
                  ],
                ),
              ),
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

  Widget _buildRow({required int rowIdx, required int total, required double progress, required bool isDark}) {
    final row = _rows[rowIdx];
    final accent = Color(row.hex);
    final threshold = rowIdx / total;
    final rowP = ((progress - threshold) * total).clamp(0.0, 1.0);
    return AnimatedOpacity(
      opacity: rowP,
      duration: const Duration(milliseconds: 350),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.11 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: isDark ? 0.35 : 0.22), width: 1.2),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: accent.withValues(alpha: rowP * (isDark ? 0.9 : 0.75)))),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: '' + row.label + '  ',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: rowP * (isDark ? 1.0 : 0.9)))),
                  TextSpan(text: row.sub,
                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white70.withValues(alpha: rowP)
                          : const Color(0xFF2D3748).withValues(alpha: rowP * 0.75))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VesselDotPainter extends CustomPainter {
  final bool isDark;
  const _VesselDotPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF0D6B52)).withValues(alpha: isDark ? 0.04 : 0.05);
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_VesselDotPainter o) => o.isDark != isDark;
}
''';
  
  content = content.substring(0, stateStart) + newCode + content.substring(removeEnd);
  f.writeAsStringSync(content);
  print('Done! New code length: ${newCode.length}');
}
