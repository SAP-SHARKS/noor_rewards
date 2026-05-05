// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  NOOR THEME TOKENS
// ─────────────────────────────────────────────

class NoorColors {
  NoorColors._();

  // Primary
  static const emerald = Color(0xFF0B6B5C);
  static const emeraldLight = Color(0xFF2BAE99);
  static const gold = Color(0xFFD4A017);
  static const goldLight = Color(0xFFF5C842);

  // Neutrals
  static const cream = Color(0xFFFAF6F1);
  static const sand = Color(0xFFEDE6DC);
  static const ink = Color(0xFF1A1A2E);
  static const slate = Color(0xFF6B7280);
  static const white = Color(0xFFFFFFFF);

  // Accents
  static const amethyst = Color(0xFF6B4EBB);
  static const coral = Color(0xFFE8643A);
  static const mint = Color(0xFFEDF7F4);
  static const ruby = Color(0xFFE53935);
  static const sky = Color(0xFF78C1F3);

  // Dark
  static const night = Color(0xFF0A1628);
  static const nightCard = Color(0xFF152238);
  static const nightText = Color(0xFFE8E4DF);

  // Gradients
  static const emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, emeraldLight],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldLight],
  );
}

class NoorSpacing {
  NoorSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class NoorRadius {
  NoorRadius._();
  static final sm = BorderRadius.circular(12);
  static final md = BorderRadius.circular(18);
  static final lg = BorderRadius.circular(28);
  static final full = BorderRadius.circular(999);
}

class NoorShadows {
  NoorShadows._();
  static final card = [
    BoxShadow(
      color: NoorColors.ink.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
  static final elevated = [
    BoxShadow(
      color: NoorColors.ink.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  static final emeraldGlow = [
    BoxShadow(
      color: NoorColors.emerald.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  static final goldGlow = [
    BoxShadow(
      color: NoorColors.gold.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

class NoorType {
  NoorType._();
  static TextStyle displayLg = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: NoorColors.ink,
  );
  static TextStyle displayMd = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    color: NoorColors.ink,
  );
  static TextStyle titleLg = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: NoorColors.ink,
  );
  static TextStyle titleMd = GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.41,
    color: NoorColors.ink,
  );
  static TextStyle bodyLg = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: NoorColors.ink,
  );
  static TextStyle bodyMd = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: NoorColors.slate,
  );
  static TextStyle caption = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: NoorColors.slate,
  );
  static TextStyle label = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
    color: NoorColors.white,
  );
  static TextStyle arabicDisplay = GoogleFonts.amiri(
    fontSize: 28,
    height: 1.71,
    color: NoorColors.ink,
  );
  static TextStyle arabicBody = GoogleFonts.amiri(
    fontSize: 22,
    height: 1.82,
    color: NoorColors.ink,
  );
}

// ─────────────────────────────────────────────
//  CUSTOM BUTTON WIDGETS
// ─────────────────────────────────────────────

class NoorPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const NoorPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  State<NoorPrimaryButton> createState() => _NoorPrimaryButtonState();
}

class _NoorPrimaryButtonState extends State<NoorPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: enabled ? (_) => _ctrl.forward() : null,
        onTapUp:
            enabled
                ? (_) {
                  _ctrl.reverse();
                  widget.onPressed?.call();
                }
                : null,
        onTapCancel: enabled ? () => _ctrl.reverse() : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.4,
          duration: Duration(milliseconds: 200),
          child: Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: NoorSpacing.lg),
            decoration: BoxDecoration(
              gradient: NoorColors.emeraldGradient,
              borderRadius: NoorRadius.lg,
              boxShadow: enabled ? NoorShadows.emeraldGlow : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: NoorColors.white, size: 18),
                  SizedBox(width: NoorSpacing.sm),
                ],
                Text(widget.text.toUpperCase(), style: NoorType.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoorSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const NoorSecondaryButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: NoorSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: NoorRadius.lg,
          border: Border.all(color: NoorColors.emerald, width: 2),
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: NoorType.label.copyWith(color: NoorColors.emerald),
          ),
        ),
      ),
    );
  }
}

class NoorGoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const NoorGoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  State<NoorGoldButton> createState() => _NoorGoldButtonState();
}

class _NoorGoldButtonState extends State<NoorGoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) {
          return Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: NoorSpacing.lg),
            decoration: BoxDecoration(
              gradient: NoorColors.goldGradient,
              borderRadius: NoorRadius.lg,
              boxShadow: NoorShadows.goldGlow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shimmer sweep
                ClipRRect(
                  borderRadius: NoorRadius.lg,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment(-1.0 + 3.0 * _shimmer.value, 0),
                        end: Alignment(-0.5 + 3.0 * _shimmer.value, 0),
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      height: 52,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: NoorColors.ink, size: 18),
                      SizedBox(width: NoorSpacing.sm),
                    ],
                    Text(
                      widget.text.toUpperCase(),
                      style: NoorType.label.copyWith(color: NoorColors.ink),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class NoorGhostButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const NoorGhostButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: NoorColors.slate,
        textStyle: NoorType.bodyMd.copyWith(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: NoorRadius.lg),
        padding: EdgeInsets.symmetric(
          horizontal: NoorSpacing.md,
          vertical: NoorSpacing.sm,
        ),
      ),
      child: Text(text),
    );
  }
}

// ─────────────────────────────────────────────
//  CARD WIDGETS
// ─────────────────────────────────────────────

class NoorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const NoorCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(NoorSpacing.md),
      decoration: BoxDecoration(
        color: NoorColors.white,
        borderRadius: NoorRadius.md,
        boxShadow: NoorShadows.card,
      ),
      child: child,
    );
  }
}

class NoorElevatedCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const NoorElevatedCard({
    super.key,
    required this.child,
    this.accentColor = NoorColors.emerald,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NoorColors.white,
        borderRadius: NoorRadius.md,
        boxShadow: NoorShadows.elevated,
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      padding: EdgeInsets.all(NoorSpacing.md),
      child: child,
    );
  }
}

class NoorGlassCard extends StatelessWidget {
  final Widget child;

  const NoorGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(NoorSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: NoorRadius.md,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  TIER BADGE
// ─────────────────────────────────────────────

class NoorTierBadge extends StatelessWidget {
  final String tier;
  final Color color;
  final IconData icon;

  const NoorTierBadge({
    super.key,
    required this.tier,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: NoorRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            tier,
            style: NoorType.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GEOMETRIC PATTERN PAINTER (Islamic motif)
// ─────────────────────────────────────────────

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = NoorColors.sand.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

    const spacing = 48.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawEightPointStar(canvas, Offset(x, y), 16, paint);
      }
    }
  }

  void _drawEightPointStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) - pi / 2;
      final outerX = center.dx + radius * cos(angle);
      final outerY = center.dy + radius * sin(angle);
      final innerAngle = angle + pi / 8;
      final innerR = radius * 0.5;
      final innerX = center.dx + innerR * cos(innerAngle);
      final innerY = center.dy + innerR * sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  DEMO APP
// ─────────────────────────────────────────────

void main() => runApp(NoorThemeDemoApp());

class NoorThemeDemoApp extends StatelessWidget {
  const NoorThemeDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor Design System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: NoorColors.emerald,
        useMaterial3: true,
        scaffoldBackgroundColor: NoorColors.cream,
      ),
      home: ThemeDemoScreen(),
    );
  }
}

class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({super.key});

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  int _navIndex = 0;

  final _navItems = const [
    _NavItem(Icons.home_rounded, 'Home', NoorColors.coral),
    _NavItem(Icons.favorite_rounded, 'Impact', NoorColors.emeraldLight),
    _NavItem(Icons.emoji_events_rounded, 'Ranking', NoorColors.gold),
    _NavItem(Icons.person_rounded, 'Profile', NoorColors.amethyst),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoorColors.cream,
      body: Stack(
        children: [
          // Islamic geometric watermark
          Positioned.fill(
            child: CustomPaint(painter: _IslamicPatternPainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: NoorSpacing.xl,
                vertical: NoorSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: NoorColors.emeraldGradient,
                          borderRadius: NoorRadius.full,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: NoorColors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: NoorSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Noor Rewards', style: NoorType.displayMd),
                            Text(
                              'Modern Islamic Minimalist',
                              style: NoorType.bodyMd,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Color Palette ──
                  Text('Color Palette', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),
                  _ColorRow('Primary', [
                    _Swatch('Emerald', NoorColors.emerald),
                    _Swatch('Emerald Lt', NoorColors.emeraldLight),
                    _Swatch('Gold', NoorColors.gold),
                    _Swatch('Gold Lt', NoorColors.goldLight),
                  ]),
                  SizedBox(height: NoorSpacing.sm),
                  _ColorRow('Neutrals', [
                    _Swatch('Cream', NoorColors.cream),
                    _Swatch('Sand', NoorColors.sand),
                    _Swatch('Slate', NoorColors.slate),
                    _Swatch('Ink', NoorColors.ink),
                  ]),
                  SizedBox(height: NoorSpacing.sm),
                  _ColorRow('Accents', [
                    _Swatch('Amethyst', NoorColors.amethyst),
                    _Swatch('Coral', NoorColors.coral),
                    _Swatch('Ruby', NoorColors.ruby),
                    _Swatch('Sky', NoorColors.sky),
                  ]),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Typography ──
                  Text('Typography', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),
                  NoorCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Display Large', style: NoorType.displayLg),
                        SizedBox(height: NoorSpacing.xs),
                        Text('Display Medium', style: NoorType.displayMd),
                        SizedBox(height: NoorSpacing.xs),
                        Text('Title Large', style: NoorType.titleLg),
                        SizedBox(height: NoorSpacing.xs),
                        Text('Title Medium', style: NoorType.titleMd),
                        SizedBox(height: NoorSpacing.xs),
                        Text(
                          'Body Large — The quick brown fox',
                          style: NoorType.bodyLg,
                        ),
                        SizedBox(height: NoorSpacing.xs),
                        Text(
                          'Body Medium — Secondary text',
                          style: NoorType.bodyMd,
                        ),
                        SizedBox(height: NoorSpacing.xs),
                        Text('Caption — 12px details', style: NoorType.caption),
                        Divider(height: NoorSpacing.lg, color: NoorColors.sand),
                        Text(
                          'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
                          style: NoorType.arabicDisplay,
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: NoorSpacing.sm),
                        Text(
                          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                          style: NoorType.arabicBody,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Buttons ──
                  Text('Buttons', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),
                  Wrap(
                    spacing: NoorSpacing.md,
                    runSpacing: NoorSpacing.md,
                    children: [
                      NoorPrimaryButton(
                        text: 'Start Journey',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {},
                      ),
                      NoorSecondaryButton(text: 'Learn More', onPressed: () {}),
                    ],
                  ),
                  SizedBox(height: NoorSpacing.md),
                  Wrap(
                    spacing: NoorSpacing.md,
                    runSpacing: NoorSpacing.md,
                    children: [
                      NoorGoldButton(
                        text: 'Claim Reward',
                        icon: Icons.star_rounded,
                        onPressed: () {},
                      ),
                      NoorGhostButton(text: 'Skip for now', onPressed: () {}),
                    ],
                  ),
                  SizedBox(height: NoorSpacing.sm),
                  NoorPrimaryButton(text: 'Disabled State', onPressed: null),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Cards ──
                  Text('Card System', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),

                  // Standard card
                  NoorCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: NoorColors.mint,
                            borderRadius: NoorRadius.sm,
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: NoorColors.emerald,
                          ),
                        ),
                        SizedBox(width: NoorSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Standard Card', style: NoorType.titleMd),
                              Text(
                                'Subtle shadow, clean surface',
                                style: NoorType.bodyMd,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: NoorSpacing.md),

                  // Elevated card
                  NoorElevatedCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: NoorColors.goldGradient,
                            borderRadius: NoorRadius.sm,
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: NoorColors.ink,
                          ),
                        ),
                        SizedBox(width: NoorSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Elevated Card', style: NoorType.titleMd),
                              Text(
                                'Emerald accent border + deep shadow',
                                style: NoorType.bodyMd,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: NoorSpacing.md),

                  // Gold elevated card
                  NoorElevatedCard(
                    accentColor: NoorColors.gold,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: NoorColors.coral,
                              size: 28,
                            ),
                            SizedBox(width: NoorSpacing.sm),
                            Text('7-Day Streak!', style: NoorType.titleLg),
                          ],
                        ),
                        SizedBox(height: NoorSpacing.sm),
                        Text(
                          'You\'ve been consistent for a whole week. Keep going!',
                          style: NoorType.bodyMd,
                        ),
                        SizedBox(height: NoorSpacing.md),
                        _ProgressBar(value: 0.7, color: NoorColors.coral),
                      ],
                    ),
                  ),

                  SizedBox(height: NoorSpacing.md),

                  // Glass card on gradient
                  Container(
                    padding: EdgeInsets.all(NoorSpacing.md),
                    decoration: BoxDecoration(
                      gradient: NoorColors.emeraldGradient,
                      borderRadius: NoorRadius.md,
                    ),
                    child: NoorGlassCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: NoorColors.white,
                            size: 32,
                          ),
                          SizedBox(width: NoorSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Glass Card',
                                  style: NoorType.titleMd.copyWith(
                                    color: NoorColors.white,
                                  ),
                                ),
                                Text(
                                  'Frosted overlay on gradient backgrounds',
                                  style: NoorType.bodyMd.copyWith(
                                    color: NoorColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Points / Gamification Demo ──
                  Text('Gamification', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),

                  NoorCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level 12',
                                  style: NoorType.displayMd.copyWith(
                                    color: NoorColors.emerald,
                                  ),
                                ),
                                Text(
                                  '1,240 / 2,000 pts',
                                  style: NoorType.bodyMd,
                                ),
                              ],
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: NoorColors.emeraldGradient,
                                shape: BoxShape.circle,
                                boxShadow: NoorShadows.emeraldGlow,
                              ),
                              child: Center(
                                child: Text(
                                  '12',
                                  style: NoorType.titleLg.copyWith(
                                    color: NoorColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: NoorSpacing.md),
                        _ProgressBar(value: 0.62, color: NoorColors.emerald),
                        SizedBox(height: NoorSpacing.lg),
                        Text('Tier Badges', style: NoorType.titleMd),
                        SizedBox(height: NoorSpacing.sm),
                        Wrap(
                          spacing: NoorSpacing.sm,
                          runSpacing: NoorSpacing.sm,
                          children: [
                            NoorTierBadge(
                              tier: 'Seeker',
                              color: NoorColors.sky,
                              icon: Icons.eco_rounded,
                            ),
                            NoorTierBadge(
                              tier: 'Believer',
                              color: Color(0xFF4CAF50),
                              icon: Icons.park_rounded,
                            ),
                            NoorTierBadge(
                              tier: 'Devoted',
                              color: NoorColors.amethyst,
                              icon: Icons.nightlight_rounded,
                            ),
                            NoorTierBadge(
                              tier: 'Champion',
                              color: NoorColors.gold,
                              icon: Icons.workspace_premium_rounded,
                            ),
                            NoorTierBadge(
                              tier: 'Legend',
                              color: NoorColors.ruby,
                              icon: Icons.auto_awesome,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Spacing & Radius ──
                  Text('Spacing Scale', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),
                  NoorCard(
                    child: Column(
                      children: [
                        for (final s in [
                          ('xs', 4.0),
                          ('sm', 8.0),
                          ('md', 16.0),
                          ('lg', 24.0),
                          ('xl', 32.0),
                        ])
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    s.$1,
                                    style: NoorType.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: s.$2 * 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    gradient: NoorColors.emeraldGradient,
                                    borderRadius: NoorRadius.full,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${s.$2.toInt()}px',
                                  style: NoorType.caption,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: NoorSpacing.xxl),

                  // ── Dark Mode Preview ──
                  Text('Dark Mode Preview', style: NoorType.titleLg),
                  SizedBox(height: NoorSpacing.md),
                  Container(
                    padding: EdgeInsets.all(NoorSpacing.lg),
                    decoration: BoxDecoration(
                      color: NoorColors.night,
                      borderRadius: NoorRadius.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Noor Rewards',
                          style: NoorType.displayMd.copyWith(
                            color: NoorColors.nightText,
                          ),
                        ),
                        SizedBox(height: NoorSpacing.sm),
                        Text(
                          'Dark mode uses deep navy tones with warm text.',
                          style: NoorType.bodyLg.copyWith(
                            color: NoorColors.nightText.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: NoorSpacing.md),
                        Container(
                          padding: EdgeInsets.all(NoorSpacing.md),
                          decoration: BoxDecoration(
                            color: NoorColors.nightCard,
                            borderRadius: NoorRadius.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: NoorColors.goldGradient,
                                  borderRadius: NoorRadius.sm,
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  color: NoorColors.ink,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: NoorSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dark Card',
                                      style: NoorType.titleMd.copyWith(
                                        color: NoorColors.nightText,
                                      ),
                                    ),
                                    Text(
                                      '+50 pts earned today',
                                      style: NoorType.bodyMd.copyWith(
                                        color: NoorColors.nightText.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 100), // space for nav bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Navigation ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NoorColors.white,
          boxShadow: [
            BoxShadow(
              color: NoorColors.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _navIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _navIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? item.activeColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                      borderRadius: NoorRadius.full,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          Container(
                            width: 6,
                            height: 3,
                            margin: EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: NoorColors.emerald,
                              borderRadius: NoorRadius.full,
                            ),
                          ),
                        Icon(
                          item.icon,
                          size: 24,
                          color:
                              selected ? NoorColors.emerald : NoorColors.slate,
                        ),
                        SizedBox(height: 2),
                        Text(
                          item.label,
                          style: NoorType.caption.copyWith(
                            color:
                                selected
                                    ? NoorColors.emerald
                                    : NoorColors.slate,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──

class _NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  const _NavItem(this.icon, this.label, this.activeColor);
}

class _Swatch {
  final String name;
  final Color color;
  const _Swatch(this.name, this.color);
}

class _ColorRow extends StatelessWidget {
  final String label;
  final List<_Swatch> swatches;
  const _ColorRow(this.label, this.swatches);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NoorType.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: NoorSpacing.xs),
        Row(
          children:
              swatches.map((s) {
                final isLight = s.color.computeLuminance() > 0.5;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Column(
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: NoorRadius.sm,
                            border:
                                isLight
                                    ? Border.all(color: NoorColors.sand)
                                    : null,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          s.name,
                          style: NoorType.caption.copyWith(fontSize: 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: NoorColors.sand,
        borderRadius: NoorRadius.full,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: NoorRadius.full,
          ),
        ),
      ),
    );
  }
}
