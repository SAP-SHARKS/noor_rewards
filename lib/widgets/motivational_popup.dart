import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/y4_theme.dart';
import 'noor_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NoorMotivationalPopup
// Full-screen inspiration popup, inspired by Quranly / Madacamp / SweetCoin.
// Repeats every ~3 minutes. User can permanently silence with "Don't Disturb".
// ─────────────────────────────────────────────────────────────────────────────

enum _CtaType { quran, share, dhikr, boost }

class _Card {
  final String arabic;
  final String quote;
  final String source;
  final List<Color> gradient;
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
  // ── Quran CTA ─────────────────────────────────────────────────────────────
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

  // ── Share CTA ─────────────────────────────────────────────────────────────
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

  // ── Dhikr CTA ────────────────────────────────────────────────────────────
  _Card(
    arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    quote: 'Verily, in the remembrance of Allah\ndo hearts find rest.',
    source: "Quran • Ar-Ra'd 13:28",
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

  // ── Boost CTA ────────────────────────────────────────────────────────────
  _Card(
    arabic: 'وَاعْلَمُوا أَنَّمَا أَمْوَالُكُمْ وَأَوْلَادُكُمْ فِتْنَةٌ',
    quote: 'Your time is your most\nprecious asset. Invest it wisely\nin what endures forever.',
    source: 'Quran • Al-Anfal 8:28',
    gradient: [Color(0xFF1A0D00), Color(0xFFB45309), Color(0xFFFFAA00)],
    cta: _CtaType.boost,
  ),
  _Card(
    arabic: '',
    quote: 'Every minute in worship\nis a seed planted in Jannah.\nHow many have you planted today?',
    source: 'The Prophet ﷺ said: "Take advantage of five before five."',
    gradient: [Color(0xFF071A0F), Color(0xFF065F46), Color(0xFF34D399)],
    cta: _CtaType.boost,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Public helper — random motivational popup (Quran / Dhikr / Share / Boost)
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showMotivationalPopup(
  BuildContext context, {
  required VoidCallback onGoQuran,
  required VoidCallback onGoDhikr,
  required VoidCallback onShare,
  required VoidCallback onDoNotDisturb,
  VoidCallback? onGoBoost,
}) {
  final card = _kCards[math.Random().nextInt(_kCards.length)];
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
      onGoQuran:       onGoQuran,
      onGoDhikr:       onGoDhikr,
      onShare:         onShare,
      onGoBoost:       onGoBoost ?? onGoQuran,
      onDoNotDisturb:  onDoNotDisturb,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// showValidationRewardPopup — dopamine hit shown immediately after coin seal
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showValidationRewardPopup(
  BuildContext context, {
  required int pointsEarned,
  required int bonusPoints,
  VoidCallback? onContinue,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'validation_reward',
    // Warm brown-tinted barrier — sits softer against the honey card
    barrierColor: Y4.ink.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _ValidationRewardBody(
      pointsEarned: pointsEarned,
      bonusPoints: bonusPoints,
      onContinue: onContinue,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ValidationRewardBody — celebratory popup with points & bonus breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _ValidationRewardBody extends StatefulWidget {
  final int pointsEarned, bonusPoints;
  final VoidCallback? onContinue;
  const _ValidationRewardBody({
    required this.pointsEarned,
    required this.bonusPoints,
    this.onContinue,
  });
  @override
  State<_ValidationRewardBody> createState() => _ValidationRewardBodyState();
}

class _ValidationRewardBodyState extends State<_ValidationRewardBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final total  = widget.pointsEarned + widget.bonusPoints;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                decoration: BoxDecoration(
                  // Y4 honey wash gradient — warm celebration card
                  gradient: const LinearGradient(
                    colors: [Y4.cream, Y4.bg, Y4.butter],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Y4.honeyDeep.withValues(alpha: 0.30), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Y4.honeyDeep.withValues(alpha: 0.30), blurRadius: 40, spreadRadius: 2),
                    BoxShadow(color: Y4.honey.withValues(alpha: 0.30), blurRadius: 20),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // — Verified-seal icon (honey gradient)
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [Y4.honey, Y4.honeyDeep]),
                        border: Border.all(color: Y4.honeyDeep, width: 2),
                        boxShadow: [BoxShadow(color: Y4.honeyDeep.withValues(alpha: 0.40), blurRadius: 24)],
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),

                    // — Title (Fraunces serif — matches dashboard hero)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Coins Sealed! ماشاء الله',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: Y4.display(
                          fontSize: 26, fontWeight: FontWeight.w500,
                          color: Y4.ink, letterSpacing: -0.3, height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You have been rewarded for\nyour consistency today!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13, color: Y4.inkSoft, height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // — Points breakdown card (white surface on honey wash)
                    Container(
                      decoration: BoxDecoration(
                        color: Y4.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Y4.border),
                        boxShadow: [BoxShadow(
                          color: Y4.ink.withValues(alpha: 0.04),
                          blurRadius: 8, offset: const Offset(0, 2),
                        )],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Column(children: [
                        _RewardRow('⚡ Validation Points', '+${widget.pointsEarned} pts', Y4.honeyDeep),
                        if (widget.bonusPoints > 0) ...[
                          const SizedBox(height: 10),
                          _RewardRow('🔥 Streak Bonus', '+${widget.bonusPoints} pts', Y4.honeyDeep),
                          const SizedBox(height: 10),
                          const Divider(color: Y4.border, height: 1),
                          const SizedBox(height: 10),
                          _RewardRow('✨ Total Earned', '+$total pts', Y4.ink, big: true),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // — CTA (honey-deep filled button)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.maybePop(context);
                          widget.onContinue?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Y4.honeyDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text('Alhamdulillah! 🤲',
                          style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
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
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool big;
  const _RewardRow(this.label, this.value, this.color, {this.big = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.outfit(
        fontSize: big ? 14 : 13,
        fontWeight: big ? FontWeight.w800 : FontWeight.w500,
        color: big ? Y4.ink : Y4.inkSoft,
      )),
      Text(value, style: GoogleFonts.outfit(
        fontSize: big ? 16 : 14,
        fontWeight: FontWeight.w800,
        color: color,
      )),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// showNoorBoostPopup — always shows a Noor Boost card (used post-validation)
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showNoorBoostPopup(
  BuildContext context, {
  required VoidCallback onGoQuran,
  required VoidCallback onGoDhikr,
  VoidCallback? onGoInvite,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'noor_boost_popup',
    barrierColor: Colors.black.withValues(alpha: 0.80),
    transitionDuration: const Duration(milliseconds: 480),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _NoorBoostPopupBody(
      onGoQuran:  onGoQuran,
      onGoDhikr:  onGoDhikr,
      onGoInvite: onGoInvite,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Body widget — standard motivational popup
// ─────────────────────────────────────────────────────────────────────────────
class _MotivationalPopupBody extends StatefulWidget {
  final _Card card;
  final VoidCallback onGoQuran, onGoDhikr, onShare, onGoBoost, onDoNotDisturb;
  const _MotivationalPopupBody({
    required this.card,
    required this.onGoQuran,
    required this.onGoDhikr,
    required this.onShare,
    required this.onGoBoost,
    required this.onDoNotDisturb,
  });
  @override
  State<_MotivationalPopupBody> createState() => _MotivationalPopupBodyState();
}

class _MotivationalPopupBodyState extends State<_MotivationalPopupBody>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _textCtrl;
  late Animation<double>   _textFade;
  late Animation<Offset>   _textSlide;

  final _particles = List.generate(18, (_) => _Particle());

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

    final (String ctaLabel, IconData ctaIcon, Color ctaColor) = switch (card.cta) {
      _CtaType.quran => ('Open Quran',        Icons.menu_book_rounded, const Color(0xFF0D9488)),
      _CtaType.dhikr => ('Dua & Azkaar',      Icons.favorite_rounded,  const Color(0xFFF59E0B)),
      _CtaType.share => ('Share with Friends', Icons.share_rounded,     const Color(0xFF3B82F6)),
      _CtaType.boost => ('Earn More Noor',     Icons.bolt_rounded,      const Color(0xFFFFAA00)),
    };

    void onCtaTap() {
      Navigator.maybePop(context);
      switch (card.cta) {
        case _CtaType.quran: widget.onGoQuran(); break;
        case _CtaType.dhikr: widget.onGoDhikr(); break;
        case _CtaType.share: widget.onShare();   break;
        case _CtaType.boost: widget.onGoBoost(); break;
      }
    }

    void onDndTap() {
      HapticFeedback.lightImpact();
      Navigator.maybePop(context);
      widget.onDoNotDisturb();
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: size.height * 0.90),
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
                  // ── Particles ──────────────────────────────────────────────
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

                  // ── Decorative rings ───────────────────────────────────────
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

                  // ── Content ────────────────────────────────────────────────
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top row: DND left, close right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 🔕 Don't Disturb
                                GestureDetector(
                                  onTap: onDndTap,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.18)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.notifications_off_rounded,
                                          color: Colors.white60, size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Don't Disturb",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white60,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                // ✕ close
                                GestureDetector(
                                  onTap: () => Navigator.maybePop(context),
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white70, size: 17),
                                  ),
                                ),
                              ],
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
                                            : card.cta == _CtaType.boost
                                                ? Icons.bolt_rounded
                                                : Icons.share_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

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

                            if (card.arabic.isNotEmpty) const SizedBox(height: 16),

                            // Divider
                            FadeTransition(
                              opacity: _textFade,
                              child: Row(children: [
                                Expanded(child: Container(height: 0.5, color: Colors.white24)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Container(
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                        color: Colors.white54, shape: BoxShape.circle),
                                  ),
                                ),
                                Expanded(child: Container(height: 0.5, color: Colors.white24)),
                              ]),
                            ),

                            const SizedBox(height: 18),

                            // Quote
                            SlideTransition(
                              position: _textSlide,
                              child: FadeTransition(
                                opacity: _textFade,
                                child: Text(
                                  card.quote,
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

                            const SizedBox(height: 14),

                            // Source pill
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

                            // CTA button
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

                            const SizedBox(height: 10),

                            // Maybe later
                            TextButton(
                              onPressed: () => Navigator.maybePop(context),
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
// Noor Boost Popup Body — shown right after coin validation
// ─────────────────────────────────────────────────────────────────────────────
class _NoorBoostPopupBody extends StatefulWidget {
  final VoidCallback onGoQuran, onGoDhikr;
  final VoidCallback? onGoInvite;
  const _NoorBoostPopupBody({
    required this.onGoQuran,
    required this.onGoDhikr,
    this.onGoInvite,
  });
  @override
  State<_NoorBoostPopupBody> createState() => _NoorBoostPopupBodyState();
}

class _NoorBoostPopupBodyState extends State<_NoorBoostPopupBody>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _rayCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  // Which CTA to show — randomly quran or dhikr
  late bool _showQuran;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _showQuran = math.Random().nextBool();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    _rayCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _rayCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const gold  = Color(0xFFFFAA00);
    const honeyDeep = Y4.honeyDeep;
    const dark  = Color(0xFF5A3200);

    final benefitRows = [
      (
        icon: NoorIcon.greenBook(size: 26),
        title: 'Read 5 Quran Pages',
        desc: 'Complete now → earn +50 points bonus',
        onTap: () {
          Navigator.maybePop(context);
          widget.onGoQuran();
        },
      ),
      (
        icon: NoorIcon.beads(size: 26),
        title: 'Complete a Dhikr Set',
        desc: 'Finish your Azkaar → earn +30 points bonus',
        onTap: () {
          Navigator.maybePop(context);
          widget.onGoDhikr();
        },
      ),
      (
        icon: NoorIcon.handshake(size: 26),
        title: 'Invite a Friend',
        desc: 'Share Noor with someone → earn +100 NP',
        onTap: () {
          Navigator.maybePop(context);
          widget.onGoInvite?.call();
        },
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: size.height * 0.88),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Y4.cream, Y4.bg, Y4.butter],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Y4.honeyDeep.withValues(alpha: 0.35),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Y4.honey.withValues(alpha: 0.25),
                  blurRadius: 30,
                ),
              ],
              border: Border.all(
                color: Y4.honeyDeep.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // ── Rotating sunburst rays ─────────────────────────────────
                  Positioned(
                    top: -60, left: 0, right: 0,
                    child: AnimatedBuilder(
                      animation: _rayCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _rayCtrl.value * math.pi * 2,
                        child: SizedBox(
                          height: 320,
                          child: CustomPaint(
                            painter: _SunburstRayPainter(
                              color: gold.withValues(alpha: 0.07),
                              rayCount: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Green glow orb behind emblem ──────────────────────────
                  Positioned(
                    top: 30, left: 0, right: 0,
                    child: AnimatedBuilder(
                      animation: _glowCtrl,
                      builder: (_, __) => Center(
                        child: Container(
                          width: 180 + _glowCtrl.value * 20,
                          height: 180 + _glowCtrl.value * 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              gold.withValues(alpha: 0.22 + _glowCtrl.value * 0.10),
                              honeyDeep.withValues(alpha: 0.08 + _glowCtrl.value * 0.04),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Content ────────────────────────────────────────────────
                  Positioned.fill(
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Top: close button ────────────────────────────
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.maybePop(context),
                                child: Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: Y4.ink.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Y4.ink.withValues(alpha: 0.12)),
                                  ),
                                  child: Icon(Icons.close_rounded,
                                      color: Y4.inkSoft, size: 17),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Emblem: crescent + star ──────────────────────
                            SlideTransition(
                              position: _contentSlide,
                              child: FadeTransition(
                                opacity: _contentFade,
                                child: AnimatedBuilder(
                                  animation: _glowCtrl,
                                  builder: (_, __) => Container(
                                    width: 110, height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(colors: [
                                        gold.withValues(alpha: 0.30 + _glowCtrl.value * 0.10),
                                        dark.withValues(alpha: 0.80),
                                        dark,
                                      ]),
                                      border: Border.all(
                                        color: gold.withValues(alpha: 0.50 + _glowCtrl.value * 0.25),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gold.withValues(alpha: 0.35 + _glowCtrl.value * 0.15),
                                          blurRadius: 28,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Crescent shape via two stacked circles
                                          Container(
                                            width: 58, height: 58,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: gold.withValues(alpha: 0.90),
                                            ),
                                          ),
                                          Positioned(
                                            right: 8, top: 8,
                                            child: Container(
                                              width: 46, height: 46,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: dark,
                                              ),
                                            ),
                                          ),
                                          // Small star
                                          const Positioned(
                                            right: 0, top: 2,
                                            child: Icon(Icons.star_rounded,
                                                color: gold, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Heading ──────────────────────────────────────
                            SlideTransition(
                              position: _contentSlide,
                              child: FadeTransition(
                                opacity: _contentFade,
                                child: Column(children: [
                                  Text(
                                    'MULTIPLY YOUR',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Y4.ink,
                                      letterSpacing: 2.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Color(0xFFFFAA00), Color(0xFFFFD166), Color(0xFFFFAA00)],
                                    ).createShader(bounds),
                                    child: Text(
                                      'NOOR POINTS!',
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2.5,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ── Subheading ───────────────────────────────────
                            FadeTransition(
                              opacity: _contentFade,
                              child: Text(
                                'Keep your spiritual momentum going\nand watch your Noor grow ✨',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Y4.inkSoft,
                                  height: 1.55,
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ── 3 benefit rows ────────────────────────────────
                            FadeTransition(
                              opacity: _contentFade,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Y4.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Y4.border),
                                  boxShadow: [BoxShadow(
                                    color: Y4.ink.withValues(alpha: 0.04),
                                    blurRadius: 8, offset: const Offset(0, 2),
                                  )],
                                ),
                                child: Column(
                                  children: List.generate(benefitRows.length, (i) {
                                    final row = benefitRows[i];
                                    return Column(children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.vertical(
                                            top: i == 0 ? const Radius.circular(20) : Radius.zero,
                                            bottom: i == benefitRows.length - 1
                                                ? const Radius.circular(20) : Radius.zero,
                                          ),
                                          onTap: row.onTap,
                                          splashColor: gold.withValues(alpha: 0.12),
                                          highlightColor: gold.withValues(alpha: 0.06),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                            child: Row(children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              color: gold.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: gold.withValues(alpha: 0.25)),
                                            ),
                                            child: Center(
                                              child: row.icon,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  row.title,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: Y4.ink,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  row.desc,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: Y4.inkSoft,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                              const Icon(Icons.arrow_forward_ios_rounded,
                                                  color: Color(0xFFFFAA00), size: 15),
                                            ]),
                                          ),
                                        ),
                                      ),
                                      if (i < benefitRows.length - 1)
                                        Divider(
                                          height: 1,
                                          color: Colors.white.withValues(alpha: 0.08),
                                          indent: 16, endIndent: 16,
                                        ),
                                    ]);
                                  }),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ── Primary CTA button ────────────────────────────
                            FadeTransition(
                              opacity: _contentFade,
                              child: SizedBox(
                                width: double.infinity,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.maybePop(context);
                                    if (_showQuran) {
                                      widget.onGoQuran();
                                    } else {
                                      widget.onGoDhikr();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFFF8C00).withValues(alpha: 0.50),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gold.withValues(alpha: 0.20),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _showQuran
                                              ? Icons.menu_book_rounded
                                              : Icons.favorite_rounded,
                                          color: const Color(0xFFFF8C00),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _showQuran ? 'Open Quran Now' : 'Start Azkaar Now',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFFF8C00),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── Skip ─────────────────────────────────────────
                            TextButton(
                              onPressed: () => Navigator.maybePop(context),
                              child: Text(
                                'Maybe later',
                                style: GoogleFonts.outfit(
                                  color: Y4.inkSoft,
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
// Sunburst ray painter (used in boost popup background)
// ─────────────────────────────────────────────────────────────────────────────
class _SunburstRayPainter extends CustomPainter {
  final Color color;
  final int rayCount;
  const _SunburstRayPainter({required this.color, required this.rayCount});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()..color = color;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2;
      final halfWidth = math.pi / rayCount * 0.55;
      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + math.cos(angle - halfWidth) * size.height,
          cy + math.sin(angle - halfWidth) * size.height,
        )
        ..lineTo(
          cx + math.cos(angle + halfWidth) * size.height,
          cy + math.sin(angle + halfWidth) * size.height,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstRayPainter old) =>
      old.color != color || old.rayCount != rayCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle model
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
// Particle painter
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
      final dy = -t * size.height * 0.35;
      final opacity = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.25;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height + dy),
        p.size,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

