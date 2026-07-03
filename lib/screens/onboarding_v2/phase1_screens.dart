// lib/screens/onboarding_v2/phase1_screens.dart
//
// Phase 1 — Story (screens 1–7). All seven screens are designed to be
// rendered inside a PageView managed by [OnboardingFlow]. Each is given
// an [onNext] callback that advances the page or, on screen 7, completes
// Phase 1 and routes to the existing StartJourneyScreen (Google login).
// [onSkip] short-circuits the story and goes straight to login.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/sabiq_coin.dart';
import 'widgets/akhirah_mini.dart';
import 'widgets/decorations.dart';
import 'widgets/door_scales.dart';
import 'widgets/onboarding_components.dart';
import 'widgets/onboarding_tokens.dart';
import 'widgets/quran_mini.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1 — The Hook
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen1 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen1({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  const PhotoSlot(slotKey: 'onb_hero_1'),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: 90,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              OnbTok.cream.withValues(alpha: 0),
                              OnbTok.cream,
                            ],
                            stops: const [0.0, 0.92],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Container(
                color: OnbTok.cream,
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Wordmark(size: 26),
                    const SizedBox(height: 26),
                    OnbHeading(
                      first: l.onbV2_1_TitleA,
                      accent: l.onbV2_1_TitleB,
                      fontSize: 34,
                    ),
                    const SizedBox(height: 14),
                    Text(l.onbV2_1_Sub, style: OnbTok.sans()),
                    const Spacer(),
                    ScreenFooter(
                      dotsIdx: 0,
                      child: CTA(label: l.onbV2_1_Cta, onPressed: onNext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — The Mechanism (animated seed flow)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen2({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 32, 26, 24),
                child: Wordmark(size: 26),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Text(l.onbV2_2_Title,
                    style: OnbTok.serif(fontSize: 30)),
              ),
              const SizedBox(height: 20),
              // Flow box — expands to fill the space that used to sit
              // empty above the Next button, so the two screenshots
              // inside render as large as the screen allows.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: OnbTok.creamWarm,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        // Card height tracks the box height — a taller box
                        // means taller screenshots. Cards are inset from
                        // the box edges so the cream frame still shows.
                        const inset = 22.0;
                        const cardW = 142.0;
                        final cardH = c.maxHeight - inset * 2;
                        const coinD = 96.0;
                        return Stack(
                          children: [
                            // Left: Quran mini
                            Positioned(
                              left: 18,
                              top: inset,
                              width: cardW,
                              height: cardH,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: PhotoSlot(
                                  slotKey: 'onb_quran_2',
                                  fallback: _MiniQuranCard(),
                                ),
                              ),
                            ),
                            // Right: aid photo
                            Positioned(
                              right: 18,
                              top: inset,
                              width: cardW,
                              height: cardH,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: const PhotoSlot(
                                  slotKey: 'onb_aid_2',
                                  placeholderText:
                                      'aid photo\nhands receiving',
                                ),
                              ),
                            ),
                            // Seeds flowing between the two cards
                            Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  width: 90,
                                  height: c.maxHeight,
                                  child: const SeedFlow(),
                                ),
                              ),
                            ),
                            // Sabiq Seed coin — the centerpiece linking the
                            // two images: Read Quran → earn Seeds → fund.
                            Positioned(
                              left: 0,
                              right: 0,
                              top: (c.maxHeight - coinD) / 2,
                              child: Center(
                                child: Container(
                                  width: coinD,
                                  height: coinD,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: OnbTok.cream,
                                    boxShadow: [
                                      BoxShadow(
                                        color: OnbTok.goldDeep.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 22,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: SabiqCoin(size: 68),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: _MechanicLine(),
              ),
              const SizedBox(height: 16),
              ScreenFooter(
                dotsIdx: 2,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

class _MechanicLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Text(
      l.onbV2_2_Body,
      style: OnbTok.sans(
        fontSize: 15.5,
        color: OnbTok.brownSoft,
        height: 1.45,
      ),
    );
  }
}

class _MiniQuranCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Al-Baqarah',
            style: OnbTok.sans(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: OnbTok.brown,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: OnbTok.creamWarm),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'بِسْمِ اللَّهِ',
              textAlign: TextAlign.right,
              style: OnbTok.arabic(fontSize: 13, color: OnbTok.brown),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)?.phase1Screens_inTheNameOf ?? 'In the name of Allah, the Most Gracious…',
            style: OnbTok.sans(fontSize: 6, color: OnbTok.brownSoft),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3 (display order) — Three-step flow: Read → Earn → Fund.
// Inserted between "The Mechanism" and "Quran Earns Seeds". The older
// Phase1ScreenN classes keep their original names; display order is
// defined by phase1_flow.dart, not by the class numbers.
// ─────────────────────────────────────────────────────────────────────────────
class Phase1ScreenSteps extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1ScreenSteps({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<Phase1ScreenSteps> createState() => _Phase1ScreenStepsState();
}

class _Phase1ScreenStepsState extends State<Phase1ScreenSteps>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 30, 26, 0),
                child: Wordmark(size: 20),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: c.maxHeight - 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Step 1 — Read Quran (admin-uploadable image)
                          _JourneyStep(
                            step: 1,
                            label: l.onbV2_3step_S1Text,
                            color: OnbTok.tealDark,
                            visual: const _StepImage(
                              slotKey: 'onb_step_quran',
                              placeholder: 'Quran reading\nimage',
                            ),
                          ),
                          _StepArrow(pulse: _pulse),
                          // Step 2 — Earn Seeds (the Sabiq Seed coin)
                          _JourneyStep(
                            step: 2,
                            label: l.onbV2_3step_S2Text,
                            color: OnbTok.goldDeep,
                            visual: const SizedBox(
                              height: 150,
                              child: Center(child: SabiqCoin(size: 138)),
                            ),
                          ),
                          _StepArrow(pulse: _pulse),
                          // Step 3 — Feed Orphans (admin-uploadable image)
                          _JourneyStep(
                            step: 3,
                            label: l.onbV2_3step_S3Text,
                            color: OnbTok.brownSoft,
                            visual: const _StepImage(
                              slotKey: 'onb_step_orphans',
                              placeholder: 'Orphans\nimage',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.onbV2_3step_Title,
                      style: OnbTok.serif(fontSize: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_3step_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              ScreenFooter(
                dotsIdx: 1,
                child: CTA(label: l.onbV2Next, onPressed: widget.onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: widget.onSkip),
        ],
      ),
    );
  }
}

// One step of the Read → Earn → Feed journey: a large visual with a solid
// colored pill below it. The pill carries a numbered white disc (1 · 2 · 3)
// so the three stages read clearly as ordered steps. Each step has its own
// [color] so the stages stay visually distinct.
class _JourneyStep extends StatelessWidget {
  final Widget visual;
  final String label;
  final Color color;
  final int step;
  const _JourneyStep({
    required this.visual,
    required this.label,
    required this.color,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        visual,
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 22, 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.36),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Numbered disc — white circle, colored numeral.
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: OnbTok.sans(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: OnbTok.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Large rounded image for a journey step. Pulls the admin-uploaded
// onboarding image for [slotKey] (manageable from the admin web panel's
// "Onboarding Images" section); falls back to a cream placeholder.
class _StepImage extends StatelessWidget {
  final String slotKey;
  final String placeholder;
  const _StepImage({required this.slotKey, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fills the available width (screen minus the scroll padding) and
      // stands ~1.7× taller than before so each step reads clearly.
      width: double.infinity,
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: OnbTok.brown.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: PhotoSlot(
        slotKey: slotKey,
        placeholderText: placeholder,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(26),
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  final Animation<double> pulse;
  const _StepArrow({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final t = pulse.value;
          // Ease opacity 0.35 → 1 → 0.35 across the cycle.
          final o = 0.35 + 0.65 * (1 - (2 * t - 1).abs());
          return Opacity(
            opacity: o,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: OnbTok.goldDeep,
              size: 46,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3 — Quran Earns Seeds
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen3 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen3({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          // Radial gold gradient bg
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.24),
                  radius: 0.6,
                  colors: [
                    OnbTok.goldLight.withValues(alpha: 0.55),
                    OnbTok.cream.withValues(alpha: 0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 32, 26, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wordmark(size: 26),
                ),
              ),
              Expanded(
                child: Center(
                  child: Center(
                    // Quran mockup (or admin-uploaded screenshot).
                    // transparentBackdrop: the uploaded asset is centered
                    // on the screen's own background — no cream fill or
                    // blurred side margins around a portrait image.
                    child: PhotoSlot(
                      slotKey: 'onb_quran_3',
                      transparentBackdrop: true,
                      fallback: const QuranMini(
                        width: 210,
                        tilt: -4,
                        showSeedBanner: true,
                        pulseBanner: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_3_TitleA,
                      accent: l.onbV2_3_TitleB,
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_3_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              ScreenFooter(
                dotsIdx: 3,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 4 — Azkaar Animations (door ↔ scales)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen4 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen4({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.creamWarm,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 32, 26, 0),
                child: Wordmark(size: 26),
              ),
              const SizedBox(height: 20),
              // Artwork expands to fill the space that used to sit empty
              // above the Next button, so the azkaar screenshot is large.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: PhotoSlot(
                    slotKey: 'onb_zikr_4',
                    fallback: const DoorScalesAnim(),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_4_TitleA,
                      accent: l.onbV2_4_TitleB,
                    ),
                    const SizedBox(height: 14),
                    Text(l.onbV2_4_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ScreenFooter(
                dotsIdx: 4,
                child: CTA(label: l.onbV2Next, onPressed: onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 5 — Real-World Impact
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen5 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen5({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 60,
              child: Stack(
                children: [
                  const PhotoSlot(slotKey: 'onb_impact_5'),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              OnbTok.goldDeep.withValues(alpha: 0),
                              OnbTok.goldDeep.withValues(alpha: 0.18),
                              OnbTok.cream,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 40,
              child: Container(
                color: OnbTok.cream,
                padding: const EdgeInsets.fromLTRB(26, 32, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_5_TitleA,
                      accent: l.onbV2_5_TitleB,
                    ),
                    const SizedBox(height: 14),
                    Text(l.onbV2_5_Sub, style: OnbTok.sans()),
                    const Spacer(),
                    ScreenFooter(
                      dotsIdx: 5,
                      child: CTA(label: l.onbV2Next, onPressed: onNext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SkipBtn(label: l.onbV2Skip, onPressed: onSkip),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 6 — Trust (3-step diagram)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen6 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  // The Phase 1 PageView controller — lets this screen detect when it
  // settles into view (page index 6) so the Donor → You → Charity icons
  // play their staggered entrance exactly when the user arrives, not
  // while the page is still being swiped in.
  final PageController pageController;
  const Phase1Screen6({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.pageController,
  });

  @override
  State<Phase1Screen6> createState() => _Phase1Screen6State();
}

class _Phase1Screen6State extends State<Phase1Screen6>
    with SingleTickerProviderStateMixin {
  // This screen's index in the Phase 1 PageView (see phase1_flow.dart).
  static const int _pageIndex = 6;

  late final AnimationController _entrance;
  // Three staggered slices of [_entrance]: Donor reveals first, then You,
  // then Charity — each fades + slides up + scales into place.
  late final Animation<double> _donorIn;
  late final Animation<double> _youIn;
  late final Animation<double> _charityIn;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _donorIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _youIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.22, 0.80, curve: Curves.easeOutCubic),
    );
    _charityIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.46, 1.0, curve: Curves.easeOutCubic),
    );
    widget.pageController.addListener(_maybePlay);
    // Covers the case where screen 6 is already the visible page at build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlay());
  }

  // Fires the staggered entrance once, the moment page 6 settles into view.
  void _maybePlay() {
    if (_played || !mounted) return;
    final c = widget.pageController;
    if (!c.hasClients || c.page == null) return;
    if ((c.page! - _pageIndex).abs() < 0.08) {
      _played = true;
      _entrance.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_maybePlay);
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 32, 26, 0),
                child: Wordmark(size: 26),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_6_TitleA,
                      accent: l.onbV2_6_TitleB,
                      trailing: l.onbV2_6_TitleC,
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_6_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RevealStep(
                        animation: _donorIn,
                        child: _StepIcon(
                          size: 62,
                          bg: OnbTok.goldDeep,
                          glyph: const DonorGlyph(),
                          label: l.onbV2_6_Donor,
                          sub: l.onbV2_6_DonorSub,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 36),
                        child: _RevealStep(
                          animation: _youIn,
                          child: _StepIcon(
                            size: 124,
                            bg: OnbTok.gold,
                            big: true,
                            glyph: const ReaderGlyph(),
                            label: l.onbV2_6_You,
                            sub: l.onbV2_6_YouSub,
                          ),
                        ),
                      ),
                      _RevealStep(
                        animation: _charityIn,
                        child: _StepIcon(
                          size: 62,
                          bg: OnbTok.goldDeep,
                          glyph: const CharityGlyph(),
                          label: l.onbV2_6_Charity,
                          sub: l.onbV2_6_CharitySub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: OnbTok.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: OnbTok.teal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.onbV2_6_TrustBadge,
                        style: OnbTok.sans(
                          fontSize: 11.5,
                          color: OnbTok.tealDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ScreenFooter(
                dotsIdx: 6,
                child: CTA(label: l.onbV2Next, onPressed: widget.onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: widget.onSkip),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final double size;
  final Color bg;
  final Widget glyph;
  final String label;
  final String sub;
  final bool big;
  const _StepIcon({
    required this.size,
    required this.bg,
    required this.glyph,
    required this.label,
    required this.sub,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              boxShadow: big
                  ? [
                      BoxShadow(
                        color: OnbTok.gold.withValues(alpha: 0.18),
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: OnbTok.gold.withValues(alpha: 0.6),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                        spreadRadius: -14,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: glyph),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: OnbTok.serif(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OnbTok.brown,
              height: 1.0,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: OnbTok.sans(
              fontSize: 11,
              color: OnbTok.brownSoft,
              height: 1.3,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Plays a single step into view: fade + slide-up + scale, driven by an
// [animation] (0 → 1). Used to stagger the Donor → You → Charity reveal on
// Screen 6 without changing how each [_StepIcon] looks once settled.
class _RevealStep extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _RevealStep({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 28),
            child: Transform.scale(
              scale: 0.82 + 0.18 * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 7 — Akhirah Account (teal-dominant)
// ─────────────────────────────────────────────────────────────────────────────
class Phase1Screen7 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const Phase1Screen7({super.key, required this.onNext, required this.onSkip});

  @override
  State<Phase1Screen7> createState() => _Phase1Screen7State();
}

class _Phase1Screen7State extends State<Phase1Screen7>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle;
  late final List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _sparkles = List.generate(14, (_) {
      return _Sparkle(
        leftPct: 0.06 + rng.nextDouble() * 0.88,
        topPct: 0.08 + rng.nextDouble() * 0.70,
        delay: rng.nextDouble() * 4,
        dur: 3 + rng.nextDouble() * 3,
        size: 4 + rng.nextDouble() * 4,
      );
    });
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: OnbTok.cream,
      child: Stack(
        children: [
          // Radial teal wash
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.16),
                  radius: 0.7,
                  colors: [
                    OnbTok.teal.withValues(alpha: 0.16),
                    OnbTok.cream.withValues(alpha: 0),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 32, 26, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wordmark(size: 26),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Teal halo
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              OnbTok.teal.withValues(alpha: 0.22),
                              OnbTok.teal.withValues(alpha: 0),
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                      // Sparkles
                      ..._sparkles.map((s) {
                        return AnimatedBuilder(
                          animation: _sparkle,
                          builder: (_, __) {
                            final now = _sparkle.value * 6.0;
                            final t = ((now - s.delay) / s.dur) % 1.0;
                            double opacity = 0;
                            double y = 0;
                            double scale = 0.6;
                            if (t >= 0 && t <= 1) {
                              if (t < 0.4) {
                                opacity = t / 0.4;
                                y = -6 * (t / 0.4);
                                scale = 0.6 + 0.4 * (t / 0.4);
                              } else if (t < 0.6) {
                                opacity = 1;
                                y = -6 - 4 * ((t - 0.4) / 0.2);
                                scale = 1.0;
                              } else {
                                opacity = (1.0 - t) / 0.4;
                                y = -10 + 10 * ((t - 0.6) / 0.4);
                                scale = 1.0 - 0.4 * ((t - 0.6) / 0.4);
                              }
                            }
                            return Positioned(
                              left: s.leftPct * c.maxWidth,
                              top: s.topPct * c.maxHeight + y,
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: scale,
                                  child: CustomPaint(
                                    size: Size(s.size, s.size),
                                    painter: _TealStarPainter(),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      // Akhirah mockup (or admin-uploaded screenshot)
                      PhotoSlot(
                        slotKey: 'onb_akhirah_7',
                        fallback: const AkhirahMini(width: 210, tilt: 3),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnbHeading(
                      first: l.onbV2_7_TitleA,
                      accent: l.onbV2_7_TitleB,
                      accentColor: OnbTok.tealDark,
                    ),
                    const SizedBox(height: 12),
                    Text(l.onbV2_7_Sub, style: OnbTok.sans()),
                  ],
                ),
              ),
              ScreenFooter(
                dotsIdx: 7,
                teal: true,
                child: CTA(label: l.onbV2Next, onPressed: widget.onNext),
              ),
            ],
          ),
          SkipBtn(label: l.onbV2Skip, onPressed: widget.onSkip),
        ],
      ),
    );
  }
}

class _Sparkle {
  final double leftPct;
  final double topPct;
  final double delay;
  final double dur;
  final double size;
  _Sparkle({
    required this.leftPct,
    required this.topPct,
    required this.delay,
    required this.dur,
    required this.size,
  });
}

class _TealStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = OnbTok.teal;
    final s = size.width;
    final path = Path()
      ..moveTo(s * 0.5, 0)
      ..lineTo(s * 0.6, s * 0.4)
      ..lineTo(s, s * 0.5)
      ..lineTo(s * 0.6, s * 0.6)
      ..lineTo(s * 0.5, s)
      ..lineTo(s * 0.4, s * 0.6)
      ..lineTo(0, s * 0.5)
      ..lineTo(s * 0.4, s * 0.4)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
