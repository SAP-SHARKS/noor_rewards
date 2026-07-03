// lib/screens/onboarding_v2/widgets/quran_mini.dart
//
// Mock phone-in-phone Quran reading screen used as fallback for the
// onb_quran_2 / onb_quran_3 slots. Renders a stylized Quran page with
// optional "+96 Seeds earned today" gold banner (pulsing on S3).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/sabiq_coin.dart';
import 'onboarding_tokens.dart';

class QuranMini extends StatefulWidget {
  final double width;
  final double tilt;
  final bool showSeedBanner;
  final bool pulseBanner;
  const QuranMini({
    super.key,
    this.width = 220,
    this.tilt = 0,
    this.showSeedBanner = false,
    this.pulseBanner = false,
  });

  @override
  State<QuranMini> createState() => _QuranMiniState();
}

class _QuranMiniState extends State<QuranMini>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.pulseBanner) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 2.0;
    return Transform.rotate(
      angle: widget.tilt * math.pi / 180.0,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Phone shell
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: OnbTok.brown.withValues(alpha: 0.35),
                    blurRadius: 60,
                    offset: const Offset(0, 30),
                    spreadRadius: -28,
                  ),
                ],
              ),
              padding: EdgeInsets.all(w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Surah label
                  Text(
                    'Al-Baqarah',
                    style: OnbTok.sans(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w600,
                      color: OnbTok.brown,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: w * 0.025),
                  Container(height: 1, color: OnbTok.creamWarm),
                  SizedBox(height: w * 0.04),
                  // Arabic verse (RTL)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.right,
                      style: OnbTok.arabic(
                        fontSize: w * 0.085,
                        fontWeight: FontWeight.w700,
                        color: OnbTok.brown,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: w * 0.04),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                      textAlign: TextAlign.right,
                      style: OnbTok.arabic(
                        fontSize: w * 0.075,
                        color: OnbTok.brown,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: w * 0.05),
                  Text(
                    AppLocalizations.of(context)?.quranMini_inTheNameOf_46925d ?? 'In the name of Allah, the Most Gracious, the Most Merciful.',
                    style: OnbTok.sans(
                      fontSize: w * 0.04,
                      color: OnbTok.brownSoft,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: w * 0.03),
                  Text(
                    AppLocalizations.of(context)?.quranMini_allPraiseBelongsTo_2d51df ?? 'All praise belongs to Allah, Lord of all the worlds.',
                    style: OnbTok.sans(
                      fontSize: w * 0.04,
                      color: OnbTok.brownSoft,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  // Page counter pill
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.04,
                        vertical: w * 0.018,
                      ),
                      decoration: BoxDecoration(
                        color: OnbTok.cream,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Page 2 of 604',
                        style: OnbTok.sans(
                          fontSize: w * 0.035,
                          fontWeight: FontWeight.w600,
                          color: OnbTok.brownSoft,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showSeedBanner)
              Positioned(
                top: -w * 0.08,
                left: 0,
                right: 0,
                child: _SeedBanner(pulse: _pulse, width: w),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeedBanner extends StatelessWidget {
  final AnimationController? pulse;
  final double width;
  const _SeedBanner({required this.pulse, required this.width});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.1),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.06,
        vertical: width * 0.035,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OnbTok.gold, OnbTok.goldLight, OnbTok.gold],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: OnbTok.goldDeep.withValues(alpha: 0.55),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SabiqCoin(size: width * 0.08),
          SizedBox(width: width * 0.025),
          Text(
            '+96 Sabiq Seeds',
            style: GoogleFonts.dmSans(
              fontSize: width * 0.055,
              fontWeight: FontWeight.w700,
              color: OnbTok.brown,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
    if (pulse == null) return pill;
    return AnimatedBuilder(
      animation: pulse!,
      builder: (_, child) {
        final t = pulse!.value;
        final scale = 1.0 + 0.03 * math.sin(t * math.pi * 2);
        return Transform.scale(scale: scale, child: child);
      },
      child: pill,
    );
  }
}
