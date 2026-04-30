import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../main.dart' show flowerComposition;

/// Full-screen animated splash screen that plays the growing-flower Lottie
/// animation on a warm honey background, then calls [onComplete] when done.
///
/// ## How blank-screen elimination works
/// `flowerComposition` is pre-parsed in `main()` **before** `runApp()`, during
/// the same window that Supabase / Firebase initialise. By the time this widget
/// builds its first frame the composition is already decoded and the animation
/// starts immediately — no visible delay.
///
/// If pre-parsing somehow failed (edge case), the screen falls back to an
/// async load, staying on the honey background the whole time.
class FlowerSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const FlowerSplashScreen({super.key, required this.onComplete});

  @override
  State<FlowerSplashScreen> createState() => _FlowerSplashScreenState();
}

class _FlowerSplashScreenState extends State<FlowerSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  LottieComposition? _composition;
  Timer? _safetyTimeout;

  static const _bg = Color(0xFFFFF4D2); // Y4 honey wash — matches launch_background.xml

  /// Skip the first portion of the animation where the flower hasn't "grown"
  /// yet (Lottie typically draws nothing in the very early frames). Starting
  /// the controller at this offset means the user sees a visible flower from
  /// frame 1 — no perceived blank gap.
  static const _initialFrameOffset = 0.25;

  /// If the Lottie composition isn't ready within this window, we give up
  /// waiting and call [widget.onComplete] so the SplashGate can move on.
  static const _maxLoadWait = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);

    // Start animation IMMEDIATELY (synchronously) if we already have it.
    // This sets `_composition` before the first build() runs, so the very
    // first paint shows the flower (no SizedBox.shrink frame).
    if (flowerComposition != null) {
      _composition = flowerComposition;
      _ctrl
        ..duration = flowerComposition!.duration
        ..value = _initialFrameOffset;
    } else {
      _loadAndPlay();
    }

    // Belt-and-suspenders: if for any reason the animation hasn't called
    // onComplete within 1.5s of its expected duration, fire it manually.
    _safetyTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onComplete();
    });

    // Kick the animation forward on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_composition != null) _runForward();
    });
  }

  void _runForward() {
    if (!mounted) return;
    _ctrl.forward(from: _initialFrameOffset).whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  Future<void> _loadAndPlay() async {
    try {
      final bytes = await rootBundle.load('assets/lottie/Flower.json')
          .timeout(_maxLoadWait);
      final composition = await LottieComposition.fromByteData(bytes);
      if (!mounted) return;
      setState(() {
        _composition = composition;
        _ctrl
          ..duration = composition.duration
          ..value = _initialFrameOffset;
      });
      _runForward();
    } catch (_) {
      if (mounted) widget.onComplete();
    }
  }

  @override
  void dispose() {
    _safetyTimeout?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: _composition == null
            // Honey-tinted placeholder circle while Lottie decodes — never
            // lets the screen feel "blank" even on the slowest device.
            ? Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33D89A1E), // honey-deep @ 20%
                ),
              )
            : Lottie(
                composition: _composition!,
                controller: _ctrl,
                width: 320,
                height: 320,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
