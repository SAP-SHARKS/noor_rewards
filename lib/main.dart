import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/qf_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_config.dart';
import 'screens/onboarding_v2/phase1_flow.dart';
import 'screens/onboarding_v2/phase2_flow.dart';
import 'screens/start_journey_screen.dart';
import 'screens/welcome_gate_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/flower_splash_screen.dart';
import 'services/settings_service.dart';
import 'services/live_notification_service.dart';
import 'services/quran_api_config.dart'; // Quran Foundation credentials
import 'services/quran_api_service.dart';
import 'services/notification_service.dart';
import 'services/notification_center.dart';
import 'services/onboarding_assets_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'widgets/noor_offline.dart';
import 'utils/asset_helper.dart';

import 'core/env/env.dart';
import 'theme/y4_theme.dart';
import 'services/profile_name_notifier.dart';

/// Pre-parsed Lottie composition — loaded in [main] before [runApp] so the
/// splash screen can start animating on the very first Flutter frame.
LottieComposition? flowerComposition;

/// Signals when all heavy boot-time services have finished initializing.
/// The AuthGate waits on this before navigating to a real screen — the
/// FlowerSplashScreen plays in front of it for the entire init window.
final ValueNotifier<bool> appInitReady = ValueNotifier(false);

/// Captures any boot-time error so we can surface it instead of a blank screen.
String? bootError;

Future<void> main() async {
  // ── Stage 1: bare minimum BEFORE runApp — keeps gap to first paint near-zero
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    // In-app notification inbox — small, fast, must be ready before any
    // service tries to enqueue a notification.
    await NotificationCenter.instance.init();

    try {
      final bytes = await rootBundle.load('assets/lottie/Flower.json');
      flowerComposition = await LottieComposition.fromByteData(bytes);
    } catch (_) {} // silent — FlowerSplashScreen has its own async fallback
  } catch (e, stack) {
    bootError = '$e\n$stack';
  }
  // ── runApp() FIRST — flower splash starts drawing immediately. ──────────────
  runApp(
    ChangeNotifierProvider<SettingsService>.value(
      value: SettingsService.instance,
      child: const MyApp(),
    ),
  );

  // ── Stage 2: heavy init runs in parallel WHILE the splash plays ─────────────
  unawaited(_bootHeavyInit());
}

/// Wrap a step so one failing/slow service can't block the whole boot.
/// Each step has its own timeout. Failures are logged but don't propagate.
Future<void> _step(
  String name,
  Future<void> Function() body, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    await body().timeout(timeout);
  } on TimeoutException {
    debugPrint('[boot] $name timed out, continuing without it');
  } catch (e) {
    debugPrint('[boot] $name failed: $e');
  }
}

Future<void> _bootHeavyInit() async {
  // Critical-path: must complete before AuthGate works. Sequential because
  // Supabase depends on Env, NotificationService depends on Supabase, etc.
  await _step('Env', Env.init);
  await _step('Firebase', Firebase.initializeApp);
  await _step(
    'Supabase',
    () => Supabase.initialize(
      url: 'https://fwjzhtcxfiendofnhyzp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3anpodGN4ZmllbmRvZm5oeXpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzkwNDksImV4cCI6MjA4NjkxNTA0OX0.gspfVlCH-S2Cs8_fhOeDWNZN2XH1NC53CJ8riyvJ5nw',
    ),
  );
  // Start onboarding-image warming as early as possible — the moment
  // Supabase is up (it needs Supabase for the URL fetch). Running it here,
  // unawaited and in parallel with the remaining boot steps, gives the
  // image downloads the whole rest of boot + the splash window as a head
  // start, so the onboarding slides are already cached when shown.
  // init() returns fast; the downloads it kicks off continue in the
  // background and never block navigation.
  unawaited(_step('OnboardingAssets', OnboardingAssetsService.instance.init));

  await _step('NotificationService', NotificationService.instance.initialize);
  await _step('QuranApiConfig', QuranApiConfig.load);

  // Mark ready as soon as the critical chain is done — the splash can move on.
  appInitReady.value = true;

  // Non-critical: nice-to-have, fire in background, don't block navigation.
  unawaited(
    _step(
      'SettingsService',
      SettingsService.instance.initialize,
      timeout: const Duration(seconds: 8),
    ),
  );
  unawaited(_step('AssetHelper', AssetHelper.loadAssets));
  unawaited(
    _step('NoorLiveNotification', NoorLiveNotificationService.instance.init),
  );

  try {
    _initAppLinks();
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild theme whenever SettingsService notifies (Realtime color change)
    final cfg = context.watch<SettingsService>().config;
    return MaterialApp(
      title: 'Sabiq',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(cfg),
      locale:
          context.watch<SettingsService>().localeCode != null
              ? Locale(context.watch<SettingsService>().localeCode!)
              : null,
      // Localization — auto-follows device locale if locale is null
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English (default)
        Locale('ar'), // Arabic  — RTL
        Locale('ur'), // Urdu    — RTL
        Locale('tr'), // Turkish
        Locale('ms'), // Malay
        Locale('id'), // Indonesian
        Locale('ru'), // Russian
        Locale('fr'), // French
      ],
      // Caps the textScaler so that device accessibility font-size settings
      // cannot break gamified fixed-height layouts and cause global overflow.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.0,
            ),
            boldText: false,
          ),
          child: child!,
        );
      },
      navigatorKey: notificationNavigatorKey,
      home: const _SplashGate(),
    );
  }

  ThemeData _buildTheme(AppConfig cfg) {
    // Y4 Honey + Sage — single source of truth for the entire app's
    // palette + typography. Admin-overridable colors from AppConfig still
    // win where present; otherwise the Y4 defaults flow through to every
    // Material widget via the ThemeData below.
    final base = Y4.buildTheme();
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        // Honor admin overrides (Supabase app_config) on top of Y4 defaults
        primary: cfg.primaryColor,
        secondary: cfg.secondaryColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Initialises the app_links stream listener.
///
/// Any URI matching noorrewards://oauth2/callback is forwarded to
/// [QfAuthService.handleCallback], completing the pending Completer from
/// [QfAuthService.signIn].
void _initAppLinks() {
  final appLinks = AppLinks();

  // Helper function to handle a referral join URI
  Future<void> handleJoinUri(Uri uri) async {
    final referralCode = uri.queryParameters['ref'];
    if (referralCode != null && referralCode.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_referral_code', referralCode.toUpperCase());
        debugPrint('[AppLinks] Saved pending referral code: $referralCode');
      } catch (e) {
        debugPrint('[AppLinks] Error saving pending referral code: $e');
      }
    }
  }

  // Handle URI if the app was COLD-STARTED
  appLinks.getInitialLinkString().then((link) {
    if (link != null) {
      final uri = Uri.tryParse(link);
      if (uri != null) {
        if (_isQfCallback(uri)) {
          QfAuthService.instance.handleCallback(uri);
        } else if (_isJoinCallback(uri)) {
          handleJoinUri(uri);
        }
      }
    }
  });

  // Handle URIs while the app is already running (warm start / foreground)
  appLinks.uriLinkStream.listen((uri) {
    if (_isQfCallback(uri)) {
      QfAuthService.instance.handleCallback(uri);
    } else if (_isJoinCallback(uri)) {
      handleJoinUri(uri);
    }
  });
}

bool _isQfCallback(Uri uri) =>
    uri.scheme == 'noorrewards' && uri.host == 'oauth2';

bool _isJoinCallback(Uri uri) =>
    (uri.scheme == 'noorrewards' && uri.host == 'join') ||
    (uri.scheme == 'https' && uri.host == 'sabiq-rewards.vercel.app' && uri.path == '/join');

// ─────────────────────────────────────────────────────────────────────────────
/// Shows the flower Lottie splash, then hands off to [AuthGate] only when
/// BOTH conditions are met:
///  1. The Lottie animation has finished playing.
///  2. All heavy boot-time services in [_bootHeavyInit] have completed.
///
/// If init finishes before the animation, we navigate when the animation ends.
/// If the animation finishes before init (e.g. on a slow network for Supabase
/// realtime), we keep the flower's last frame visible and navigate the moment
/// init signals ready.
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _lottieDone = false;
  bool _navigated = false;
  Timer? _hardTimeout;

  /// Absolute maximum the splash can stay on screen. If [appInitReady] hasn't
  /// flipped to `true` by then, navigate anyway — services that aren't ready
  /// will lazily initialise / show offline UI on the destination screen.
  static const _maxSplashDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    appInitReady.addListener(_maybeNavigate);
    // Hard timeout — guarantees we never get stuck on the splash even if a
    // background service hangs (e.g. Supabase realtime, Firebase, Settings
    // remote-config fetch on a slow / offline network).
    _hardTimeout = Timer(_maxSplashDuration, _forceNavigate);
  }

  @override
  void dispose() {
    _hardTimeout?.cancel();
    appInitReady.removeListener(_maybeNavigate);
    super.dispose();
  }

  void _forceNavigate() {
    if (_navigated || !mounted) return;
    debugPrint(
      '[SplashGate] hard timeout reached, navigating to AuthGate '
      '(lottieDone=$_lottieDone, initReady=${appInitReady.value})',
    );
    _go();
  }

  void _maybeNavigate() {
    if (_navigated || !mounted) return;
    if (_lottieDone && appInitReady.value) _go();
  }

  void _go() {
    _navigated = true;
    _hardTimeout?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder:
            (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlowerSplashScreen(
      onComplete: () {
        _lottieDone = true;
        _maybeNavigate();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _onboardingDone = false;
  bool _profileSetupDone = false;
  bool _welcomeShown = false;
  String _userName = '';
  String? _lastUserId; // tracks which user these local flags belong to
  // Per-user once-per-session guard for the dedup RPC. Without this we'd
  // hit the network on every StreamBuilder rebuild.
  final Set<String> _dedupedUserIds = <String>{};

  /// Calls `dedupe_profile_on_login` so any older profile that shares the
  /// caller's email (from a different auth method) is merged INTO the
  /// current session. Fire-and-forget; the merge happens server-side and
  /// the next profile read will reflect the absorbed data.
  void _maybeDedupeProfile(User? user) {
    if (user == null) return;
    final email = (user.email ??
            user.userMetadata?['qf_email'] as String? ??
            user.userMetadata?['email'] as String? ??
            '')
        .trim();
    if (email.isEmpty) return;
    if (_dedupedUserIds.contains(user.id)) return;
    _dedupedUserIds.add(user.id);
    Supabase.instance.client
        .rpc('dedupe_profile_on_login', params: {'p_email': email})
        .catchError((e) {
      debugPrint('[AuthGate] dedupe_profile_on_login failed: $e');
      // Allow a retry on next rebuild if it actually failed
      _dedupedUserIds.remove(user.id);
    });
  }

  @override
  void initState() {
    super.initState();
    // Restore the persisted QF signed-out flag from secure storage.
    QfAuthService.instance.init();
    // If the user already has a live QF session at app start, reconcile
    // bookmarks both ways in the background. Catches the case where the
    // user added a bookmark on quran.com while the app was closed.
    _syncQfBookmarksIfLinked();
  }

  Future<void> _syncQfBookmarksIfLinked() async {
    try {
      if (await QuranApiService.instance.isUserLoggedIn()) {
        // Fire-and-forget — sync runs in the background, never blocks UI.
        QuranApiService.instance.syncBookmarks();
      }
    } catch (_) {
      // Never let bookmark sync crash app startup.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Outer builder: show _AuthLoading for the entire QF token-exchange window.
    return ValueListenableBuilder<bool>(
      valueListenable: QfAuthService.instance.loginInProgress,
      builder: (context, qfLoggingIn, _) {
        if (qfLoggingIn) return const _AuthLoading();

        // Inner builder: treat QF user as logged-out when they tapped Sign Out,
        // even though the Supabase anonymous session is kept alive.
        return ValueListenableBuilder<bool>(
          valueListenable: QfAuthService.instance.isQfSignedOut,
          builder: (context, qfSignedOut, _) {
            return _buildAuthStream(qfSignedOut);
          },
        );
      },
    );
  }

  Widget _buildAuthStream(bool qfSignedOut) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.hasData
                ? snapshot.data!.session
                : Supabase.instance.client.auth.currentSession;

        // QF users who explicitly signed out should see the login screen even
        // though their Supabase session is still alive.  But only gate QF users—
        // a Google user signing in while this flag is set must not be blocked.
        final isCurrentUserQf =
            Supabase
                .instance
                .client
                .auth
                .currentUser
                ?.userMetadata?['provider'] ==
            'quran_com';
        final showLogin = (qfSignedOut && isCurrentUserQf) || session == null;

        // Auto-clear a stale QF sign-out flag when a non-QF user is active,
        // so it doesn't accidentally block a future re-login check.
        if (qfSignedOut && !isCurrentUserQf && session != null) {
          QfAuthService.instance.isQfSignedOut.value = false;
          // SecureStorage will be properly cleared the next time a QF user signs in.
        }

        if (showLogin) {
          if (!_onboardingDone) {
            return Phase1Flow(
              onComplete: () => setState(() => _onboardingDone = true),
            );
          }
          return StartJourneyScreen(
            onBack: () => setState(() => _onboardingDone = false),
          );
        }

        // Session verified but stream hasn't emitted full metadata yet—
        // show loading to prevent any screen from flashing.
        if (!snapshot.hasData) return const _AuthLoading();

        final user = Supabase.instance.client.auth.currentUser;

        // ── Reset local flags when the signed-in user changes ────────────────
        // _profileSetupDone and _userName belong to a specific user session.
        // If the user ID changes (e.g. User B logs in after User A), we must
        // clear them so User B is never treated as already having completed
        // setup, and User A's name is never shown to User B.
        if (user?.id != _lastUserId) {
          _lastUserId = user?.id;
          _profileSetupDone = false;
          _userName = '';
          _welcomeShown = false;
          // Drop the previous user's override so it can't leak to the new user.
          ProfileNameNotifier.instance.clear();
        }

        // Cross-auth-method profile dedup. Runs once per user per session.
        // If this auth.uid() is fresh but the email matches an older
        // profile (Google→QF, QF→Google, etc.), the older profile's data
        // is merged INTO this session's profile server-side.
        _maybeDedupeProfile(user);

        final noorSetupDone =
            user?.userMetadata?['noor_setup_complete'] == true;
        final hasProfile = noorSetupDone || _profileSetupDone;
        final storedName = user?.userMetadata?['noor_name'] as String?;

        if (!hasProfile) {
          // Pre-fill with whatever name the auth provider gave us, if any.
          final providerName =
              (user?.userMetadata?['full_name'] as String?) ??
              (user?.userMetadata?['noor_name'] as String?) ??
              '';
          return Phase2Flow(
            initialName: providerName,
            onComplete: (name) {
              final isQfUser = user?.userMetadata?['provider'] == 'quran_com';
              if (isQfUser) {
                QfAuthService.instance.storeQfName(name);
              }
              // Persist email + display name to profiles table for all login
              // methods so they're always visible in the Supabase dashboard.
              final userEmail =
                  user
                      ?.email // email/Google
                      ??
                  user?.userMetadata?['qf_email'] as String?; // QF
              if (user != null) {
                // Direct upserts on `profiles` are revoked from authenticated;
                // use the safe RPC instead (auth.uid() check + allow-listed
                // columns inside the function).
                final params = <String, dynamic>{
                  'p_display_name': name,
                  'p_setup_done': true,
                };
                if (userEmail != null && userEmail.isNotEmpty) {
                  params['p_email'] = userEmail;
                }
                Supabase.instance.client
                    .rpc('upsert_my_profile_bootstrap', params: params)
                    .catchError(
                      (e) => debugPrint('[AuthGate] profile bootstrap failed: $e'),
                    );
              }
              // Mirror to auth metadata so future cold starts skip Phase 2.
              unawaited(
                Supabase.instance.client.auth
                    .updateUser(
                      UserAttributes(
                        data: {
                          'noor_setup_complete': true,
                          'noor_name': name,
                        },
                      ),
                    )
                    .then<void>((_) {})
                    .catchError(
                      (e) => debugPrint(
                        '[AuthGate] metadata update failed: $e',
                      ),
                    ),
              );
              setState(() {
                _userName = name;
                _profileSetupDone = true;

                _welcomeShown = false;
              });
            },
          );
        }

        final googleName = user?.userMetadata?['full_name'] as String?;
        // Highest-priority source for the user-facing display name is the
        // ProfileNameNotifier — settings_screen pushes the freshly saved
        // name into it the instant the RPC succeeds, so this guarantees
        // propagation even if the auth stream's userUpdated event is
        // missed. Falls back to auth metadata, then local cached name,
        // then OAuth provider name, then 'Friend'.
        return ValueListenableBuilder<String?>(
          valueListenable: ProfileNameNotifier.instance.name,
          builder: (context, overrideName, _) {
            final override = overrideName?.trim();
            final freshStoredName = storedName?.trim();
            final displayName = (override != null && override.isNotEmpty)
                ? override
                : (freshStoredName != null && freshStoredName.isNotEmpty)
                    ? freshStoredName
                    : (_userName.isNotEmpty
                        ? _userName
                        : (googleName ?? 'Friend'));

            if (_profileSetupDone && !_welcomeShown) {
              return WelcomeGateScreen(
                name: displayName,
                onComplete: () => setState(() => _welcomeShown = true),
              );
            }

            return DashboardScreen(name: displayName);
          },
        );
      },
    );
  }
}

/// A minimal full-screen loader shown for the brief window (<200 ms) between
/// app startup and the first Supabase auth stream event. Prevents any
/// intermediate screen (e.g. ProfileSetupScreen) from flashing for users
/// who are already registered.
class _AuthLoading extends StatelessWidget {
  const _AuthLoading();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Y4.bg,
      body: Center(child: NoorInlineLoader(height: 80)),
    );
  }
}
