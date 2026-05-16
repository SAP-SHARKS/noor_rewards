import '../models/app_config.dart';
import '../services/settings_service.dart';

/// Page / tab visibility — controlled remotely from the admin panel.
///
/// Each flag reads a key from the `app_config` table via [SettingsService],
/// which loads the config at startup and refreshes live over Supabase
/// Realtime. Toggling a flag on the admin "Features" page hides/shows that
/// page for all users with no app rebuild.
///
/// To make a new page hideable: add a getter here backed by a new
/// `feature_*` key, gate the page's tab/entry point on it (see how the
/// dashboard nav and the Level screen use these), and add the key to the
/// admin Features page's `FEATURE_FLAGS` list.
class FeatureFlags {
  FeatureFlags._();

  static AppConfig get _cfg => SettingsService.instance.config;

  // ── Bottom-navigation tabs ────────────────────────────────────────────
  // Home is always shown — it is the app's root tab and cannot be hidden.
  static bool get causeTab => _cfg.featureCause;
  static bool get journeyTab => _cfg.featureJourney;
  static bool get akhirahTab => _cfg.featureAkhirah;

  // ── Inner / sub-tabs ──────────────────────────────────────────────────
  /// The "Challenges" tab inside the Journey (Level) screen.
  static bool get challengesTab => _cfg.featureChallenges;
}
