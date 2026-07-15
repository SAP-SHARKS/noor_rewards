import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/dhikr_screen.dart';
import '../screens/quran_screen.dart';
import '../screens/impact_report_screen.dart';
import 'push_notification_builder.dart';

/// Top-level entrypoint that Firebase invokes in a *separate* isolate
/// when a data-only FCM message arrives while the app is killed or in
/// deep background. Isolates don't share memory, so we must re-init
/// Firebase before touching the plugin. Marked `vm:entry-point` so
/// Dart's release-mode tree-shaker keeps the symbol.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized in this isolate — ignore.
  }
  await PushNotificationBuilder.show(message);
}

/// Global navigator key — pass to [MaterialApp.navigatorKey] in main.dart.
/// Used to push routes from FCM tap handlers outside the widget tree.
final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();

/// Pending deep-link route from a notification tap. Set when the FCM tap
/// arrives before the navigator is ready (cold start through splash + auth).
/// The dashboard listens to this on mount and consumes the value by calling
/// [consumePendingDeepLinkRoute] — only THEN do we navigate, so the route
/// can't be discarded by the splash → auth → dashboard stack replacement
/// that happens during boot.
final ValueNotifier<String?> pendingDeepLinkRoute =
    ValueNotifier<String?>(null);

/// Pull the pending route, returning it once and clearing it so the same
/// notification tap doesn't deep-link twice (e.g. if the dashboard rebuilds
/// after coming back from another screen).
String? consumePendingDeepLinkRoute() {
  final r = pendingDeepLinkRoute.value;
  pendingDeepLinkRoute.value = null;
  return r;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Cached position from the boot-time location request. Reused by
  /// [_saveTokenWithLocation] so a second permission/location fetch isn't
  /// needed when the user signs in.
  Position? _cachedPosition;

  // ── Public entry point ──────────────────────────────────────────────────────
  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // ── 0. Android notification channel ──────────────────────────────────────
    // FCM messages on Android 8+ require a channel. The channel id MUST match
    // `default_notification_channel_id` in AndroidManifest.xml — without that
    // pairing, Android routes incoming pushes to an invisible system channel
    // and they never appear on the user's lock screen / notification tray.
    const androidChannel = AndroidNotificationChannel(
      'sabiq_default_channel',
      'Sabiq Rewards Notifications',
      description:
          'Quran reading reminders, dhikr streaks, rewards, and milestones.',
      importance: Importance.high,
      playSound: true,
    );
    final localPlugin = FlutterLocalNotificationsPlugin();
    await localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // ── 1. Notification permission ───────────────────────────────────────────
    // First prompt the user sees on fresh install. The OS only shows this
    // dialog once per install regardless of how often we call it.
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // iOS: show banner/sound when a push arrives while the app is in the
    // foreground. Without this iOS silently delivers the message to handlers
    // only and the user sees nothing. No-op on Android.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // iOS: FCM tokens require an APNs token to be ready. On a fresh install
    // getToken() can return null if APNs hasn't registered yet, so wait
    // briefly for APNs first.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apns = await messaging.getAPNSToken();
      debugPrint('APNS_TOKEN: $apns');
    }

    // ── 2. Location permission ───────────────────────────────────────────────
    // Requested immediately after notification so both prompts appear
    // back-to-back on fresh install, regardless of whether the user is signed
    // in yet. Previously this only ran inside _saveTokenWithLocation (gated
    // on sign-in) which meant fresh-install users never saw the location
    // prompt until a later launch — feeling random/inconsistent.
    try {
      _cachedPosition = await _getLocation();
    } catch (_) {
      _cachedPosition = null;
    }

    // ── 3. FCM token + initial Supabase persistence ──────────────────────────
    final token = await messaging.getToken();
    debugPrint('FCM_TOKEN: $token');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (token != null && userId != null) {
      await _saveTokenWithLocation(token: token, userId: userId);
    }

    // Re-save on token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await _saveTokenWithLocation(token: newToken, userId: uid);
      }
    });

    // ── 4. Save the token when the user signs in ─────────────────────────────
    // Fresh-install flow: notification + location prompts fire during boot,
    // then the user goes through onboarding and signs in. We need to push the
    // FCM token to Supabase at that point — without this, the token grabbed
    // pre-sign-in is never persisted, and the user receives no FCM messages.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if ((data.event == AuthChangeEvent.signedIn ||
              data.event == AuthChangeEvent.userUpdated) &&
          session != null) {
        final t = await messaging.getToken();
        if (t != null) {
          await _saveTokenWithLocation(token: t, userId: session.user.id);
        }
      }
    });

    // onMessage / onBackgroundMessage intentionally NOT registered. When
    // an FCM push arrives with a top-level `notification` block, Android
    // auto-displays it — which is what makes MIUI render the app icon at
    // its large "native" size. Intercepting via flutter_local_notifications
    // would force the compact/small-icon rendering the user rejected.
    // Kept commented rather than deleted so the dynamic-icon path can be
    // re-enabled quickly if MIUI's rendering assumptions change:
    //   FirebaseMessaging.onMessage.listen(PushNotificationBuilder.show);
    //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // ── Deep-link handling ────────────────────────────────────────────────────
    // Cold start (app was killed). Stash the route in the pending notifier
    // immediately — the dashboard consumes it once it's mounted, which
    // survives the splash → auth → dashboard navigator-stack replacement.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Background → foreground
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  }

  /// Push just the active locale to `fcm_tokens.app_locale` for the
  /// signed-in user so subsequent server pushes look up the correct
  /// language variant. Call this whenever the user changes language in
  /// settings — the token itself is unchanged, only `app_locale`.
  ///
  /// Silent no-op when nothing is signed in — the row won't exist yet
  /// and the initial `_saveTokenWithLocation` will pick up the current
  /// locale on the very first insert.
  Future<void> syncAppLocale(String? code) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final normalised = _normaliseLocale(code) ?? _currentEffectiveLocale();
    try {
      await Supabase.instance.client
          .from('fcm_tokens')
          .update({
            'app_locale': normalised,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('syncAppLocale failed: $e');
    }
  }

  /// Whatever language the app is speaking to the user *right now* —
  /// preferring the LocaleService reading (which reflects both the
  /// user's explicit override and the resolved MaterialApp locale),
  /// falling back to the OS locale, and finally 'en'.
  String _currentEffectiveLocale() {
    // Deliberately avoid a hard import of LocaleService/SettingsService
    // in this callsite so background isolates that only get
    // NotificationService still compile — the effective locale is a
    // nice-to-have there, not a correctness dependency.
    try {
      final name = _readAmbientLocaleName();
      final norm = _normaliseLocale(name);
      if (norm != null) return norm;
    } catch (_) {}
    final platform =
        _normaliseLocale(WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag());
    return platform ?? 'en';
  }

  /// Reads LocaleService.instance.l?.localeName via dynamic access so
  /// this file doesn't take a hard dependency (see comment above).
  String? _readAmbientLocaleName() {
    try {
      // ignore: avoid_dynamic_calls
      final dyn = _localeServiceInstance;
      if (dyn == null) return null;
      final l = dyn.l;
      if (l == null) return null;
      return l.localeName as String?;
    } catch (_) {
      return null;
    }
  }

  // Set once by NotificationServiceBootstrap.setLocaleAccessor in main.dart
  // (see `syncAppLocale` — kept optional so tests don't need to wire it).
  static dynamic _localeServiceInstance;
  static void setLocaleAccessor(dynamic svc) {
    _localeServiceInstance = svc;
  }

  /// Canonicalise "en_US" / "ur-PK" / "ur" → "ur" (language subtag).
  String? _normaliseLocale(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    final head = trimmed.split(RegExp(r'[_-]')).first.toLowerCase();
    if (head.length != 2) return null;
    return head;
  }

  // ── GPS + timezone detection ────────────────────────────────────────────────
  Future<void> _saveTokenWithLocation({
    required String token,
    required String userId,
  }) async {
    // Attempt GPS → precise IANA timezone first, system tz as fallback.
    // Reuse the position cached during initialize() so the sign-in flow
    // doesn't re-prompt for location or stall on a second GPS read.
    String timezone = 'UTC';
    double? latitude;
    double? longitude;

    try {
      final pos = _cachedPosition ?? await _getLocation();
      _cachedPosition ??= pos;
      if (pos != null) {
        latitude = pos.latitude;
        longitude = pos.longitude;
        timezone =
            await _timezoneFromCoords(pos.latitude, pos.longitude) ??
            await _systemTimezone();
        debugPrint('📍 GPS timezone: $timezone ($latitude, $longitude)');
      } else {
        timezone = await _systemTimezone();
        debugPrint('📍 System timezone fallback: $timezone');
      }
    } catch (e) {
      timezone = await _systemTimezone();
      debugPrint('📍 Location error ($e), using system timezone: $timezone');
    }

    // Effective locale for server-side variant lookup. The row's
    // `app_locale` column defaults to 'en' at INSERT time — without this
    // upsert setting the real value on every token save, users who ran
    // through onboarding on Urdu / Arabic / Bahasa keep receiving English
    // push copy even though the in-app UI is fully localised.
    final effectiveLocale = _currentEffectiveLocale();

    try {
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'timezone': timezone,
        'latitude': latitude,
        'longitude': longitude,
        'device_type':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'last_seen': DateTime.now().toUtc().toIso8601String(),
        'app_locale': effectiveLocale,
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Requests location permission and returns current position.
  /// Returns null if denied or unavailable.
  Future<Position?> _getLocation() async {
    // Check if location services are enabled at OS level
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('📍 Location services disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // This triggers the Android system permission dialog
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('📍 Location permission denied');
      return null;
    }

    // Get a low-accuracy position quickly (good enough for timezone)
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Calls timeapi.io (free, no API key) to get IANA timezone from coordinates.
  Future<String?> _timezoneFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://timeapi.io/api/timezone/coordinate?latitude=$lat&longitude=$lng',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final tz = data['timeZone'] as String?;
        return (tz != null && tz.isNotEmpty) ? tz : null;
      }
    } catch (e) {
      debugPrint('timeapi.io error: $e');
    }
    return null;
  }

  /// Reads device system timezone (accurate when "auto timezone" is on).
  Future<String> _systemTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } catch (_) {
      return 'UTC';
    }
  }

  // ── Notification tap → deep link ────────────────────────────────────────────
  void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    final nid = message.data['nid'] as String?;
    debugPrint('FCM tap, route: $route, nid: $nid');

    // Log the open. Fire-and-forget; auth + RLS guarantee the row only
    // updates for the signed-in user. Wrapped in try/catch so a logging
    // failure never blocks the navigation below.
    if (nid != null && nid.isNotEmpty) {
      Supabase.instance.client
          .rpc('mark_notification_opened', params: {'p_nid': nid})
          .then((_) {}, onError: (e) {
        debugPrint('mark_notification_opened failed: $e');
      });
    }

    handleDeepLinkRoute(route);
  }

  /// Dispatcher for taps that come through `flutter_local_notifications`
  /// (LocalReminderScheduler AND any push we surfaced ourselves via
  /// [PushNotificationBuilder]). Handles both payload shapes:
  ///
  ///   • Raw route string (legacy — LocalReminderScheduler set
  ///     `payload: route` directly, e.g. "morning").
  ///   • JSON `{"route": "...", "nid": "..."}` (new — set by
  ///     PushNotificationBuilder so the tap can also fire the
  ///     `mark_notification_opened` RPC that used to run inside
  ///     [_handleMessageTap] when FCM auto-displayed the notification).
  ///
  /// FCM's own `onMessageOpenedApp` / `getInitialMessage` still route
  /// through [_handleMessageTap] for the legacy code path (Edge
  /// Functions that haven't been migrated to data-only yet).
  static void handleTapPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      handleDeepLinkRoute(null);
      return;
    }
    // JSON shape from PushNotificationBuilder.
    if (payload.startsWith('{')) {
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        final nid = map['nid'] as String?;
        final route = map['route'] as String?;
        if (nid != null && nid.isNotEmpty) {
          Supabase.instance.client
              .rpc('mark_notification_opened', params: {'p_nid': nid})
              .then((_) {}, onError: (e) {
            debugPrint('mark_notification_opened failed: $e');
          });
        }
        handleDeepLinkRoute(route);
        return;
      } catch (_) {
        // Fall through to legacy raw-route handling below.
      }
    }
    handleDeepLinkRoute(payload);
  }

  /// Shared entry point for both FCM and local-notification taps.
  ///
  /// Stashes the route in [pendingDeepLinkRoute] so the dashboard can
  /// consume it after mounting (survives cold-start splash → auth →
  /// dashboard navigator-stack replacement), and best-effort direct-
  /// pushes when the navigator is already live (warm-tap case).
  static void handleDeepLinkRoute(String? route) {
    if (route == null || route.isEmpty) {
      pendingDeepLinkRoute.value = null;
      return;
    }

    pendingDeepLinkRoute.value = route;

    final nav = notificationNavigatorKey.currentState;
    if (nav == null) return; // cold start — dashboard mount will handle it.

    final screen = _screenForRoute(route);
    if (screen != null) {
      nav.push(MaterialPageRoute(builder: (_) => screen));
    }
    // Consume — direct push done (or unmapped route, which we don't
    // want the dashboard consumer to trigger on again).
    pendingDeepLinkRoute.value = null;
  }

  /// Route string → target screen. Returns null for `home` / unknown,
  /// which foreground the app to the dashboard (no push needed).
  ///
  /// Supported values (mirror the `route` column on `notification_variants`
  /// and the `payload` field on LocalReminderScheduler):
  ///   morning / evening / sleeping — DhikrScreen at that category
  ///   dhikr                        — DhikrScreen (general)
  ///   quran                        — QuranScreen
  ///   cause                        — ImpactReportScreen (donate hub)
  ///   home / (anything else)       — no-op → just brings app forward
  static Widget? _screenForRoute(String route) {
    switch (route) {
      case 'morning':
        return const DhikrScreen(initialCategory: 'morning');
      case 'evening':
        return const DhikrScreen(initialCategory: 'evening');
      case 'sleeping':
        return const DhikrScreen(initialCategory: 'sleeping');
      case 'dhikr':
        return const DhikrScreen();
      case 'quran':
        return const QuranScreen();
      case 'cause':
        return const ImpactReportScreen();
      case 'home':
      default:
        return null;
    }
  }
}
