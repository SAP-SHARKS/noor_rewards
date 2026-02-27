import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'start_journey_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for each onboarding slide
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage {
  final Color bgTop;
  final Color bgBottom;
  final Widget illustration;
  final String arabicText;
  final String transliteration;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.bgTop,
    required this.bgBottom,
    required this.illustration,
    required this.arabicText,
    required this.transliteration,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Onboarding Screen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      bgTop: const Color(0xFF0D1B2A),
      bgBottom: const Color(0xFF1A3A4A),
      illustration: const _MoonIllustration(),
      arabicText: 'السَّلَامُ عَلَيْكُم',
      transliteration: 'As-salamu Alaykum',
      title: 'Peace Be\nUpon You',
      subtitle:
          'Welcome to Noor Rewards — where every good deed is a step closer to Allah\'s mercy and light.',
    ),
    _OnboardingPage(
      bgTop: const Color(0xFF1A0A00),
      bgBottom: const Color(0xFF3D1F00),
      illustration: const _TasbihIllustration(),
      arabicText: 'سُبْحَانَ اللَّه',
      transliteration: 'SubhanAllah',
      title: 'Remember\nAllah Always',
      subtitle:
          'A heart that remembers Allah finds peace in every breath. Track your daily zikr and let every bead count.',
    ),
    _OnboardingPage(
      bgTop: const Color(0xFF003322),
      bgBottom: const Color(0xFF005540),
      illustration: const _QuranIllustration(),
      arabicText: 'اقْرَأْ',
      transliteration: 'Iqra — Read',
      title: 'Reflect &\nGrow Daily',
      subtitle:
          'The Quran is a guide for all of mankind. Unlock verses, daily duas, and reflections tailored for your journey.',
    ),
    _OnboardingPage(
      bgTop: const Color(0xFF2D0A3A),
      bgBottom: const Color(0xFF4A1560),
      illustration: const _SadaqahIllustration(),
      arabicText: 'صَدَقَة',
      transliteration: 'Sadaqah — Charity',
      title: 'Give &\nEarn Blessings',
      subtitle:
          'Sadaqah extinguishes sin as water extinguishes fire. Earn rewards for every act of charity and kindness.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, _) => const StartJourneyScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Page content ──────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _PageSlide(
              page: _pages[i],
              pulseAnimation: _pulseAnimation,
            ),
          ),

          // ── Skip button (top right) ───────────────────────────────────────
          if (_currentPage < _pages.length - 1)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _goToApp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom controls ───────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress dots
                    _PageDots(
                      total: _pages.length,
                      current: _currentPage,
                      activeColor: _accentColor(_currentPage),
                    ),
                    const SizedBox(height: 28),
                    // CTA button
                    _NextButton(
                      isLast: _currentPage == _pages.length - 1,
                      color: _accentColor(_currentPage),
                      onTap: _next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(int page) {
    const accents = [
      Color(0xFF00D4AA), // Teal — peace page
      Color(0xFFFFAA00), // Gold — zikr page
      Color(0xFF00C875), // Emerald — quran page
      Color(0xFFDD88FF), // Lavender — sadaqah page
    ];
    return accents[page];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Page Slide
// ─────────────────────────────────────────────────────────────────────────────
class _PageSlide extends StatelessWidget {
  final _OnboardingPage page;
  final Animation<double> pulseAnimation;

  const _PageSlide({required this.page, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [page.bgTop, page.bgBottom],
        ),
      ),
      child: Stack(
        children: [
          // Background geometric pattern
          Positioned.fill(
            child: CustomPaint(painter: _IslamicPatternPainter()),
          ),

          // Radial glow behind illustration
          Positioned(
            top: size.height * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: pulseAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Illustration — takes all remaining space ────────────────
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (_, child) => Transform.scale(
                        scale: pulseAnimation.value,
                        child: child,
                      ),
                      child: page.illustration,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Text content — natural height, no Expanded ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Arabic
                      Text(
                        page.arabicText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Transliteration
                      Text(
                        page.transliteration,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white38,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      Text(
                        page.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white60,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dynamic bottom spacer: adapts to controls height + safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 130),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Dots
// ─────────────────────────────────────────────────────────────────────────────
class _PageDots extends StatelessWidget {
  final int total;
  final int current;
  final Color activeColor;

  const _PageDots(
      {required this.total, required this.current, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next / Begin Button
// ─────────────────────────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final bool isLast;
  final Color color;
  final VoidCallback onTap;

  const _NextButton(
      {required this.isLast, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLast ? 'Begin Your Journey' : 'Continue',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.black87, size: 20),
              ] else ...[
                const SizedBox(width: 8),
                const Icon(Icons.explore_rounded,
                    color: Colors.black87, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background: Subtle Islamic Geometric Pattern
// ─────────────────────────────────────────────────────────────────────────────
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 80.0;
    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        _drawStar(canvas, Offset(x, y), 28, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    const innerRadius = 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points - math.pi / 2;
      final r = i.isEven ? radius : radius * innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustrations
// ─────────────────────────────────────────────────────────────────────────────

/// Page 1 — Crescent Moon + Stars (Peace)
class _MoonIllustration extends StatelessWidget {
  const _MoonIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.15), width: 1),
            ),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.1), width: 1),
            ),
          ),
          // Moon
          CustomPaint(
            size: const Size(140, 140),
            painter: _CrescentPainter(),
          ),
          // Stars
          ..._starPositions.map((pos) => Positioned(
                left: pos.dx,
                top: pos.dy,
                child: _StarDot(size: pos.distance > 100 ? 4 : 6),
              )),
        ],
      ),
    );
  }

  static const _starPositions = [
    Offset(30, 40),
    Offset(210, 30),
    Offset(230, 110),
    Offset(20, 160),
    Offset(180, 200),
    Offset(100, 15),
    Offset(50, 220),
    Offset(200, 180),
  ];
}

class _StarDot extends StatelessWidget {
  final double size;
  const _StarDot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: size * 2,
            spreadRadius: size * 0.5,
          ),
        ],
      ),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;

    final shadowPaint = Paint()
      ..color = const Color(0xFF00D4AA).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Glow shadow (outside saveLayer so it's visible)
    canvas.drawCircle(Offset(cx, cy), r, shadowPaint);

    // Use saveLayer so BlendMode.clear actually punches a transparent hole
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 2);
    canvas.saveLayer(rect, Paint());

    // Draw full moon in teal
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xFF00D4AA),
    );

    // Punch out crescent with BlendMode.clear — NO dark circle
    canvas.drawCircle(
      Offset(cx + r * 0.42, cy - r * 0.08),
      r * 0.85,
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Page 2 — Tasbih Beads (Zikr)
class _TasbihIllustration extends StatelessWidget {
  const _TasbihIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular bead path
          CustomPaint(
            size: const Size(240, 240),
            painter: _TasbihPainter(),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Color(0xFFFFAA00), size: 48),
              const SizedBox(height: 6),
              Text(
                '99×',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TasbihPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pathRadius = size.width * 0.42;
    const beadCount = 33;

    final linePaint = Paint()
      ..color = const Color(0xFFFFAA00).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw circle path (string)
    canvas.drawCircle(Offset(cx, cy), pathRadius, linePaint);

    // Draw beads
    for (int i = 0; i < beadCount; i++) {
      final angle = (i / beadCount) * 2 * math.pi - math.pi / 2;
      final bx = cx + pathRadius * math.cos(angle);
      final by = cy + pathRadius * math.sin(angle);
      final isSpecial = i % 11 == 0; // Every 11th bead is special (33÷3=11)

      final beadPaint = Paint()
        ..color = isSpecial
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFFAA00).withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;

      if (isSpecial) {
        // Glow
        canvas.drawCircle(
          Offset(bx, by),
          9,
          Paint()
            ..color = const Color(0xFFFFAA00).withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawCircle(Offset(bx, by), isSpecial ? 8 : 5, beadPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Page 3 — Quran Book (Knowledge)
class _QuranIllustration extends StatelessWidget {
  const _QuranIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00C875).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Open book icon
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 120),
                    painter: _OpenBookPainter(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Decorative geometric divider
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GeoLine(),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00C875),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GeoLine(),
                ],
              ),
            ],
          ),
          // Stars around the book
          Positioned(top: 30, left: 40, child: _StarDot(size: 5)),
          Positioned(top: 20, right: 50, child: _StarDot(size: 4)),
          Positioned(bottom: 40, left: 30, child: _StarDot(size: 3)),
          Positioned(bottom: 35, right: 40, child: _StarDot(size: 5)),
        ],
      ),
    );
  }
}

class _GeoLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 1,
      color: const Color(0xFF00C875).withValues(alpha: 0.5),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final h = size.height;

    final coverPaint = Paint()..color = const Color(0xFF00C875);
    final pagePaint = Paint()..color = const Color(0xFFE8F5E9);
    final spinePaint = Paint()
      ..color = const Color(0xFF005540)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF00C875).withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Left cover
    final leftCover = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx * 0.08, cy * 0.1, cx * 0.84, h * 0.82),
      topLeft: const Radius.circular(8),
      bottomLeft: const Radius.circular(8),
    );
    canvas.drawRRect(leftCover, coverPaint);

    // Right cover (mirror)
    final rightCover = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx + cx * 0.08, cy * 0.1, cx * 0.84, h * 0.82),
      topRight: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(rightCover, coverPaint);

    // Left page
    final leftPage = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx * 0.14, cy * 0.18, cx * 0.74, h * 0.7),
      topLeft: const Radius.circular(4),
      bottomLeft: const Radius.circular(4),
    );
    canvas.drawRRect(leftPage, pagePaint);

    // Right page
    final rightPage = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx + cx * 0.12, cy * 0.18, cx * 0.74, h * 0.7),
      topRight: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    canvas.drawRRect(rightPage, pagePaint);

    // Spine
    canvas.drawRect(
      Rect.fromLTWH(cx - 4, cy * 0.1, 8, h * 0.82),
      spinePaint,
    );

    // Lines on left page
    final lineStart = cx * 0.22;
    final lineEnd = cx * 0.82;
    for (int i = 0; i < 5; i++) {
      final y = cy * 0.38 + i * (h * 0.1);
      canvas.drawLine(Offset(lineStart, y), Offset(lineEnd, y), linePaint);
    }
    // Lines on right page
    for (int i = 0; i < 5; i++) {
      final y = cy * 0.38 + i * (h * 0.1);
      canvas.drawLine(
          Offset(cx + cx * 0.18, y), Offset(cx + cx * 0.8, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Page 4 — Sadaqah / Charity (Heart + Light Rays)
class _SadaqahIllustration extends StatelessWidget {
  const _SadaqahIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Light rays background
          CustomPaint(
            size: const Size(260, 260),
            painter: _LightRaysPainter(),
          ),
          // Outer ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFDD88FF).withValues(alpha: 0.3), width: 1.5),
            ),
          ),
          // Inner glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFDD88FF).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Heart icon
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF69B4), Color(0xFFDD88FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Coin/reward icons row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RewardChip(emoji: '✨'),
                  const SizedBox(width: 6),
                  _RewardChip(emoji: '🌙'),
                  const SizedBox(width: 6),
                  _RewardChip(emoji: '🤲'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String emoji;
  const _RewardChip({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border:
            Border.all(color: const Color(0xFFDD88FF).withValues(alpha: 0.3)),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
    );
  }
}

class _LightRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = const Color(0xFFDD88FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi;
      final nextAngle = ((i + 0.4) / rayCount) * 2 * math.pi;
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + size.width * 0.7 * math.cos(angle),
          cy + size.height * 0.7 * math.sin(angle),
        )
        ..lineTo(
          cx + size.width * 0.7 * math.cos(nextAngle),
          cy + size.height * 0.7 * math.sin(nextAngle),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
