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
  // ── Legacy Y4 tokens (now palette-driven so every screen swaps) ────────
  /// Y4 honey — warm accent used across cards, chips, gradients
  final Color honey;
  /// Y4 deep honey — secondary/deep accent
  final Color honeyDeep;
  /// Y4 butter — soft yellow, primary containers
  final Color butter;
  /// Y4 cream — warm off-white surface
  final Color cream;
  /// Y4 primary-deep — darker sage / brand deep
  final Color primaryDeep;
  /// Y4 ink — main text
  final Color ink;
  /// Y4 ink-soft — secondary text
  final Color inkSoft;
  /// Y4 muted — placeholder text / low emphasis
  final Color muted;
  /// Y4 amberY — accent yellow
  final Color amberY;
  /// Y4 track — progress-bar / disabled slots
  final Color track;
  /// Y4 soil — earth-tone (streak base)
  final Color soil;

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
  /// Soft divider / card border colour (semi-transparent onSurface)
  final Color border;
  /// "Seal" gradient — Seeds-pending pill + Seal-the-Day slider track.
  /// Honey mode keeps its original emerald so the default theme is
  /// pixel-for-pixel unchanged.
  final Color accentSeal;
  /// Deep variant of accentSeal for gradient end / shadow tint.
  final Color accentSealDeep;

  const ThemePalette({
    required this.honey,
    required this.honeyDeep,
    required this.butter,
    required this.cream,
    required this.primaryDeep,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.amberY,
    required this.track,
    required this.soil,
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
    required this.border,
    required this.accentSeal,
    required this.accentSealDeep,
  });
}

/// Named theme modes shipped with the app. Add a new entry to expose it
/// in the admin Theme & Branding panel automatically.
const kThemeModes = <String, ThemePalette>{
  // ── Honey (default) — warm sage + gold ────────────────────────────────
  'honey': ThemePalette(
    honey:            Color(0xFFFFC83D),
    honeyDeep:        Color(0xFFD89A1E),
    butter:           Color(0xFFFFE89A),
    cream:            Color(0xFFFFFAE3),
    primaryDeep:      Color(0xFF4D5C20),
    ink:              Color(0xFF2A2410),
    inkSoft:          Color(0xFF766B47),
    muted:            Color(0xFFB8AC85),
    amberY:           Color(0xFFE8A84A),
    track:            Color(0xFFF4E5B0),
    soil:             Color(0xFF8A5A3B),
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
    border:           Color(0x1A2A2410),
    accentSeal:       Color(0xFF4A9B8E),
    accentSealDeep:   Color(0xFF1F4F3D),
  ),

  // ── Mint — cool green throughout ──────────────────────────────────────
  'mint': ThemePalette(
    honey:            Color(0xFF6BC49A),
    honeyDeep:        Color(0xFF3E8562),
    butter:           Color(0xFFD8EFDF),
    cream:            Color(0xFFF2FAF5),
    primaryDeep:      Color(0xFF1E5A3E),
    ink:              Color(0xFF0F3D28),
    inkSoft:          Color(0xFF446B57),
    muted:            Color(0xFF9DC0AD),
    amberY:           Color(0xFF5FB88A),
    track:            Color(0xFFC5E8D2),
    soil:             Color(0xFF6E8C7A),
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
    border:           Color(0x1A0F3D28),
    accentSeal:       Color(0xFF4E9F7A),
    accentSealDeep:   Color(0xFF1E5A3E),
  ),

  // ── Sky — cool blue palette ───────────────────────────────────────────
  'sky': ThemePalette(
    honey:            Color(0xFF4EA0E5),
    honeyDeep:        Color(0xFF2E7CB8),
    butter:           Color(0xFFCFE4F5),
    cream:            Color(0xFFF3FAFF),
    primaryDeep:      Color(0xFF1A4E7A),
    ink:              Color(0xFF103A5C),
    inkSoft:          Color(0xFF456A85),
    muted:            Color(0xFFA0B8CC),
    amberY:           Color(0xFF6BB0E5),
    track:            Color(0xFFB8E0F0),
    soil:             Color(0xFF6B7A85),
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
    border:           Color(0x1A103A5C),
    accentSeal:       Color(0xFF2E7CB8),
    accentSealDeep:   Color(0xFF1A4E7A),
  ),

  // ── Rose — warm pink / coral ──────────────────────────────────────────
  'rose': ThemePalette(
    honey:            Color(0xFFE5A088),
    honeyDeep:        Color(0xFFC87A94),
    butter:           Color(0xFFF8D8DC),
    cream:            Color(0xFFFDF6F6),
    primaryDeep:      Color(0xFF7A2E4A),
    ink:              Color(0xFF4C1E28),
    inkSoft:          Color(0xFF7A4E58),
    muted:            Color(0xFFC2A0A8),
    amberY:           Color(0xFFE58B70),
    track:            Color(0xFFF5D2AA),
    soil:             Color(0xFF8A5A5A),
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
    border:           Color(0x1A4C1E28),
    accentSeal:       Color(0xFFC87A94),
    accentSealDeep:   Color(0xFF7A2E4A),
  ),

  // ── Gray — editorial neutral ──────────────────────────────────────────
  'gray': ThemePalette(
    honey:            Color(0xFF7A7A7A),
    honeyDeep:        Color(0xFF4A4A4A),
    butter:           Color(0xFFE0E0E0),
    cream:            Color(0xFFF7F7F7),
    primaryDeep:      Color(0xFF2E2E2E),
    ink:              Color(0xFF1F1F1F),
    inkSoft:          Color(0xFF5A5A5A),
    muted:            Color(0xFFB0B0B0),
    amberY:           Color(0xFF888888),
    track:            Color(0xFFD8D8D8),
    soil:             Color(0xFF6A6A6A),
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
    border:           Color(0x1A1F1F1F),
    accentSeal:       Color(0xFF7A7A7A),
    accentSealDeep:   Color(0xFF2E2E2E),
  ),

  // ── Black — dark mode ─────────────────────────────────────────────────
  'black': ThemePalette(
    honey:            Color(0xFFFFC83D),
    honeyDeep:        Color(0xFFE5A430),
    butter:           Color(0xFF3A3020),
    cream:            Color(0xFF2A2418),
    primaryDeep:      Color(0xFFB8862E),
    ink:              Color(0xFFF0F0F0),
    inkSoft:          Color(0xFFB0B0B0),
    muted:            Color(0xFF707070),
    amberY:           Color(0xFFE8A84A),
    track:            Color(0xFF3A3A3A),
    soil:             Color(0xFF6A5030),
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
    border:           Color(0x1AF0F0F0),
    accentSeal:       Color(0xFF4A9B8E),
    accentSealDeep:   Color(0xFF1F4F3D),
  ),
};

/// Returns the palette for the given mode key, or Honey if unknown.
ThemePalette paletteForMode(String? mode) =>
    kThemeModes[mode] ?? kThemeModes['honey']!;
