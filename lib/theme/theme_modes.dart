// lib/theme/theme_modes.dart
//
// One-click app-wide theme modes. Each mode is a complete palette of
// semantic accent tokens that were previously hardcoded across widgets
// (podium gradients, streak pill, engagement strip, reminder card, etc.).
//
// A mode is selected via the `app_theme_mode` row in Supabase's app_config
// (admin picks in the "Theme & Branding" panel). Widgets read colours via
// `Y4.palette.accentGold` etc. — see `y4_theme.dart`.

import 'package:flutter/material.dart';

/// Semantic accent tokens. Every mode fills in the same set; widgets read
/// via `Y4.palette.<token>` instead of hardcoding a hex.
class ThemePalette {
  /// Podium #1 / hero honey — warmest brand hue
  final Color accentGold;
  /// Podium #2 — cool neutral tone
  final Color accentSilver;
  /// Podium #3 — earthy contrast
  final Color accentBronze;
  /// Streak flame gradient (start colour)
  final Color accentStreak;
  /// Streak flame gradient (end colour, deeper)
  final Color accentStreakDeep;
  /// Fresh mint tint used for engagement bg + reminder accent + rank sticker
  final Color accentMint;
  /// Deeper olive/mint for the reminder card's left accent bar
  final Color accentOlive;
  /// Success green (deed pills, +today chips, "done" states)
  final Color accentSuccess;
  /// Error / destructive
  final Color accentDanger;
  /// Info blue (country chip, links)
  final Color accentInfo;
  /// Soft rose accent (rank badge palette)
  final Color accentRose;
  /// Soft butter/yellow accent
  final Color accentButter;
  /// M3 primary — brand seed
  final Color primary;
  /// M3 secondary — alt accent
  final Color secondary;
  /// M3 surface — cards/sheets
  final Color surface;
  /// M3 background — page bg
  final Color background;
  /// Foreground on primary
  final Color onPrimary;
  /// Foreground on surface
  final Color onSurface;

  const ThemePalette({
    required this.accentGold,
    required this.accentSilver,
    required this.accentBronze,
    required this.accentStreak,
    required this.accentStreakDeep,
    required this.accentMint,
    required this.accentOlive,
    required this.accentSuccess,
    required this.accentDanger,
    required this.accentInfo,
    required this.accentRose,
    required this.accentButter,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.onPrimary,
    required this.onSurface,
  });
}

/// Named theme modes shipped with the app. Add a new entry to expose it
/// in the admin Theme & Branding panel automatically.
const kThemeModes = <String, ThemePalette>{
  // ── Honey (default) — warm sage + gold ────────────────────────────────
  'honey': ThemePalette(
    accentGold:       Color(0xFFF7B65A),
    accentSilver:     Color(0xFFB7A6F4),
    accentBronze:     Color(0xFF8FCFA0),
    accentStreak:     Color(0xFFFF6E3C),
    accentStreakDeep: Color(0xFFD8421E),
    accentMint:       Color(0xFF8FCFA0),
    accentOlive:      Color(0xFF6B7A28),
    accentSuccess:    Color(0xFF2D8A4E),
    accentDanger:     Color(0xFFB91C1C),
    accentInfo:       Color(0xFF1565C0),
    accentRose:       Color(0xFFFF9A86),
    accentButter:     Color(0xFFE5B547),
    primary:          Color(0xFF7A8C3A),
    secondary:        Color(0xFFD89A1E),
    surface:          Color(0xFFFFFFFF),
    background:       Color(0xFFFFF4D2),
    onPrimary:        Color(0xFFFFFFFF),
    onSurface:        Color(0xFF2A2410),
  ),

  // ── Mint — cool green throughout ──────────────────────────────────────
  'mint': ThemePalette(
    accentGold:       Color(0xFF6BC49A),
    accentSilver:     Color(0xFFA0D8C4),
    accentBronze:     Color(0xFF4E9F7A),
    accentStreak:     Color(0xFF3FB07A),
    accentStreakDeep: Color(0xFF1E7C4E),
    accentMint:       Color(0xFF4E9F7A),
    accentOlive:      Color(0xFF2E6A48),
    accentSuccess:    Color(0xFF2D8A4E),
    accentDanger:     Color(0xFFD14E4E),
    accentInfo:       Color(0xFF4A9BB8),
    accentRose:       Color(0xFFF5A5A5),
    accentButter:     Color(0xFFC5E8D2),
    primary:          Color(0xFF4E9F7A),
    secondary:        Color(0xFF6BC49A),
    surface:          Color(0xFFFFFFFF),
    background:       Color(0xFFEAF7EF),
    onPrimary:        Color(0xFFFFFFFF),
    onSurface:        Color(0xFF0F3D28),
  ),

  // ── Sky — cool blue palette ───────────────────────────────────────────
  'sky': ThemePalette(
    accentGold:       Color(0xFF4EA0E5),
    accentSilver:     Color(0xFFA6C6E8),
    accentBronze:     Color(0xFF7BB3E4),
    accentStreak:     Color(0xFFFF7A3C),
    accentStreakDeep: Color(0xFFD8541E),
    accentMint:       Color(0xFF7BC4E8),
    accentOlive:      Color(0xFF285A85),
    accentSuccess:    Color(0xFF4EA75E),
    accentDanger:     Color(0xFFD14E4E),
    accentInfo:       Color(0xFF2E7CB8),
    accentRose:       Color(0xFFF5A5A5),
    accentButter:     Color(0xFFB8E0F0),
    primary:          Color(0xFF2E7CB8),
    secondary:        Color(0xFF4EA0E5),
    surface:          Color(0xFFFFFFFF),
    background:       Color(0xFFE8F3FB),
    onPrimary:        Color(0xFFFFFFFF),
    onSurface:        Color(0xFF103A5C),
  ),

  // ── Rose — warm pink / coral ──────────────────────────────────────────
  'rose': ThemePalette(
    accentGold:       Color(0xFFF2A88A),
    accentSilver:     Color(0xFFE8B8C4),
    accentBronze:     Color(0xFFC89478),
    accentStreak:     Color(0xFFF07070),
    accentStreakDeep: Color(0xFFC13030),
    accentMint:       Color(0xFFE8B7A0),
    accentOlive:      Color(0xFF8A4560),
    accentSuccess:    Color(0xFF6B9B54),
    accentDanger:     Color(0xFFC13030),
    accentInfo:       Color(0xFFB87A9E),
    accentRose:       Color(0xFFE5749E),
    accentButter:     Color(0xFFF5D2AA),
    primary:          Color(0xFFC87A94),
    secondary:        Color(0xFFE5A088),
    surface:          Color(0xFFFFFFFF),
    background:       Color(0xFFFBEEEE),
    onPrimary:        Color(0xFFFFFFFF),
    onSurface:        Color(0xFF4C1E28),
  ),

  // ── Gray — editorial neutral ──────────────────────────────────────────
  'gray': ThemePalette(
    accentGold:       Color(0xFF8A8A8A),
    accentSilver:     Color(0xFFB8B8B8),
    accentBronze:     Color(0xFF6A6A6A),
    accentStreak:     Color(0xFF6A6A6A),
    accentStreakDeep: Color(0xFF2E2E2E),
    accentMint:       Color(0xFF7A9080),
    accentOlive:      Color(0xFF4A5850),
    accentSuccess:    Color(0xFF5A7A5A),
    accentDanger:     Color(0xFF9A4A4A),
    accentInfo:       Color(0xFF6A7A9A),
    accentRose:       Color(0xFFA08080),
    accentButter:     Color(0xFFC0C0B0),
    primary:          Color(0xFF4A4A4A),
    secondary:        Color(0xFF7A7A7A),
    surface:          Color(0xFFFFFFFF),
    background:       Color(0xFFF5F5F5),
    onPrimary:        Color(0xFFFFFFFF),
    onSurface:        Color(0xFF1F1F1F),
  ),

  // ── Black — dark mode ─────────────────────────────────────────────────
  'black': ThemePalette(
    accentGold:       Color(0xFFE5B84A),
    accentSilver:     Color(0xFFC8C8C8),
    accentBronze:     Color(0xFF8A6A3A),
    accentStreak:     Color(0xFFFF6E3C),
    accentStreakDeep: Color(0xFFD8421E),
    accentMint:       Color(0xFF6BC4A0),
    accentOlive:      Color(0xFF4A6A4E),
    accentSuccess:    Color(0xFF4CAF50),
    accentDanger:     Color(0xFFF55555),
    accentInfo:       Color(0xFF6BB5FF),
    accentRose:       Color(0xFFFF8AA0),
    accentButter:     Color(0xFFF0D890),
    primary:          Color(0xFFFFC83D),
    secondary:        Color(0xFFD89A1E),
    surface:          Color(0xFF1F1F22),
    background:       Color(0xFF0F0F12),
    onPrimary:        Color(0xFF0F0F12),
    onSurface:        Color(0xFFF0F0F0),
  ),
};

/// Returns the palette for the given mode key, or Honey if unknown.
ThemePalette paletteForMode(String? mode) =>
    kThemeModes[mode] ?? kThemeModes['honey']!;
