import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  LottieComposition? _composition;

  static const _bg = Color(0xFFFFF4D2); // Y4 honey wash — matches launch_background.xml

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);

    // Logo fade-in starts immediately so the user always sees branded content
    // from the very first Flutter frame — no perceived blank gap while the
    // Lottie's earliest frames (where the flower hasn't "grown" yet) play.
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoCtrl.forward();

    if (flowerComposition != null) {
      // ✅ Happy path: composition already decoded in main() — start immediately.
      _startAnimation(flowerComposition!);
    } else {
      // ⚠ Fallback: decode now (stays on honey background, no white flash).
      _loadAndPlay();
    }
  }

  void _startAnimation(LottieComposition composition) {
    _composition = composition;
    _ctrl.duration = composition.duration;
    // Post-frame so the controller is attached to the widget tree first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {}); // ensure Lottie widget is built
      _ctrl.forward().whenComplete(() {
        if (mounted) widget.onComplete();
      });
    });
  }

  Future<void> _loadAndPlay() async {
    try {
      final bytes = await rootBundle.load('assets/lottie/Flower.json');
      final composition = await LottieComposition.fromByteData(bytes);
      if (!mounted) return;
      setState(() => _composition = composition);
      _startAnimation(composition);
    } catch (_) {
      if (mounted) widget.onComplete();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        // Stack so the static logo + brand always renders from frame 1,
        // and the Lottie animates over it without ever leaving a blank gap.
        child: Stack(alignment: Alignment.center, children: [
          // Always-visible branded content (logo + name)
          FadeTransition(
            opacity: _logoFade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/app_icon_padded.png',
                  width: 132, height: 132,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 132, height: 132),
                ),
                const SizedBox(height: 14),
                Text(
                  'Noor Rewards',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2A2410), // Y4 ink
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bismillah ir-Rahman ir-Raheem',
                  style: GoogleFonts.fraunces(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFD89A1E), // Y4 honeyDeep
                  ),
                ),
              ],
            ),
          ),
          // Lottie flower — animates on top once composition is ready.
          // Wrapped in IgnorePointer so the logo behind stays the visual anchor.
          if (_composition != null)
            IgnorePointer(
              child: Lottie(
                composition: _composition!,
                controller: _ctrl,
                width: 320,
                height: 320,
                fit: BoxFit.contain,
              ),
            ),
        ]),
      ),
    );
  }
}
