import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A full-screen overlay widget that plays a success Lottie animation for
/// [displayDuration] seconds, then fades out and disappears.
///
/// Themed around 'Emerald & Gold' as the app's design system.
///
/// Usage:
/// ```dart
/// // Show as an overlay anywhere in your widget tree:
/// ImpactAnimation.show(context);
/// ```
class ImpactAnimation extends StatefulWidget {
  /// How long the animation stays visible before disappearing.
  final Duration displayDuration;

  /// Called when the animation finishes and disappears.
  final VoidCallback? onComplete;

  const ImpactAnimation({
    super.key,
    this.displayDuration = const Duration(seconds: 3),
    this.onComplete,
  });

  /// Convenience method to show the animation as a full-screen overlay.
  static void show(
    BuildContext context, {
    Duration displayDuration = const Duration(seconds: 3),
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => ImpactAnimation(
            displayDuration: displayDuration,
            onComplete: () {
              entry.remove();
              onComplete?.call();
            },
          ),
    );
    overlay.insert(entry);
  }

  @override
  State<ImpactAnimation> createState() => _ImpactAnimationState();
}

class _ImpactAnimationState extends State<ImpactAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  // Official LottieFiles CDN — success checkmark (green/gold compatible)
  // Source: https://lottiefiles.com/animations/success-checkmark
  static const String _successAnimationUrl =
      'https://lottie.host/4db68bbd-31f6-4cd8-84eb-189de081159a/krnog0zuS2.json';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Fade in immediately
    _fadeController.forward();

    // Start the dismiss countdown
    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    // Fade out, then call onComplete
    _fadeController.reverse().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Semi-transparent dark background
            GestureDetector(
              onTap: _dismiss,
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),

            // Card container styled in Emerald & Gold theme
            Container(
              width: 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 16),
                  ),
                ],
                border: Border.all(
                  color: const Color(
                    0xFFD4AF37,
                  ).withValues(alpha: 0.3), // Gold border
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie animation from network
                  Lottie.network(
                    _successAnimationUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if network unavailable
                      return Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF00A86B,
                          ).withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF00A86B),
                          size: 72,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // "Impact Made!" title — Emerald green
                  const Text(
                    'Impact Made! 🌟',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A86B), // Emerald
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle — Gold accent text
                  const Text(
                    'Your reward has been recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9A7B3A), // Gold
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress bar that mirrors the display duration
                  _DismissCountdownBar(duration: widget.displayDuration),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin animated progress bar that counts down the dismiss duration.
class _DismissCountdownBar extends StatefulWidget {
  final Duration duration;
  const _DismissCountdownBar({required this.duration});

  @override
  State<_DismissCountdownBar> createState() => _DismissCountdownBarState();
}

class _DismissCountdownBarState extends State<_DismissCountdownBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: 1.0 - _controller.value, // Counts DOWN
            minHeight: 4,
            backgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(
              const Color(0xFFC9921A),
            ), // Gold
          ),
        );
      },
    );
  }
}
