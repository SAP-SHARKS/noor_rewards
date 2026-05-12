// lib/screens/onboarding_v2/widgets/onboarding_tokens.dart
//
// Design tokens for the Sabiq Phase 1 + Phase 2 onboarding.
// Mirrors the palette + type scale from the design bundle so the screens
// match the prototype 1:1.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnbTok {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const gold = Color(0xFFE8B84A);
  static const goldDeep = Color(0xFFC8932E);
  static const goldLight = Color(0xFFF5DC8C);
  static const cream = Color(0xFFFAF3E3);
  static const creamWarm = Color(0xFFF4E4B8);
  static const teal = Color(0xFF4A9B8E);
  static const tealDark = Color(0xFF2E6B62);
  static const brown = Color(0xFF3D2914);
  static const brownSoft = Color(0xFF6B4423);
  static const greySoft = Color(0xFF8A7860);

  // ── Type ─────────────────────────────────────────────────────────────────
  static TextStyle serif({
    double fontSize = 30,
    FontWeight fontWeight = FontWeight.w500,
    FontStyle fontStyle = FontStyle.normal,
    Color color = brown,
    double height = 1.15,
    double letterSpacing = -0.01 * 30,
  }) => GoogleFonts.newsreader(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle sans({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color color = brownSoft,
    double height = 1.45,
    double letterSpacing = 0,
  }) => GoogleFonts.dmSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle arabic({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    Color color = brown,
    double height = 1.6,
  }) => GoogleFonts.amiri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}
