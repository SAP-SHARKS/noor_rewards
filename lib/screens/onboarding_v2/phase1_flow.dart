// lib/screens/onboarding_v2/phase1_flow.dart
//
// Phase 1 controller — a PageView through the 7 Story screens. The
// last screen's "Next" CTA and the Skip button both fire [onComplete],
// which the caller wires to its existing StartJourneyScreen (Google login).

import 'package:flutter/material.dart';

import '../../services/onboarding_assets_service.dart';
import 'phase1_screens.dart';
import 'widgets/onboarding_tokens.dart';

class Phase1Flow extends StatefulWidget {
  final VoidCallback onComplete;
  const Phase1Flow({super.key, required this.onComplete});

  @override
  State<Phase1Flow> createState() => _Phase1FlowState();
}

class _Phase1FlowState extends State<Phase1Flow> {
  final _pc = PageController();
  bool _completing = false;
  bool _prefetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefetched) {
      _prefetched = true;
      // Start decoding every onboarding image into Flutter's image cache
      // right now, before the user has swiped past the first slide. The
      // URLs are already cached in Hive from a prior session or were
      // refreshed during app init, so this is a pure bytes-into-memory
      // warm-up — no spinners on subsequent slides.
      OnboardingAssetsService.instance.precacheAll(context);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _advanceOrComplete(int currentIndex) {
    if (currentIndex >= 6) {
      _complete();
      return;
    }
    _pc.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _complete() {
    if (_completing) return;
    _completing = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnbTok.cream,
      body: SafeArea(
        child: PageView(
          controller: _pc,
          physics: const BouncingScrollPhysics(),
          children: [
            Phase1Screen1(onNext: () => _advanceOrComplete(0), onSkip: _complete),
            Phase1Screen2(onNext: () => _advanceOrComplete(1), onSkip: _complete),
            Phase1Screen3(onNext: () => _advanceOrComplete(2), onSkip: _complete),
            Phase1Screen4(onNext: () => _advanceOrComplete(3), onSkip: _complete),
            Phase1Screen5(onNext: () => _advanceOrComplete(4), onSkip: _complete),
            Phase1Screen6(onNext: () => _advanceOrComplete(5), onSkip: _complete),
            Phase1Screen7(onNext: () => _advanceOrComplete(6), onSkip: _complete),
          ],
        ),
      ),
    );
  }
}
