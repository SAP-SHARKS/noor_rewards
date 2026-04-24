import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/data/qf_auth_service.dart';

class StartJourneyScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const StartJourneyScreen({super.key, this.onBack});

  @override
  State<StartJourneyScreen> createState() => _StartJourneyScreenState();
}

class _StartJourneyScreenState extends State<StartJourneyScreen> {
  bool _isLoading = false;

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
        queryParams: {
          'prompt': 'select_account',
        },
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Unexpected error during Google Sign In'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // ── Deep gradient background ───────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1628), // Deep midnight blue
                    Color(0xFF0D2137), // Dark navy
                    Color(0xFF0A2E1F), // Deep emerald
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Radial emerald glow (behind lantern) ───────────────────────────
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C875).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom gold glow ───────────────────────────────────────────────
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFAA00).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Floating Islamic icons in background ───────────────────────────
          _fi(Icons.mosque_rounded,       80,  left: 16,  size: 32, op: 0.07),
          _fi(Icons.mosque_rounded,       200, right: 14, size: 24, op: 0.06),
          _fi(Icons.nights_stay_rounded,  55,  right: 48, size: 28, op: 0.08),
          _fi(Icons.star_rounded,         130, left: 58,  size: 18, op: 0.09),
          _fi(Icons.star_rounded,         310, right: 38, size: 14, op: 0.07),
          _fi(Icons.favorite_rounded,     260, left: 20,  size: 20, op: 0.07),
          _fi(Icons.volunteer_activism,   430, right: 22, size: 24, op: 0.06),
          _fi(Icons.book_rounded,         510, left: 28,  size: 22, op: 0.06),
          _fi(Icons.self_improvement,     575, right: 32, size: 24, op: 0.07),
          _fi(Icons.nights_stay_rounded,   380, left: 12,  size: 16, op: 0.09),
          _fi(Icons.spa_rounded,          650, left: 46,  size: 20, op: 0.06),
          _fi(Icons.star_border_rounded,  700, right: 26, size: 22, op: 0.07),
          _fi(Icons.circle_outlined,      460, left: 60,  size: 12, op: 0.06),
          _fi(Icons.circle_outlined,      160, right: 70, size: 10, op: 0.07),

          // ── Islamic geometric star tiling ──────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _IslamicBgPainter()),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),

                  // Lantern card with emerald glow
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A4A2E),
                            Color(0xFF00C875),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C875).withValues(alpha: 0.4),
                            blurRadius: 48,
                            spreadRadius: 6,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Lottie.asset(
                          'assets/lottie/lantern.json',
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              size: 88,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Arabic tagline
                  Text(
                    'نُورُ الرَّحْمَةِ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00C875),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.lightOfMercy,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.white30,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Title
                  Text(
                    'Start Your Journey',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    AppLocalizations.of(context)!.trackSpiritualGrowth,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white54,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Google Sign-In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _googleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C875),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 0,
                      textStyle: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _GoogleLogo(size: 22),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.continueWithGoogle),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // QF Sign-In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        // Assuming QfAuthService is defined globally or we can just import it
                        await QfAuthService.instance.signIn();
                        if (context.mounted) {
                           // Navigate to dashboard or handle success
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully authenticated with Quran.com!')));
                        }
                      } catch (e) {
                         if (context.mounted && !e.toString().contains('cancelled')) {
                           showDialog(
                             context: context,
                             builder: (c) => AlertDialog(
                               title: const Text('Auth Error'),
                               content: SingleChildScrollView(child: Text(e.toString())),
                               actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                             )
                           );
                         }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A4A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 0,
                      textStyle: GoogleFonts.outfit(
                        fontSize: 16, // Use same size
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.book_rounded, size: 22, color: Color(0xFF00C875)),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.continueWithQuran),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Terms text
                  Text(
                    AppLocalizations.of(context)!.bySigningUp,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white24,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build a positioned floating icon
  Widget _fi(
    IconData icon,
    double top, {
    double? left,
    double? right,
    required double size,
    required double op,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Icon(icon, size: size, color: Colors.white.withValues(alpha: op)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Islamic geometric 8-pointed star background pattern
// ─────────────────────────────────────────────────────────────────────────────
class _IslamicBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const spacing = 88.0;
    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        _drawStar(canvas, Offset(x, y), 26, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    const innerRatio = 0.42;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius : radius * innerRatio;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Official Google "G" logo
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  static const String _svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svgString, width: size, height: size);
  }
}
