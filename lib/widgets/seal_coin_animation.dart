// lib/widgets/seal_coin_animation.dart
//
// The seal-the-day celebration overlay.
//
// A small burst of Sabiq Seed coins — a mix of large hero coins and many
// smaller ones — fans outward from the centre of the screen, each spinning
// on its own axis, then converges on the top-right profile icon (the
// Seeds wallet). Each landing triggers a tiny gold burst ring so the
// wallet visibly "catches" every coin.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sabiq_coin.dart';

/// Resolves when the in-flight seal-coin animation finishes, or is null
/// when no animation is playing. Post-seal popups (e.g. the Noor Boost
/// popup) await this so they never appear while coins are still flying
/// to the garden.
Future<void>? sealCoinAnimationInFlight;

/// Plays the seal-the-day coin shower as a fullscreen overlay.
///
/// [pointsSealed] is the value shown briefly beneath the burst.
/// [targetPosition] is the wallet centre in global coordinates; defaults
/// to the top-right corner with a sensible inset.
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

  final future = completer.future;
  sealCoinAnimationInFlight = future;
  future.whenComplete(() {
    if (identical(sealCoinAnimationInFlight, future)) {
      sealCoinAnimationInFlight = null;
    }
  });
  return future;
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
    with SingleTickerProviderStateMixin {
  static const Duration _totalDuration = Duration(milliseconds: 1500);

  late final AnimationController _master;
  late final List<_CoinParticle> _particles;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(vsync: this, duration: _totalDuration);
    _particles = _buildParticles();
    _master.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  List<_CoinParticle> _buildParticles() {
    final rng = math.Random();
    final out = <_CoinParticle>[];

    // 2 hero coins — one with the leaf sprout, one without.
    for (var i = 0; i < 2; i++) {
      out.add(_CoinParticle(
        size: 38 + rng.nextDouble() * 10,
        launchDelay: rng.nextDouble() * 0.04,
        travel: 0.58 + rng.nextDouble() * 0.08,
        spinTurns: (rng.nextBool() ? 1 : -1) * (1.4 + rng.nextDouble() * 0.8),
        launchAngle: (rng.nextDouble() * 2 - 1) * 0.7,
        launchDistance: 70 + rng.nextDouble() * 40,
        sprouting: i == 0,
        zOrder: 2,
      ));
    }

    // 5 medium coins.
    for (var i = 0; i < 5; i++) {
      out.add(_CoinParticle(
        size: 20 + rng.nextDouble() * 10,
        launchDelay: 0.02 + rng.nextDouble() * 0.14,
        travel: 0.50 + rng.nextDouble() * 0.14,
        spinTurns: (rng.nextBool() ? 1 : -1) * (1.5 + rng.nextDouble() * 1.5),
        launchAngle: (rng.nextDouble() * 2 - 1) * 1.1,
        launchDistance: 100 + rng.nextDouble() * 60,
        sprouting: false,
        zOrder: 1,
      ));
    }

    // 10 small coins — full fan in any direction.
    for (var i = 0; i < 10; i++) {
      out.add(_CoinParticle(
        size: 11 + rng.nextDouble() * 8,
        launchDelay: 0.05 + rng.nextDouble() * 0.2,
        travel: 0.48 + rng.nextDouble() * 0.2,
        spinTurns: (rng.nextBool() ? 1 : -1) * (2 + rng.nextDouble() * 2),
        launchAngle: (rng.nextDouble() * 2 - 1) * math.pi * 0.9,
        launchDistance: 80 + rng.nextDouble() * 100,
        sprouting: false,
        zOrder: 0,
      ));
    }

    // Render small coins first so heros land on top.
    out.sort((a, b) => a.zOrder.compareTo(b.zOrder));
    return out;
  }

  /// Quadratic Bezier interpolation.
  Offset _bezier(double t, Offset p0, Offset p1, Offset p2) {
    final mt = 1 - t;
    return Offset(
      mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
      mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy,
    );
  }

  /// Easing for a single particle's local progress.
  double _ease(double u) {
    // ease-out-cubic — fast launch, gentle catch.
    final c = 1 - u;
    return 1 - c * c * c;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final centerStart = Offset(screen.width / 2, screen.height / 2.4);
    final target = widget.targetPosition ??
        Offset(
          screen.width - 30 - media.padding.right,
          media.padding.top + 36,
        );

    return AnimatedBuilder(
      animation: _master,
      builder: (_, __) {
        final t = _master.value;
        // Barrier fades in over the first 200 ms, holds, fades out at end.
        final barrierOpacity = (() {
          if (t < 0.15) return (t / 0.15) * 0.55;
          if (t > 0.82) return ((1.0 - t) / 0.18) * 0.55;
          return 0.55;
        })();
        // Label holds for the whole coin flight — it stays up while the
        // coins stream into the garden, then fades out over the final
        // stretch as the last coins land.
        final labelOpacity = (() {
          if (t < 0.1) return t / 0.1;
          if (t > 0.86) return ((1.0 - t) / 0.14).clamp(0.0, 1.0);
          return 1.0;
        })();

        // Build per-particle widgets.
        final coinWidgets = <Widget>[];
        final landingBursts = <Widget>[];
        for (final p in _particles) {
          final localT =
              ((t - p.launchDelay) / p.travel).clamp(0.0, 1.0).toDouble();
          if (localT <= 0) continue;
          final u = _ease(localT);

          // Bezier control point — biased upward and fanned out by
          // launchAngle. This makes each coin sweep out and converge.
          final control = Offset(
            centerStart.dx + math.sin(p.launchAngle) * p.launchDistance,
            centerStart.dy -
                math.cos(p.launchAngle).abs() * p.launchDistance * 0.7 -
                40,
          );
          final pos = _bezier(u, centerStart, control, target);

          // Spin around its own centre.
          final yRot = p.spinTurns * u * math.pi * 2;
          // Fade in over the first 12% of the particle's life and fade
          // out over the last 8% so the convergence reads cleanly.
          final pOpacity = (() {
            if (localT < 0.12) return localT / 0.12;
            if (localT > 0.92) return ((1.0 - localT) / 0.08).clamp(0.0, 1.0);
            return 1.0;
          })();

          coinWidgets.add(Positioned(
            left: pos.dx - p.size / 2,
            top: pos.dy - p.size / 2,
            width: p.size,
            height: p.size,
            child: Opacity(
              opacity: pOpacity,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(yRot),
                child: SabiqCoin(size: p.size, sprouting: p.sprouting),
              ),
            ),
          ));

          // When a coin has just landed (localT ≈ 1), paint a brief
          // burst ring at the target. We trigger once per particle.
          if (localT >= 0.95) {
            final burstT = ((localT - 0.95) / 0.05).clamp(0.0, 1.0);
            final ringSize = 24 + 38 * burstT * (p.size / 30);
            landingBursts.add(Positioned(
              left: target.dx - ringSize / 2,
              top: target.dy - ringSize / 2,
              width: ringSize,
              height: ringSize,
              child: Opacity(
                opacity: (1.0 - burstT).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFE89A),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66FFD662),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ));
          }
        }

        return Material(
          color: Colors.black.withValues(alpha: barrierOpacity),
          child: Stack(
            children: [
              // Caption — fades in with the burst and out before flight ends.
              Positioned(
                left: 0,
                right: 0,
                top: centerStart.dy + 90,
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
              // Individual coins (small first, heroes on top).
              ...coinWidgets,
              // Landing bursts at the wallet.
              ...landingBursts,
            ],
          ),
        );
      },
    );
  }
}

class _CoinParticle {
  final double size;          // diameter in logical px
  final double launchDelay;   // fraction of total [0, 0.3]
  final double travel;        // fraction of total to fly [0.45, 0.7]
  final double spinTurns;     // signed rotations during flight
  final double launchAngle;   // radians; 0 = straight up
  final double launchDistance;// control-point distance
  final bool sprouting;       // hero variant with leaf
  final int zOrder;           // 0=small, 1=medium, 2=hero (drawn on top)

  const _CoinParticle({
    required this.size,
    required this.launchDelay,
    required this.travel,
    required this.spinTurns,
    required this.launchAngle,
    required this.launchDistance,
    required this.sprouting,
    required this.zOrder,
  });
}
