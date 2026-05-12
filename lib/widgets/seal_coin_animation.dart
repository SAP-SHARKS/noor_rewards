// lib/widgets/seal_coin_animation.dart
//
// The seal-the-day celebration overlay.
//
// Flow when the user taps "Seal the Day":
//   1. A 180 px Sprouting SabiqCoin scales in, slow-rotating on the Y axis
//      (a 720° flip) over ~900 ms with easeInOutCubic.
//   2. After the spin, the coin shrinks and arcs upward to the top-left
//      Seed-balance pill, then fades out.
//   3. The future returned by [playSealCoinAnimation] completes when the
//      flight is done — the caller can then refresh the balance pill.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sabiq_coin.dart';

/// Plays the seal-the-day coin animation as a fullscreen overlay.
///
/// [pointsSealed] is the value to show beneath the coin while it's
/// spinning ("+286 Seeds"). [targetPosition] is where the coin should
/// fly to — typically the centre of the top-left Seed balance pill in
/// global screen coordinates. If null, the coin lands at the top-left
/// corner with a small inset.
Future<void> playSealCoinAnimation(
  BuildContext context, {
  required int pointsSealed,
  Offset? targetPosition,
}) {
  final completer = Completer<void>();
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SealCoinOverlay(
      pointsSealed: pointsSealed,
      targetPosition: targetPosition,
      onFinished: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

// ─────────────────────────────────────────────────────────────────────────────

class _SealCoinOverlay extends StatefulWidget {
  final int pointsSealed;
  final Offset? targetPosition;
  final VoidCallback onFinished;
  const _SealCoinOverlay({
    required this.pointsSealed,
    required this.onFinished,
    this.targetPosition,
  });

  @override
  State<_SealCoinOverlay> createState() => _SealCoinOverlayState();
}

class _SealCoinOverlayState extends State<_SealCoinOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _flightCtrl;
  late final AnimationController _burstCtrl;
  late final Animation<double> _scaleIn;
  late final Animation<double> _spin;
  late final Animation<double> _flightT;
  late final Animation<double> _burst;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _scaleIn = CurvedAnimation(
      parent: _spinCtrl,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
    );
    _spin = CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOutCubic);
    _flightT =
        CurvedAnimation(parent: _flightCtrl, curve: Curves.easeInCubic);
    _burst = CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut);

    _spinCtrl.forward().whenComplete(() async {
      if (!mounted) return;
      // Fire the welcome-burst just before the coin lands so it feels
      // like the wallet "catches" the coin.
      Future.delayed(const Duration(milliseconds: 520), () {
        if (mounted) _burstCtrl.forward();
      });
      await _flightCtrl.forward();
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _flightCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final centerStart = Offset(screen.width / 2, screen.height / 2.4);
    // Default to top-right when no target supplied (closest to the
    // standard profile-icon location on most layouts).
    final flightTarget = widget.targetPosition ??
        Offset(
          screen.width - 30 - media.padding.right,
          media.padding.top + 36,
        );

    return AnimatedBuilder(
      animation: Listenable.merge([_spinCtrl, _flightCtrl, _burstCtrl]),
      builder: (_, __) {
        final spinning = _flightCtrl.value == 0;
        final scale = spinning
            ? 0.4 + 0.6 * _scaleIn.value
            : 1.0 - 0.78 * _flightT.value;
        // Parabolic flight: lerp x/y linearly but add an upward arc so
        // the coin feels tossed into the wallet rather than dragged.
        final t = _flightT.value;
        final lerped =
            Offset.lerp(centerStart, flightTarget, t) ?? flightTarget;
        // peak of the arc ~80 px above the straight-line midpoint
        final arcLift = -80.0 * math.sin(t * math.pi);
        final pos = spinning
            ? centerStart
            : Offset(lerped.dx, lerped.dy + arcLift);
        final coinSize = 180.0 * scale;
        final yRot = _spin.value * 2 * math.pi * 2; // 720° flip

        final barrierOpacity = spinning
            ? 0.55 * _scaleIn.value
            : 0.55 * (1.0 - _flightT.value);
        final labelOpacity = spinning ? _scaleIn.value : (1.0 - _flightT.value);

        return Material(
          color: Colors.black.withValues(alpha: barrierOpacity),
          child: Stack(
            children: [
              // The coin.
              Positioned(
                left: pos.dx - coinSize / 2,
                top: pos.dy - coinSize / 2,
                width: coinSize,
                height: coinSize,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(yRot),
                  child: const SabiqCoin(size: 180, sprouting: true),
                ),
              ),
              // Welcome-burst ring on the wallet — gold ripple that
              // expands outward when the coin lands.
              if (_burstCtrl.value > 0)
                Positioned(
                  left: flightTarget.dx - 60 * _burst.value,
                  top: flightTarget.dy - 60 * _burst.value,
                  width: 120 * _burst.value,
                  height: 120 * _burst.value,
                  child: Opacity(
                    opacity: (1.0 - _burst.value).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFE89A),
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FFD662),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // "+X Seeds" label under the coin during the spin.
              if (spinning)
                Positioned(
                  left: 0,
                  right: 0,
                  top: centerStart.dy + 110,
                  child: Opacity(
                    opacity: labelOpacity.clamp(0.0, 1.0),
                    child: Column(
                      children: [
                        Text(
                          '+${widget.pointsSealed} '
                          '${widget.pointsSealed == 1 ? 'Seed' : 'Seeds'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFE89A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'SEALED FOR THE AKHIRAH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFAF3E3),
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
