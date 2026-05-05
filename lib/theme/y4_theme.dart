// lib/theme/y4_theme.dart
//
// Y4 — Honey + Sage Garden theme.
// Single source of truth for the new app-wide palette + typography. Imported
// by both the central ThemeData (main.dart) and individual screens that want
// to reference the palette directly (dashboard, etc.).
//
// Per the design lineage in copy-of-noor-rewards-v1, this is the warm
// honey/sage variant with cream surfaces and Fraunces serif for display.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Public palette tokens — use these everywhere instead of hardcoded colors
/// when adopting the Y4 look.
class Y4 {
  // ── Surfaces ────────────────────────────────────────────────────────────
  static const bg = Color(0xFFFFF4D2); // honey wash background
  static const cream = Color(0xFFFFFAE3);
  static const surface = Color(0xFFFFFFFF);

  // ── Text / ink ──────────────────────────────────────────────────────────
  static const ink = Color(0xFF2A2410);
  static const inkSoft = Color(0xFF766B47);
  static const muted = Color(0xFFB8AC85);

  // ── Sage / olive (primary) ──────────────────────────────────────────────
  static const primary = Color(0xFF7A8C3A);
  static const primaryDeep = Color(0xFF4D5C20);

  // ── Honey / butter / amber (accents) ────────────────────────────────────
  static const honey = Color(0xFFFFC83D);
  static const honeyDeep = Color(0xFFD89A1E);
  static const butter = Color(0xFFFFE89A);
  static const amberY = Color(0xFFE8A84A);

  // ── Earth tones (planters / streak base) ────────────────────────────────
  static const soil = Color(0xFF8A5A3B);
  static const soilDeep = Color(0xFF6D4528);

  // ── UI scaffolding ──────────────────────────────────────────────────────
  static const track = Color(0xFFF4E5B0);
  static const border = Color(0x1A2A2410); // rgba(42,36,16,0.1)

  /// Fraunces serif — used for display headings, hero numbers, italic accents.
  static TextStyle display({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    Color color = ink,
    double letterSpacing = -0.01,
    double height = 1.0,
  }) => GoogleFonts.fraunces(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  // ── Material-3 ColorScheme ──────────────────────────────────────────────
  /// Y4-tuned light color scheme. Use as the base for [ThemeData.colorScheme].
  static ColorScheme get colorScheme => ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: butter,
    onPrimaryContainer: ink,
    secondary: honeyDeep,
    onSecondary: Colors.white,
    secondaryContainer: cream,
    onSecondaryContainer: ink,
    tertiary: amberY,
    onTertiary: Colors.white,
    surface: surface,
    onSurface: ink,
    error: const Color(0xFFB3261E),
    onError: Colors.white,
  );

  /// Build a global [ThemeData] that applies the Y4 palette + typography to
  /// any screen that uses Theme/Material widgets. Per-screen hardcoded styles
  /// (e.g. `GoogleFonts.outfit(...)` calls) are NOT overridden — those are
  /// updated screen-by-screen as a follow-up.
  static ThemeData buildTheme() {
    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    // Outfit text theme + Fraunces for display levels (matches the dashboard
    // hero / streak / progress styling).
    final textTheme = base.textTheme.copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: ink,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: ink,
        letterSpacing: -0.4,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: ink,
        letterSpacing: -0.3,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: inkSoft,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: inkSoft,
        letterSpacing: 0.8,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: honeyDeep,
        unselectedItemColor: muted,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: honeyDeep,
        unselectedLabelColor: inkSoft,
        indicatorColor: honeyDeep,
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      iconTheme: const IconThemeData(color: ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: honeyDeep,
        linearTrackColor: track,
        circularTrackColor: track,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: honeyDeep,
        inactiveTrackColor: track,
        thumbColor: honey,
        overlayColor: Color(0x33D89A1E),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? honey : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? honeyDeep : track,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? honeyDeep : Colors.transparent,
        ),
        side: const BorderSide(color: muted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? honeyDeep : muted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: honeyDeep,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: honeyDeep,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: honeyDeep,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          side: const BorderSide(color: honeyDeep, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: honeyDeep,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: honeyDeep, width: 1.5),
        ),
        labelStyle: GoogleFonts.outfit(
          color: inkSoft,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.outfit(
          color: muted,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cream,
        selectedColor: honey,
        labelStyle: GoogleFonts.outfit(color: ink, fontWeight: FontWeight.w600),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: ink,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
