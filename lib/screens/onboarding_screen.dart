import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

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

  // Pages are built in build() so AppLocalizations context is available
  List<_OnboardingPage> _buildPages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _OnboardingPage(
        bgTop: const Color(0xFF0D1B2A),
        bgBottom: const Color(0xFF1A3A4A),
        illustration: const _MoonIllustration(),
        arabicText: 'السَّلَامُ عَلَيْكُم',
        transliteration: 'As-salamu Alaykum',
        title: l10n.onboarding1Title,
        subtitle: l10n.onboarding1Subtitle,
      ),
      _OnboardingPage(
        bgTop: const Color(0xFF0A0A1A),
        bgBottom: const Color(0xFF0D1F3C),
        illustration: const _DualBenefitIllustration(),
        arabicText: 'خير الدُنيا والآخرة',
        transliteration: 'Khayr al-Dunya wal-Akhirah',
        title: l10n.onboarding2Title,
        subtitle: l10n.onboarding2Subtitle,
      ),
      _OnboardingPage(
        bgTop: const Color(0xFF1A0A00),
        bgBottom: const Color(0xFF3D1F00),
        illustration: const _TasbihIllustration(),
        arabicText: 'سُبْحَانَ اللَّه',
        transliteration: 'SubhanAllah',
        title: l10n.onboarding3Title,
        subtitle: l10n.onboarding3Subtitle,
      ),
      _OnboardingPage(
        bgTop: const Color(0xFF003322),
        bgBottom: const Color(0xFF005540),
        illustration: const _QuranIllustration(),
        arabicText: 'اقْرَأْ',
        transliteration: 'Iqra — Read',
        title: l10n.onboarding4Title,
        subtitle: l10n.onboarding4Subtitle,
      ),
      _OnboardingPage(
        bgTop: const Color(0xFF2D0A3A),
        bgBottom: const Color(0xFF4A1560),
        illustration: const _SadaqahIllustration(),
        arabicText: 'صَدَقَة',
        transliteration: 'Sadaqah — Charity',
        title: l10n.onboarding5Title,
        subtitle: l10n.onboarding5Subtitle,
      ),
    ];
  }

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
    final pages = _buildPages(context);
    if (_currentPage < pages.length - 1) {
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
          transitionsBuilder:
              (_, animation, _, child) =>
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
            itemCount: _buildPages(context).length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder:
                (_, i) => _PageSlide(
                  page: _buildPages(context)[i],
                  pulseAnimation: _pulseAnimation,
                ),
          ),

          // ── Skip button (top right) ───────────────────────────────────────
          if (_currentPage < _buildPages(context).length - 1)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _goToApp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.skip,
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
                      total: _buildPages(context).length,
                      current: _currentPage,
                      activeColor: _accentColor(_currentPage),
                    ),
                    const SizedBox(height: 28),
                    // CTA button
                    _NextButton(
                      isLast: _currentPage == _buildPages(context).length - 1,
                      color: _accentColor(_currentPage),
                      onTap: _next,
                      labelContinue: AppLocalizations.of(context)!.continue_,
                      labelBegin:
                          AppLocalizations.of(context)!.beginYourJourney,
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
      Color(0xFF00D4AA), // Teal    — peace page
      Color(0xFFFFC94D), // Amber   — dual benefit page  ← NEW
      Color(0xFFFFAA00), // Gold    — zikr page
      Color(0xFF00C875), // Emerald — quran page
      Color(0xFFDD88FF), // Lavender— sadaqah page
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
                builder:
                    (_, child) => Transform.scale(
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
                      builder:
                          (_, child) => Transform.scale(
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

  const _PageDots({
    required this.total,
    required this.current,
    required this.activeColor,
  });

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
  final String labelContinue;
  final String labelBegin;

  const _NextButton({
    required this.isLast,
    required this.color,
    required this.onTap,
    required this.labelContinue,
    required this.labelBegin,
  });

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
                isLast ? labelBegin : labelContinue,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
              ] else ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.explore_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
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
    final paint =
        Paint()
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

/// NEW Page 2 — Dual Benefit (Sawab + Noor Coins for noble cause)
class _DualBenefitIllustration extends StatefulWidget {
  const _DualBenefitIllustration();
  @override
  State<_DualBenefitIllustration> createState() =>
      _DualBenefitIllustrationState();
}

class _DualBenefitIllustrationState extends State<_DualBenefitIllustration>
    with TickerProviderStateMixin {
  late AnimationController _orbitCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _orbit;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _orbit = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _orbitCtrl, curve: Curves.linear));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbit, _pulse]),
      builder: (_, __) {
        const cx = 130.0;
        const cy = 130.0;
        const orbitR = 72.0;

        // Orbiting orb positions
        final sawabX = cx + orbitR * math.cos(_orbit.value);
        final sawabY = cy + orbitR * math.sin(_orbit.value);
        final coinX = cx + orbitR * math.cos(_orbit.value + math.pi);
        final coinY = cy + orbitR * math.sin(_orbit.value + math.pi);

        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ─ Orbit ring
              Container(
                width: orbitR * 2 + 20,
                height: orbitR * 2 + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 1,
                  ),
                ),
              ),

              // ─ Centre pulsing core
              Transform.scale(
                scale: _pulse.value,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1E2A5E), Color(0xFF0A0A1A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC94D).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFC94D).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '★',
                      style: TextStyle(fontSize: 28, color: Color(0xFFFFC94D)),
                    ),
                  ),
                ),
              ),

              // ─ Orbiting Sawab orb (golden light)
              Positioned(
                left: sawabX - 22,
                top: sawabY - 22,
                child: _OrbBubble(
                  size: 44,
                  emoji: '✨',
                  color: const Color(0xFFFFC94D),
                  label: 'Sawab',
                ),
              ),

              // ─ Orbiting Coins orb (neon green)
              Positioned(
                left: coinX - 22,
                top: coinY - 22,
                child: _OrbBubble(
                  size: 44,
                  emoji: '🪙',
                  color: const Color(0xFF00E5AA),
                  label: 'Impact',
                ),
              ),

              // ─ Two benefit cards at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniCard(
                      icon: '✨',
                      title: 'Good Deed',
                      sub: 'Earn Sawab\nwith every read',
                      glow: const Color(0xFFFFC94D),
                    ),
                    const SizedBox(width: 10),
                    _MiniCard(
                      icon: '🪙',
                      title: 'Real Impact',
                      sub: 'Coins fund\nnoble causes',
                      glow: const Color(0xFF00E5AA),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrbBubble extends StatelessWidget {
  final double size;
  final String emoji;
  final Color color;
  final String label;
  const _OrbBubble({
    required this.size,
    required this.emoji,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  final Color glow;
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: glow.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: glow,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 1 — Crescent Moon + twinkling stars + shooting star
class _MoonIllustration extends StatefulWidget {
  const _MoonIllustration();
  @override
  State<_MoonIllustration> createState() => _MoonIllustrationState();
}

class _MoonIllustrationState extends State<_MoonIllustration>
    with TickerProviderStateMixin {
  late AnimationController _twinkleCtrl;
  late AnimationController _shootCtrl;
  late Animation<double> _shootAnim;

  @override
  void initState() {
    super.initState();
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shootCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shootAnim = CurvedAnimation(parent: _shootCtrl, curve: Curves.easeIn);
    // Launch a shooting star every ~3.5 s
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 3500));
      if (!mounted) return false;
      await _shootCtrl.forward(from: 0);
      return mounted;
    });
  }

  @override
  void dispose() {
    _twinkleCtrl.dispose();
    _shootCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_twinkleCtrl, _shootAnim]),
      builder: (_, __) {
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),

              // Shooting star
              if (_shootAnim.value > 0 && _shootAnim.value < 1)
                Positioned(
                  left: 30 + _shootAnim.value * 160,
                  top: 40 + _shootAnim.value * 80,
                  child: Opacity(
                    opacity: (1 - _shootAnim.value).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: 0.5,
                      child: Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),

              // Moon
              CustomPaint(
                size: const Size(140, 140),
                painter: _CrescentPainter(),
              ),

              // Twinkling stars
              ..._starData.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final phase = (i * 0.37) % 1.0;
                final tw =
                    0.5 +
                    0.5 * math.sin((_twinkleCtrl.value + phase) * 2 * math.pi);
                return Positioned(
                  left: s.$1,
                  top: s.$2,
                  child: Opacity(
                    opacity: (0.3 + 0.7 * tw).clamp(0.0, 1.0),
                    child: _StarDot(size: s.$3 * (0.7 + 0.3 * tw)),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // (left, top, size)
  static const _starData = [
    (30.0, 40.0, 5.0),
    (210.0, 30.0, 4.0),
    (230.0, 110.0, 3.0),
    (20.0, 160.0, 4.0),
    (180.0, 200.0, 5.0),
    (100.0, 15.0, 3.0),
    (50.0, 220.0, 4.0),
    (200.0, 180.0, 3.0),
    (140.0, 240.0, 3.5),
    (15.0, 80.0, 2.5),
    (245.0, 70.0, 3.0),
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

    final shadowPaint =
        Paint()
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

/// Page 3 — Tasbih Beads light up one-by-one (Zikr)
class _TasbihIllustration extends StatefulWidget {
  const _TasbihIllustration();
  @override
  State<_TasbihIllustration> createState() => _TasbihIllustrationState();
}

class _TasbihIllustrationState extends State<_TasbihIllustration>
    with TickerProviderStateMixin {
  late AnimationController _loopCtrl; // drives which bead is lit
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  static const _beadCount = 33;

  @override
  void initState() {
    super.initState();
    // One full revolution every 4.5 s
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _loopCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_loopCtrl, _pulse]),
      builder: (_, __) {
        final litUpTo = (_loopCtrl.value * _beadCount).floor();
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _TasbihPainter(litUpTo: litUpTo),
              ),
              // Centre
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _pulse.value,
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFFAA00),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$litUpTo×',
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
      },
    );
  }
}

class _TasbihPainter extends CustomPainter {
  final int litUpTo;
  const _TasbihPainter({this.litUpTo = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pathRadius = size.width * 0.42;
    const beadCount = 33;

    // String
    canvas.drawCircle(
      Offset(cx, cy),
      pathRadius,
      Paint()
        ..color = const Color(0xFFFFAA00).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int i = 0; i < beadCount; i++) {
      final angle = (i / beadCount) * 2 * math.pi - math.pi / 2;
      final bx = cx + pathRadius * math.cos(angle);
      final by = cy + pathRadius * math.sin(angle);
      final isLit = i < litUpTo;
      final isSpecial = i % 11 == 0;
      final isCurrent = i == litUpTo - 1; // the bead that just lit

      if (isCurrent) {
        // Glow burst on the current bead
        canvas.drawCircle(
          Offset(bx, by),
          14,
          Paint()
            ..color = const Color(0xFFFFAA00).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      } else if (isSpecial && isLit) {
        canvas.drawCircle(
          Offset(bx, by),
          10,
          Paint()
            ..color = const Color(0xFFFFAA00).withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawCircle(
        Offset(bx, by),
        isCurrent ? 9.5 : (isSpecial ? 8 : 5),
        Paint()
          ..color =
              isLit
                  ? (isSpecial
                      ? const Color(0xFFFFAA00)
                      : const Color(0xFFFFCC55))
                  : const Color(0xFFFFAA00).withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_TasbihPainter o) => o.litUpTo != litUpTo;
}

/// Page 4 — Quran: book closed → opens page by page
class _QuranIllustration extends StatefulWidget {
  const _QuranIllustration();
  @override
  State<_QuranIllustration> createState() => _QuranIllustrationState();
}

class _QuranIllustrationState extends State<_QuranIllustration>
    with TickerProviderStateMixin {
  // openProgress: 0 = fully closed, 1 = fully open
  late AnimationController _openCtrl;
  late Animation<double> _openAnim;
  // Glow pulse
  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  // Page-line reveal
  late AnimationController _lineCtrl;
  late Animation<double> _lines;

  @override
  void initState() {
    super.initState();
    _openCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _openAnim = CurvedAnimation(parent: _openCtrl, curve: Curves.easeOutCubic);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _lines = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOut);

    // Sequence: wait 0.6s, open book, then reveal lines
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      await _openCtrl.forward();
      if (!mounted) return;
      await _lineCtrl.forward();
      // Loop: close and reopen
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return false;
        _lineCtrl.reset();
        await _openCtrl.reverse();
        if (!mounted) return false;
        await Future.delayed(const Duration(milliseconds: 500));
        await _openCtrl.forward();
        if (!mounted) return false;
        await _lineCtrl.forward();
        return mounted;
      });
    });
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    _glowCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_openAnim, _glow, _lines]),
      builder: (_, __) {
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF00C875,
                      ).withValues(alpha: 0.28 * _glow.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Floating light motes
              ..._motes.asMap().entries.map((e) {
                final i = e.key;
                final m = e.value;
                final rise = (_openAnim.value - m.$3).clamp(0.0, 1.0);
                return Positioned(
                  left: m.$1 + math.sin(rise * 3 + i) * 6,
                  top: m.$2 - rise * 30,
                  child: Opacity(
                    opacity: (rise * (1 - rise) * 4).clamp(0.0, 0.8),
                    child: const _StarDot(size: 3),
                  ),
                );
              }),

              // Book CustomPaint
              CustomPaint(
                size: const Size(200, 150),
                painter: _AnimatedBookPainter(
                  openProgress: _openAnim.value,
                  lineReveal: _lines.value,
                  glowPulse: _glow.value,
                ),
              ),

              // Static corner stars
              Positioned(top: 28, left: 38, child: _StarDot(size: 4.5)),
              Positioned(top: 22, right: 48, child: _StarDot(size: 3.5)),
            ],
          ),
        );
      },
    );
  }

  // (left, top, delay 0-1)
  static const _motes = [
    (90.0, 130.0, 0.3),
    (140.0, 120.0, 0.5),
    (115.0, 135.0, 0.6),
    (70.0, 125.0, 0.7),
    (160.0, 130.0, 0.45),
  ];
}

class _AnimatedBookPainter extends CustomPainter {
  final double openProgress; // 0 = closed, 1 = fully open
  final double lineReveal; // 0-1 how many text lines are visible
  final double glowPulse;

  const _AnimatedBookPainter({
    required this.openProgress,
    required this.lineReveal,
    required this.glowPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    final coverColor = const Color(0xFF00C875);
    final pageColor = const Color(0xFFE8F5E9);
    final spineColor = const Color(0xFF005540);
    final lineColor = const Color(0xFF00C875).withValues(alpha: 0.45);

    // How wide each cover is when open
    final halfOpen = (w * 0.44) * openProgress;
    final bookTop = cy * 0.15;
    final bookH = h * 0.82;

    // ── Spine ──
    canvas.drawRect(
      Rect.fromLTWH(cx - 5, bookTop, 10, bookH),
      Paint()..color = spineColor,
    );

    if (openProgress < 0.05) {
      // Fully closed: just a flat rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.14, bookTop, w * 0.28, bookH),
          const Radius.circular(8),
        ),
        Paint()..color = coverColor,
      );
      return;
    }

    // ── Left cover ──
    final leftPath =
        Path()
          ..moveTo(cx, bookTop)
          ..lineTo(cx - halfOpen, bookTop + 4)
          ..lineTo(cx - halfOpen, bookTop + bookH - 4)
          ..lineTo(cx, bookTop + bookH)
          ..close();
    canvas.drawPath(leftPath, Paint()..color = coverColor);

    // ── Right cover ──
    final rightPath =
        Path()
          ..moveTo(cx, bookTop)
          ..lineTo(cx + halfOpen, bookTop + 4)
          ..lineTo(cx + halfOpen, bookTop + bookH - 4)
          ..lineTo(cx, bookTop + bookH)
          ..close();
    canvas.drawPath(rightPath, Paint()..color = coverColor);

    if (openProgress > 0.3) {
      final fade = ((openProgress - 0.3) / 0.7).clamp(0.0, 1.0);
      final pageW = halfOpen * 0.88;

      // ── Left page ──
      final lPage =
          Path()
            ..moveTo(cx - 2, bookTop + 8)
            ..lineTo(cx - pageW, bookTop + 10)
            ..lineTo(cx - pageW, bookTop + bookH - 10)
            ..lineTo(cx - 2, bookTop + bookH - 8)
            ..close();
      canvas.drawPath(
        lPage,
        Paint()..color = pageColor.withValues(alpha: fade),
      );

      // ── Right page ──
      final rPage =
          Path()
            ..moveTo(cx + 2, bookTop + 8)
            ..lineTo(cx + pageW, bookTop + 10)
            ..lineTo(cx + pageW, bookTop + bookH - 10)
            ..lineTo(cx + 2, bookTop + bookH - 8)
            ..close();
      canvas.drawPath(
        rPage,
        Paint()..color = pageColor.withValues(alpha: fade),
      );

      // ── Text lines reveal ──
      if (lineReveal > 0 && fade > 0.5) {
        final lp =
            Paint()
              ..color = lineColor.withValues(alpha: fade * lineReveal)
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke;

        final visibleLines = (lineReveal * 5).ceil().clamp(0, 5);
        for (int i = 0; i < visibleLines; i++) {
          final lineAlpha = ((lineReveal * 5) - i).clamp(0.0, 1.0);
          final y = bookTop + bookH * (0.22 + i * 0.14);
          // Left page lines
          canvas.drawLine(
            Offset(cx - pageW + 8, y),
            Offset(cx - 10, y),
            lp..color = lineColor.withValues(alpha: fade * lineAlpha),
          );
          // Right page lines
          canvas.drawLine(
            Offset(cx + 10, y),
            Offset(cx + pageW - 8, y),
            lp..color = lineColor.withValues(alpha: fade * lineAlpha),
          );
        }

        // Glow on spine when fully open
        if (openProgress > 0.9) {
          canvas.drawLine(
            Offset(cx, bookTop + 8),
            Offset(cx, bookTop + bookH - 8),
            Paint()
              ..color = const Color(
                0xFF00C875,
              ).withValues(alpha: 0.6 * glowPulse)
              ..strokeWidth = 3
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AnimatedBookPainter o) =>
      o.openProgress != openProgress ||
      o.lineReveal != lineReveal ||
      o.glowPulse != glowPulse;
}

/// Page 5 — Sadaqah: coins float up from a glowing hand, heart pulses
class _SadaqahIllustration extends StatefulWidget {
  const _SadaqahIllustration();
  @override
  State<_SadaqahIllustration> createState() => _SadaqahIllustrationState();
}

class _SadaqahIllustrationState extends State<_SadaqahIllustration>
    with TickerProviderStateMixin {
  late AnimationController _coinCtrl;
  late AnimationController _heartCtrl;
  late Animation<double> _heart;
  late AnimationController _rayCtrl;
  late Animation<double> _ray;

  @override
  void initState() {
    super.initState();

    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _heart = Tween<double>(
      begin: 0.88,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut));

    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _ray = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _rayCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _coinCtrl.dispose();
    _heartCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_coinCtrl, _heart, _ray]),
      builder: (_, __) {
        // 5 coins at different phases
        final coins = List.generate(5, (i) {
          final phase = (i / 5.0);
          final t = ((_coinCtrl.value + phase) % 1.0);
          return _CoinParticle(
            t: t,
            startX: 100.0 + (i - 2) * 18.0,
            color: i.isEven ? const Color(0xFFDD88FF) : const Color(0xFFFF99CC),
          );
        });

        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating light rays
              CustomPaint(
                size: const Size(260, 260),
                painter: _RotatingRaysPainter(phase: _ray.value),
              ),

              // Outer ring
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDD88FF).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
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
                      const Color(0xFFDD88FF).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Floating coins
              ...coins.map(
                (c) => Positioned(
                  left: c.startX - 10,
                  top: 90 - c.t * 80,
                  child: Opacity(
                    opacity: (c.t < 0.1
                            ? c.t * 10
                            : c.t > 0.65
                            ? (1 - c.t) / 0.35
                            : 1.0)
                        .clamp(0.0, 1.0),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white, c.color],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.color.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '✦',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pulsing heart + hand
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _heart.value,
                    child: ShaderMask(
                      shaderCallback:
                          (b) => const LinearGradient(
                            colors: [Color(0xFFFF69B4), Color(0xFFDD88FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(b),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('🤲', style: const TextStyle(fontSize: 36)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinParticle {
  final double t;
  final double startX;
  final Color color;
  const _CoinParticle({
    required this.t,
    required this.startX,
    required this.color,
  });
}

class _RotatingRaysPainter extends CustomPainter {
  final double phase;
  const _RotatingRaysPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint =
        Paint()
          ..color = const Color(0xFFDD88FF).withValues(alpha: 0.07)
          ..style = PaintingStyle.fill;

    const rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + phase * 2 * math.pi;
      final nextAngle =
          ((i + 0.4) / rayCount) * 2 * math.pi + phase * 2 * math.pi;
      final path =
          Path()
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
  bool shouldRepaint(_RotatingRaysPainter o) => o.phase != phase;
}
