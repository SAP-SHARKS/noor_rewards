import '../l10n/app_localizations.dart';

/// Ambient access to the app's current `AppLocalizations` instance,
/// so services / models / notification helpers that don't own a
/// `BuildContext` can still emit localised strings.
///
/// Wiring: the root widget (see `main.dart`'s `MaterialApp.builder`)
/// calls `LocaleService.instance.update(AppLocalizations.of(context))`
/// on every rebuild, so `current` always reflects the locale MaterialApp
/// resolved. This keeps in sync when the user switches language via
/// `SettingsService.localeCode`.
///
/// Call sites use the null-safe helper `l` (nullable) with a bare-string
/// fallback for the pre-first-frame window, mirroring the widget-side
/// convention used throughout the codebase:
///
///     final l = LocaleService.instance.l;
///     final title = l?.streakMilestoneTitle(days) ?? '$days-day streak!';
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  AppLocalizations? _current;
  String? _currentLocaleName;

  /// Optional listener fired ONLY when the resolved locale changes (not on
  /// every rebuild). Services that render text into channels outside the
  /// widget tree — e.g. NoorLiveNotificationService's persistent tray
  /// notification — subscribe here so their output re-renders when the
  /// user switches language.
  void Function(String localeName)? onLocaleChanged;

  /// Update the ambient localisation. Called from the root widget's
  /// `builder` on every rebuild — cheap identity check keeps this a no-op
  /// when the locale hasn't changed.
  void update(AppLocalizations? next) {
    if (identical(_current, next)) return;
    _current = next;
    final name = next?.localeName;
    if (name != null && name != _currentLocaleName) {
      _currentLocaleName = name;
      onLocaleChanged?.call(name);
    }
  }

  /// The most recently resolved `AppLocalizations`. Null only before the
  /// first frame (during service constructors that fire from `main()` /
  /// notification handlers that fire before `MaterialApp` builds).
  AppLocalizations? get l => _current;
}
