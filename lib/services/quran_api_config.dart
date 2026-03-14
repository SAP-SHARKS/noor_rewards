// lib/services/quran_api_config.dart
//
// Central configuration for the Quran Foundation API.
//
//  isDev = true  →  Pre-production / pre-live environment
//  isDev = false →  Production environment
//
// Keys are loaded from the project-root .env file (excluded from git).
// Call QuranApiConfig.load() once in main() before using any getters.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class QuranApiConfig {
  QuranApiConfig._(); // static-only class

  // ── Dev toggle ──────────────────────────────────────────────────────────────
  /// Set to [true] during development/testing (uses pre-live credentials).
  /// Flip to [false] before releasing to production.
  static bool isDev = true;

  // ── Load .env ───────────────────────────────────────────────────────────────
  /// Must be called once in main() before runApp():
  ///   await QuranApiConfig.load();
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    // Override isDev from .env if the key is present
    final envFlag = dotenv.maybeGet('IS_DEV');
    if (envFlag != null) isDev = envFlag.trim().toLowerCase() == 'true';
  }

  // ── Credentials ─────────────────────────────────────────────────────────────
  static String get clientId => isDev
      ? _require('QURAN_PRELIVE_CLIENT_ID')
      : _require('QURAN_PROD_CLIENT_ID');

  static String get clientSecret => isDev
      ? _require('QURAN_PRELIVE_CLIENT_SECRET')
      : _require('QURAN_PROD_CLIENT_SECRET');

  // ── Base URLs ───────────────────────────────────────────────────────────────
  /// Quran Foundation public API (used for page-fetch and word-by-word).
  /// The authenticated endpoints use the same host with a Bearer token.
  static const String apiBase = 'https://api.quran.com/api/v4';

  /// OAuth2 token endpoint — confirmed from Quran Foundation docs.
  static const String tokenEndpoint =
      'https://api.quran.com/oauth2/token';

  // ── Helper ──────────────────────────────────────────────────────────────────
  static String _require(String key) {
    final val = dotenv.maybeGet(key);
    if (val == null || val.isEmpty || val.startsWith('your_')) {
      throw StateError(
        '[QuranApiConfig] "$key" is not set in .env. '
        'Paste your Quran Foundation credentials into the project-root .env file.',
      );
    }
    return val;
  }
}
