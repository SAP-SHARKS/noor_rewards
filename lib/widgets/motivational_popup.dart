import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NoorMotivationalPopup
// Full-screen inspiration popup, inspired by Quranly / Madacamp / SweetCoin.
// Shows randomly, with 3 rotating CTA types.
// ─────────────────────────────────────────────────────────────────────────────

enum _CtaType { quran, share, dhikr }

class _Card {
  final String arabic;        // Optional Arabic ayah / hadith text
  final String quote;         // English motivational quote
  final String source;        // Source label (e.g. "Quran 9:119")
  final List<Color> gradient; // Background gradient
  final _CtaType cta;

  const _Card({
    required this.arabic,
    required this.quote,
    required this.source,
    required this.gradient,
    required this.cta,
  });
}

const _kCards = [
  // ── Quran CTA cards ──────────────────────────────────────────────────────
  _Card(
    arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    quote: 'Verily, with hardship comes ease.\nEvery trial is a door to something greater.',
    source: 'Quran • Al-Inshirah 94:6',
    gradient: [Color(0xFF0D4F5E), Color(0xFF0D9488), Color(0xFF14B8A6)],
    cta: _CtaType.quran,
  ),
  _Card(
    arabic: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    quote: 'Whoever puts their trust in Allah —\nHe is sufficient for them.',
    source: 'Quran • At-Talaq 65:3',
    gradient: [Color(0xFF1A1060), Color(0xFF4C35A0), Color(0xFF7C5CBF)],
    cta: _CtaType.quran,
  ),
  _Card(
    arabic: 'وَلَذِكْرُ اللَّهِ أَكْبَرُ',
    quote: 'The remembrance of Allah is the greatest.\nLet your heart find rest in His name.',
    source: 'Quran • Al-Ankabut 29:45',
    gradient: [Color(0xFF0A3D2E), Color(0xFF0D7A55), Color(0xFF22C55E)],
    cta: _CtaType.dhikr,
  ),
  _Card(
    arabic: 'فَاذْكُرُونِي أَذْكُرْكُمْ',
    quote: 'Remember Me — I will remember you.\nYour Dhikr rises to the heavens.',
    source: 'Quran • Al-Baqarah 2:152',
    gradient: [Color(0xFF3D1A0A), Color(0xFFB45309), Color(0xFFF59E0B)],
    cta: _CtaType.dhikr,
  ),
  _Card(
    arabic: 'وَإِن تَعُدُّوا نِعْمَةَ اللَّهِ لَا تُحْصُوهَا',
    quote: 'If you count the blessings of Allah,\nyou could never enumerate them.',
    source: 'Quran • An-Nahl 16:18',
    gradient: [Color(0xFF1A0A3D), Color(0xFF7C3AED), Color(0xFFEC4899)],
    cta: _CtaType.quran,
  ),

  // ── Share CTA cards ───────────────────────────────────────────────────────
  _Card(
    arabic: '',
    quote: 'Make your time precious.\nShare goodness with a friend today —\nevery good deed shared is a sadaqah.',
    source: 'The Prophet ﷺ said: "Guide others to good, and you get its reward."',
    gradient: [Color(0xFF0F1E3A), Color(0xFF1D4ED8), Color(0xFF60A5FA)],
    cta: _CtaType.share,
  ),
  _Card(
    arabic: '',
    quote: 'One message can change a life.\nInvite a friend to walk the path of noor.',
    source: 'Hadith: "The best of people are those most beneficial to others."',
    gradient: [Color(0xFF1A0814), Color(0xFFBE185D), Color(0xFFF472B6)],
    cta: _CtaType.share,
  ),
  _Card(
    arabic: 'مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ',
    quote: 'Whoever guides someone to goodness\nwill have the same reward as the one who does it.',
    source: 'Sahih Muslim',
    gradient: [Color(0xFF0A2A1A), Color(0xFF059669), Color(0xFF34D399)],
    cta: _CtaType.share,
  ),

  // ── Dhikr CTA cards ───────────────────────────────────────────────────────
  _Card(
    arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    quote: 'Verily, in the remembrance of Allah\ndo hearts find rest.',
    source: 'Quran • Ar-Ra\'d 13:28',
    gradient: [Color(0xFF1A1000), Color(0xFFCA8A04), Color(0xFFFBBF24)],
    cta: _CtaType.dhikr,
  ),
  _Card(
    arabic: '',
    quote: 'Your akhirah is being built\none moment of dhikr at a time.\nDon\'t let this moment pass.',
    source: 'Remind yourself — time is the most precious sadaqah.',
    gradient: [Color(0xFF0D1A2E), Color(0xFF0369A1), Color(0xFF38BDF8)],
    cta: _CtaType.dhikr,
  ),
  _Card(
    arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    quote: 'SubhanAllah wa bihamdih.\nA single tasbih plants a tree\nin your paradise.',
    source: 'Sahih Al-Bukhari',
    gradient: [Color(0xFF0A1F0A), Color(0xFF15803D), Color(0xFF86EFAC)],
    cta: _CtaType.dhikr,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Public helper — call this from initState after a random delay
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showMotivationalPopup(
  BuildContext context, {
  required VoidCallback onGoQuran,
  required VoidCallback onGoDhikr,
  required VoidCallback onShare,
}) {
  final rng  = math.Random();
  final card = _kCards[rng.nextInt(_kCards.length)];
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'motivational_popup',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 520),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _MotivationalPopupBody(
      card: card,
      onGoQuran: onGoQuran,
      onGoDhikr: onGoDhikr,
      onShare:   onShare,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Body widget
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationalPopupBody extends StatefulWidget {
  final _Card card;
  final VoidCallback onGoQuran, onGoDhikr, onShare;
  const _MotivationalPopupBody({
    required this.card,
    required this.onGoQuran,
    required this.onGoDhikr,
    required this.onShare,
  });
  @override
  State<_MotivationalPopupBody> createState() => _MotivationalPopupBodyState();
}

class _MotivationalPopupBodyState extends State<_MotivationalPopupBody>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  final _rng = math.Random();

  // Pre-generated particle positions (relative 0..1)
  final _particles = List.generate(18, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final size = MediaQuery.of(context).size;

    // CTA config
    final (String ctaLabel, IconData ctaIcon, Color ctaColor) = switch (card.cta) {
      _CtaType.quran => ('Open Quran', Icons.menu_book_rounded, const Color(0xFF0D9488)),
      _CtaType.dhikr => ('Dua & Azkaar', Icons.favorite_rounded, const Color(0xFFF59E0B)),
      _CtaType.share => ('Share with Friends', Icons.share_rounded, const Color(0xFF3B82F6)),
    };

    void onCtaTap() {
      Navigator.of(context).pop();
      switch (card.cta) {
        case _CtaType.quran: widget.onGoQuran(); break;
        case _CtaType.dhikr: widget.onGoDhikr(); break;
        case _CtaType.share: widget.onShare();   break;
      }
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: size.height * 0.88),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: card.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: card.gradient.last.withValues(alpha: 0.45),
                  blurRadius: 48,
                  spreadRadius: 6,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // ── Animated particle layer ──────────────────────────────
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _ParticlePainter(
                          particles: _particles,
                          progress: _particleCtrl.value,
                          accent: card.gradient.last,
                        ),
                      ),
                    ),
                  ),

                  // ── Decorative arc/ring ───────────────────────────────────
                  Positioned(
                    top: -80, right: -80,
                    child: Container(
                      width: 260, height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 40,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50, left: -60,
                    child: Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 30,
                        ),
                      ),
                    ),
                  ),

                  // ── Content ───────────────────────────────────────────────
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Close button
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white70, size: 18),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Glowing icon badge
                            FadeTransition(
                              opacity: _textFade,
                              child: Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: card.gradient.last.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    card.cta == _CtaType.quran
                                        ? Icons.menu_book_rounded
                                        : card.cta == _CtaType.dhikr
                                            ? Icons.favorite_rounded
                                            : Icons.share_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Arabic text
                            if (card.arabic.isNotEmpty)
                              SlideTransition(
                                position: _textSlide,
                                child: FadeTransition(
                                  opacity: _textFade,
                                  child: Text(
                                    card.arabic,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiri(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.7,
                                    ),
                                  ),
                                ),
                              ),

                            if (card.arabic.isNotEmpty) const SizedBox(height: 18),

                            // Decorative divider line
                            FadeTransition(
                              opacity: _textFade,
                              child: Row(children: [
                                Expanded(child: Container(height: 0.5, color: Colors.white24)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white54,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Expanded(child: Container(height: 0.5, color: Colors.white24)),
                              ]),
                            ),

                            const SizedBox(height: 20),

                            // Quote text
                            SlideTransition(
                              position: _textSlide,
                              child: FadeTransition(
                                opacity: _textFade,
                                child: Text(
                                  widget.card.quote,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.55,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Source label
                            FadeTransition(
                              opacity: _textFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18)),
                                ),
                                child: Text(
                                  card.source,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Primary CTA button
                            FadeTransition(
                              opacity: _textFade,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    onCtaTap();
                                  },
                                  icon: Icon(ctaIcon, size: 20),
                                  label: Text(ctaLabel),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: ctaColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18)),
                                    elevation: 0,
                                    textStyle: GoogleFonts.outfit(
                                        fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // "Maybe later" dismiss
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Maybe later',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle data model
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  final double x, y, size, speed, phase;
  _Particle()
      : x     = math.Random().nextDouble(),
        y     = math.Random().nextDouble(),
        size  = math.Random().nextDouble() * 4 + 1.5,
        speed = math.Random().nextDouble() * 0.4 + 0.2,
        phase = math.Random().nextDouble() * math.pi * 2;
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle painter — soft floating bokeh circles
// ─────────────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color accent;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase / (math.pi * 2)) % 1.0;
      final dy = -t * size.height * 0.35; // float upward
      final opacity = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.25;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height + dy),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
