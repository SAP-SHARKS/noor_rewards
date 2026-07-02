// lib/models/app_config.dart
// Strongly-typed wrapper around the raw app_config key-value table.
// Defaults match the seeded Supabase values; safe to call before first fetch.

import 'package:flutter/material.dart';
import '../theme/theme_modes.dart';

class AppConfig {
  final Map<String, String> _raw;
  const AppConfig(this._raw);
  factory AppConfig.empty() => const AppConfig({});

  // ── Economy ────────────────────────────────────────────────────────────────
  int get coinsPerAyah => _int('coins_per_ayah', 10);
  int get coinsPerDhikr => _int('coins_per_dhikr', 20);
  int get coinsPerTafsir10min => _int('coins_per_tafsir_10min', 50);
  int get coinsPerDua => _int('coins_per_dua', 15);
  int get pointsDailyLogin => _int('points_daily_login', 5);
  int get pointsValidate => _int('points_validate', 20);
  int get dailyFreeCap => _int('daily_free_cap', 500);

  // ── Dhikr behaviour ────────────────────────────────────────────────────────
  /// Seconds to hold a completed dhikr on screen before auto-advancing to
  /// the next one. 0 keeps the current snappy advance (~120 ms). A positive
  /// value (e.g. 3) holds that many seconds — the user can still swipe
  /// manually at any time.
  int get dhikrAdvanceDelaySeconds => _int('dhikr_advance_delay_seconds', 0);

  /// Whether the auto-advance delay above applies to single-read azkar
  /// (counter target of 1 — read once and done). When false, those azkar
  /// always advance instantly regardless of dhikrAdvanceDelaySeconds.
  bool get dhikrDelaySingleRead => _bool('dhikr_delay_single_read', true);

  /// Whether the auto-advance delay applies to multi-count azkar (a dhikr
  /// counter, e.g. x33). When false, those azkar always advance instantly.
  bool get dhikrDelayMultiCount => _bool('dhikr_delay_multi_count', true);

  /// Admin toggle for the "live reading right now / frequently read"
  /// engagement strip on the Quran Hub. Hides the whole card when false.
  bool get showQuranEngagement => _bool('show_quran_engagement', true);

  /// Named palette mode. One of the keys in `theme/theme_modes.dart` —
  /// e.g. 'honey', 'mint', 'sky', 'rose', 'gray', 'black'.
  /// Drives semantic accent tokens across the whole app.
  String get themeMode => _str('app_theme_mode', 'honey');

  /// The active palette derived from [themeMode]. All theme colours below
  /// fall back to this palette when their explicit `<key>_color` row is
  /// absent — so just setting `app_theme_mode` recolours every screen.
  ThemePalette get _p => paletteForMode(themeMode);

  // ── Theme — Global (fall back to mode palette) ────────────────────────────
  Color get primaryColor => _color('primary_color', _p.primary);
  Color get secondaryColor => _color('secondary_color', _p.secondary);
  Color get donationColor => _color('donation_color', _p.honey);

  // ── Theme — Dashboard ─────────────────────────────────────────────────────
  Color get dashBg => _color('dash_bg', _p.background);
  Color get dashText => _color('dash_text', _p.onSurface);
  Color get dashTeal => _color('dash_teal', _p.honeyDeep);

  // ── Theme — Azkar/Dhikr ───────────────────────────────────────────────────
  Color get azkarAccent => _color('azkar_accent', _p.honeyDeep);
  Color get azkarMorningGrad1 => _color('azkar_morning_grad1', _p.cream);
  Color get azkarMorningGrad2 => _color('azkar_morning_grad2', _p.honey);
  Color get azkarEveningGrad1 => _color('azkar_evening_grad1', _p.primaryDeep);
  Color get azkarEveningGrad2 => _color('azkar_evening_grad2', _p.primary);
  Color get azkarBottomGrad1 => _color('azkar_bottom_grad1', _p.primaryDeep);
  Color get azkarBottomGrad2 => _color('azkar_bottom_grad2', _p.ink);
  Color get azkarHighlight => _color('azkar_highlight', _p.honeyDeep);

  // ── Theme — Quran ─────────────────────────────────────────────────────────
  Color get quranBg => _color('quran_bg', _p.cream);
  Color get quranAccent => _color('quran_accent', _p.honeyDeep);
  Color get quranGold => _color('quran_gold', _p.honey);
  Color get quranTextColor => _color('quran_text', _p.onSurface);

  // ── Feature Flags ──────────────────────────────────────────────────────────
  bool get featureLeaderboard => _bool('feature_leaderboard', true);
  bool get featureChallenges => _bool('feature_challenges', true);
  bool get featureBadges => _bool('feature_badges', true);
  bool get featureTafsir => _bool('feature_tafsir', true);
  bool get featureInvite => _bool('feature_invite', false);

  // ── Page / tab visibility (admin-controlled via the Features page) ─────────
  // Toggle a tab off from the admin panel to hide it for all users.
  bool get featureCause => _bool('feature_cause', true);
  bool get featureJourney => _bool('feature_journey', false);
  bool get featureAkhirah => _bool('feature_akhirah', true);

  // ── Limits ─────────────────────────────────────────────────────────────────
  String get minAppVersionIos => _str('min_app_version_ios', '1.0.0');
  String get minAppVersionAndroid => _str('min_app_version_android', '1.0.0');
  bool get maintenanceMode => _bool('maintenance_mode', false);
  int get maxBookmarks => _int('max_bookmarks', 200);

  // ── Messages / Banners ─────────────────────────────────────────────────────
  String get bannerText => _str('banner_text', '');
  Color get bannerColor =>
      _color('banner_color', const Color(0xFFD89A1E)); // Y4 honeyDeep
  bool get bannerEnabled => _bool('banner_enabled', false);
  String get supportEmail => _str('support_email', 'support@noorrewards.com');
  String get appStoreUrl => _str('app_store_url', '');
  String get playStoreUrl => _str('play_store_url', '');

  // ── Ad Placement ───────────────────────────────────────────────────────────
  bool get adBannerEnabled => _bool('ad_banner_enabled', false);
  String get adBannerText => _str('ad_banner_text', 'Ad Placement Banner');
  String get adBannerSubtitle => _str('ad_banner_subtitle', '');
  String get adBannerLink => _str('ad_banner_link', '');
  String get adBannerIconUrl => _str('ad_banner_icon_url', '');

  // ── Raw access (for admin panel dynamic rows) ──────────────────────────────
  Map<String, String> get raw => Map.unmodifiable(_raw);
  String rawValue(String key) => _raw[key] ?? '';

  // ── Helpers ────────────────────────────────────────────────────────────────
  int _int(String k, int d) => int.tryParse(_raw[k] ?? '') ?? d;
  bool _bool(String k, bool d) =>
      _raw[k] == null ? d : _raw[k]!.toLowerCase() == 'true';
  String _str(String k, String d) => _raw[k]?.isNotEmpty == true ? _raw[k]! : d;
  Color _color(String k, Color d) {
    final v = _raw[k];
    if (v == null || v.isEmpty) return d;
    try {
      final hex = v.replaceAll('#', '');
      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) {
      return d;
    }
  }

  /// Returns a new AppConfig with a single key overridden (for optimistic UI).
  AppConfig copyWith(String key, String value) =>
      AppConfig({..._raw, key: value});
}
