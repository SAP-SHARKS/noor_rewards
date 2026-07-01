// lib/screens/qf_account_conflict_screen.dart
//
// Shown when a user tries to sign in via Quran.com but their QF email already
// belongs to an existing Sabiq Rewards account created with Email or Google.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class QfAccountConflictScreen extends StatefulWidget {
  /// The email that caused the conflict.
  final String email;

  /// Called when the user taps "Go Back" to return to the login screen.
  final VoidCallback onBack;

  const QfAccountConflictScreen({
    super.key,
    required this.email,
    required this.onBack,
  });

  @override
  State<QfAccountConflictScreen> createState() =>
      _QfAccountConflictScreenState();
}

class _QfAccountConflictScreenState extends State<QfAccountConflictScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // ── Background geometry ──────────────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GeoBgPainter())),

          // ── Pulsing glow behind icon ─────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseAnim,
            builder:
                (_, __) => Positioned(
                  top: MediaQuery.of(context).size.height * 0.18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(
                              0xFFFFAA00,
                            ).withValues(alpha: 0.10 + _pulseAnim.value * 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFAA00).withValues(alpha: 0.12),
                      border: Border.all(
                        color: const Color(0xFFFFAA00).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.link_off_rounded,
                      size: 44,
                      color: Color(0xFFFFAA00),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    l?.qfConflictTitle ?? 'Account Already Exists',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 15,
                          color: Color(0xFFFFAA00),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.email,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFAA00),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Explanation
                  Text(
                    l?.qfConflictExplanation ??
                        'This email is already registered with Sabiq Rewards using a different sign-in method (Email or Google).\n\nTo protect your existing progress, streaks, and Sabiq Seeds, please sign in using your original method.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white54,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── What to do section ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        _StepRow(
                          number: '1',
                          text:
                              l?.qfConflictStep1 ??
                              'Go back to the login screen',
                          color: const Color(0xFF2BAE99),
                        ),
                        const SizedBox(height: 14),
                        _StepRow(
                          number: '2',
                          text:
                              l?.qfConflictStep2(widget.email) ??
                              'Sign in with Email or Google using\n${widget.email}',
                          color: const Color(0xFF5856D6),
                        ),
                        const SizedBox(height: 14),
                        _StepRow(
                          number: '3',
                          text:
                              l?.qfConflictStep3 ??
                              'All your progress will be right there',
                          color: const Color(0xFFFFAA00),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Go Back button ─────────────────────────────────────
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2BAE99), Color(0xFF00866E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2BAE99,
                            ).withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l?.qfConflictBackButton ?? 'Back to Sign In',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step row ──────────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  final Color color;
  const _StepRow({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

// ── Background painter (same pattern as profile_setup_screen) ─────────────────
class _GeoBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7;
    const sp = 88.0;
    for (double y = 0; y < size.height + sp; y += sp) {
      for (double x = 0; x < size.width + sp; x += sp) {
        final path = Path();
        for (int i = 0; i < 16; i++) {
          final a = (i * math.pi / 8) - math.pi / 2;
          final r = i.isEven ? 26.0 : 11.0;
          final p = Offset(x + r * math.cos(a), y + r * math.sin(a));
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
