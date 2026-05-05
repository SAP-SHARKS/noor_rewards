// lib/theme/noor_theme.dart
// Centralized app theme that reads all colors from AppConfig (Supabase).
// Usage: final t = NoorTheme.of(context);
//        Container(color: t.bg, child: Text('hi', style: TextStyle(color: t.text)));

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_config.dart';
import '../services/settings_service.dart';

/// Provides all dynamic colors the app needs — derived from AppConfig.
/// Fallback defaults match the Noor Classic preset so the app looks correct
/// even before the first config fetch completes.
class NoorTheme {
  final AppConfig _cfg;
  const NoorTheme(this._cfg);

  /// Convenience: get from the nearest context (requires SettingsService in Provider tree).
  static NoorTheme of(BuildContext context) =>
      NoorTheme(context.watch<SettingsService>().config);

  // ── Brand ──────────────────────────────────────────────────────────────────
  Color get primary => _cfg.primaryColor;
  Color get secondary => _cfg.secondaryColor;
  Color get donation => _cfg.donationColor;

  // ── Page backgrounds ───────────────────────────────────────────────────────
  Color get bg => _cfg.dashBg;
  Color get text => _cfg.dashText;
  Color get accent => _cfg.dashTeal;

  // ── Derived neutrals (auto-generate from bg lightness) ─────────────────────
  Color get sub => _isLight ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF);
  Color get border =>
      _isLight ? const Color(0xFFE8E8EC) : const Color(0xFF374151);
  Color get card => _isLight ? Colors.white : const Color(0xFF1F2937);
  Color get darkBtn =>
      _isLight ? const Color(0xFF1C1C1E) : const Color(0xFF374151);
  Color get inputFill =>
      _isLight ? const Color(0xFFF2F2F7) : const Color(0xFF1F2937);

  // ── Quran ──────────────────────────────────────────────────────────────────
  Color get quranBg => _cfg.quranBg;
  Color get quranText => _cfg.quranTextColor;
  Color get quranAccent => _cfg.quranAccent;
  Color get quranGold => _cfg.quranGold;

  // ── Azkar ──────────────────────────────────────────────────────────────────
  Color get azkarAccent => _cfg.azkarAccent;
  Color get azkarMornGrad1 => _cfg.azkarMorningGrad1;
  Color get azkarMornGrad2 => _cfg.azkarMorningGrad2;
  Color get azkarEveGrad1 => _cfg.azkarEveningGrad1;
  Color get azkarEveGrad2 => _cfg.azkarEveningGrad2;
  Color get azkarBottomGrad1 => _cfg.azkarBottomGrad1;
  Color get azkarBottomGrad2 => _cfg.azkarBottomGrad2;
  Color get azkarHighlight => _cfg.azkarHighlight;

  // ── Banner ─────────────────────────────────────────────────────────────────
  Color get banner => _cfg.bannerColor;

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get _isLight => bg.computeLuminance() > 0.5;
}
