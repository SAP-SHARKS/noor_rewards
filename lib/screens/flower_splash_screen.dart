import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Full-screen animated splash screen that plays the growing-flower Lottie
/// animation on a warm honey background, then calls [onComplete] when done.
class FlowerSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const FlowerSplashScreen({super.key, required this.onComplete});

  @override
  State<FlowerSplashScreen> createState() => _FlowerSplashScreenState();
}

class _FlowerSplashScreenState extends State<FlowerSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    _ctrl.duration = composition.duration;
    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Warm honey background
      body: Center(
        child: Lottie.asset(
          'assets/lottie/Flower.json',
          controller: _ctrl,
          onLoaded: _onLoaded,
          width: 280,
          height: 280,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
