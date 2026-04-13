// lib/models/app_config.dart
// Strongly-typed wrapper around the raw app_config key-value table.
// Defaults match the seeded Supabase values; safe to call before first fetch.

import 'package:flutter/material.dart';

class AppConfig {
  final Map<String, String> _raw;
  const AppConfig(this._raw);
  factory AppConfig.empty() => const AppConfig({});

  // ── Economy ────────────────────────────────────────────────────────────────
  int get coinsPerAyah        => _int('coins_per_ayah',         10);
  int get coinsPerDhikr       => _int('coins_per_dhikr',        20);
  int get coinsPerTafsir10min => _int('coins_per_tafsir_10min', 50);
  int get coinsPerDua         => _int('coins_per_dua',          15);
  int get xpPerAyah           => _int('xp_per_ayah',             5);
  int get xpPerDhikr          => _int('xp_per_dhikr',           10);
  int get xpPerTafsir10min    => _int('xp_per_tafsir_10min',    15);
  int get xpDailyLogin        => _int('xp_daily_login',          5);
  int get xpValidateCoins     => _int('xp_validate_coins',      20);
  int get dailyFreeCap        => _int('daily_free_cap',        500);
  int get weeklyXpCap         => _int('weekly_xp_cap',        2000);

  // ── Theme — Global ─────────────────────────────────────────────────────────
  Color get primaryColor    => _color('primary_color',    const Color(0xFF2BAE99));
  Color get secondaryColor  => _color('secondary_color',  const Color(0xFF6B4EBB));
  Color get donationColor   => _color('donation_color',   const Color(0xFFF5A623));

  // ── Theme — Dashboard ─────────────────────────────────────────────────────
  Color get dashBg          => _color('dash_bg',          const Color(0xFFF7F3EE));
  Color get dashText        => _color('dash_text',        const Color(0xFF1C1C1E));
  Color get dashTeal        => _color('dash_teal',        const Color(0xFF2BAE99));

  // ── Theme — Azkar/Dhikr ───────────────────────────────────────────────────
  Color get azkarAccent         => _color('azkar_accent',          const Color(0xFF0D9488));
  Color get azkarMorningGrad1   => _color('azkar_morning_grad1',   const Color(0xFF0C4A3E));
  Color get azkarMorningGrad2   => _color('azkar_morning_grad2',   const Color(0xFF0D9488));
  Color get azkarEveningGrad1   => _color('azkar_evening_grad1',   const Color(0xFF1E1B4B));
  Color get azkarEveningGrad2   => _color('azkar_evening_grad2',   const Color(0xFF4338CA));
  Color get azkarBottomGrad1    => _color('azkar_bottom_grad1',    const Color(0xFF0A6B52));
  Color get azkarBottomGrad2    => _color('azkar_bottom_grad2',    const Color(0xFF0C4A3E));
  Color get azkarHighlight      => _color('azkar_highlight',       const Color(0xFF1A7A5C));

  // ── Theme — Quran ─────────────────────────────────────────────────────────
  Color get quranBg         => _color('quran_bg',         const Color(0xFFEDF7F4));
  Color get quranAccent     => _color('quran_accent',     const Color(0xFF2BAE99));
  Color get quranGold       => _color('quran_gold',       const Color(0xFFFFAA00));
  Color get quranTextColor  => _color('quran_text',       const Color(0xFF1C1C1E));

  // ── Feature Flags ──────────────────────────────────────────────────────────
  bool get featureLeaderboard => _bool('feature_leaderboard', true);
  bool get featureChallenges  => _bool('feature_challenges',  true);
  bool get featureBadges      => _bool('feature_badges',      true);
  bool get featureTafsir      => _bool('feature_tafsir',      true);
  bool get featureInvite      => _bool('feature_invite',      false);

  // ── Limits ─────────────────────────────────────────────────────────────────
  String get minAppVersionIos     => _str('min_app_version_ios',     '1.0.0');
  String get minAppVersionAndroid => _str('min_app_version_android', '1.0.0');
  bool   get maintenanceMode      => _bool('maintenance_mode',       false);
  int    get maxBookmarks         => _int('max_bookmarks',           200);

  // ── Messages / Banners ─────────────────────────────────────────────────────
  String get bannerText    => _str('banner_text',    '');
  Color  get bannerColor   => _color('banner_color', const Color(0xFF2BAE99));
  bool   get bannerEnabled => _bool('banner_enabled', false);
  String get supportEmail  => _str('support_email',  'support@noorrewards.com');
  String get appStoreUrl   => _str('app_store_url',  '');
  String get playStoreUrl  => _str('play_store_url', '');

  // ── Raw access (for admin panel dynamic rows) ──────────────────────────────
  Map<String, String> get raw => Map.unmodifiable(_raw);
  String rawValue(String key) => _raw[key] ?? '';

  // ── Helpers ────────────────────────────────────────────────────────────────
  int    _int  (String k, int    d) => int.tryParse(_raw[k] ?? '') ?? d;
  bool   _bool (String k, bool   d) => _raw[k] == null ? d : _raw[k]!.toLowerCase() == 'true';
  String _str  (String k, String d) => _raw[k]?.isNotEmpty == true ? _raw[k]! : d;
  Color  _color(String k, Color  d) {
    final v = _raw[k];
    if (v == null || v.isEmpty) return d;
    try {
      final hex = v.replaceAll('#', '');
      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) { return d; }
  }

  /// Returns a new AppConfig with a single key overridden (for optimistic UI).
  AppConfig copyWith(String key, String value) =>
      AppConfig({..._raw, key: value});
}
