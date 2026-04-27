import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/qf_auth_service.dart';

import 'models/app_config.dart';
import 'screens/onboarding_screen.dart';
import 'screens/start_journey_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/welcome_gate_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/settings_service.dart';
import 'services/live_notification_service.dart';
import 'services/quran_api_config.dart';       // Quran Foundation credentials
import 'services/notification_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'utils/asset_helper.dart';

import 'core/env/env.dart';
import 'theme/y4_theme.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    
    // Initialize QF environment variables
    await Env.init();
    
    // Initialize Firebase Configuration
    await Firebase.initializeApp();

    await Supabase.initialize(
      url: 'https://fwjzhtcxfiendofnhyzp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3anpodGN4ZmllbmRvZm5oeXpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzkwNDksImV4cCI6MjA4NjkxNTA0OX0.gspfVlCH-S2Cs8_fhOeDWNZN2XH1NC53CJ8riyvJ5nw',
    );

    // Initialize FCM NotificationService (must be after Supabase init)
    await NotificationService.instance.initialize();

    // Load .env — Quran Foundation API credentials (Pre-live or Production)
    await QuranApiConfig.load();

    // Pre-load remote config (waits for first fetch, then subscribes to Realtime)
    await SettingsService.instance.initialize();
    
    // Pre-load all available asset registry to automatically populate custom image cards
    await AssetHelper.loadAssets();

    // Init the live "Noor Today" notification (like Sweatcoin's step counter)
    await NoorLiveNotificationService.instance.init();

    // Wire up app_links to receive OAuth callbacks from the browser.
    // When noorrewards://oauth2/callback arrives, hand it to QfAuthService.
    _initAppLinks();

    runApp(
      ChangeNotifierProvider<SettingsService>.value(
        value: SettingsService.instance,
        child: const MyApp(),
      ),
    );
  } catch (e, stack) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Initialization Error:\n$e\n\n$stack',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild theme whenever SettingsService notifies (Realtime color change)
    final cfg = context.watch<SettingsService>().config;
    return MaterialApp(
      title: 'Noor Rewards',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(cfg),
      // Localization — auto-follows device locale
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),        // English (default)
        Locale('ar'),        // Arabic  — RTL
        Locale('ur'),        // Urdu    — RTL
        Locale('tr'),        // Turkish
        Locale('ms'),        // Malay
        Locale('id'),        // Indonesian
        Locale('ru'),        // Russian
        Locale('fr'),        // French
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
      home: const AuthGate(),
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
        primary:   cfg.primaryColor,
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

  // Handle URI if the app was COLD-STARTED by the OAuth redirect
  appLinks.getInitialLinkString().then((link) {
    if (link != null) {
      final uri = Uri.tryParse(link);
      if (uri != null && _isQfCallback(uri)) {
        QfAuthService.instance.handleCallback(uri);
      }
    }
  });

  // Handle URIs while the app is already running (warm start / foreground)
  appLinks.uriLinkStream.listen((uri) {
    if (_isQfCallback(uri)) {
      QfAuthService.instance.handleCallback(uri);
    }
  });
}

bool _isQfCallback(Uri uri) =>
    uri.scheme == 'noorrewards' && uri.host == 'oauth2';

// ─────────────────────────────────────────────────────────────────────────────
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _onboardingDone   = false;
  bool _profileSetupDone = false;
  bool _welcomeShown     = false;
  String _userName       = '';
  String? _lastUserId;   // tracks which user these local flags belong to

  @override
  void initState() {
    super.initState();
    // Restore the persisted QF signed-out flag from secure storage.
    QfAuthService.instance.init();
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
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        // QF users who explicitly signed out should see the login screen even
        // though their Supabase session is still alive.  But only gate QF users—
        // a Google user signing in while this flag is set must not be blocked.
        final isCurrentUserQf = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['provider'] == 'quran_com';
        final showLogin = (qfSignedOut && isCurrentUserQf) || session == null;

        // Auto-clear a stale QF sign-out flag when a non-QF user is active,
        // so it doesn't accidentally block a future re-login check.
        if (qfSignedOut && !isCurrentUserQf && session != null) {
          QfAuthService.instance.isQfSignedOut.value = false;
          // SecureStorage will be properly cleared the next time a QF user signs in.
        }

        if (showLogin) {
          if (!_onboardingDone) {
            return OnboardingScreen(
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
          _lastUserId        = user?.id;
          _profileSetupDone  = false;
          _userName          = '';
          _welcomeShown      = false;
        }

        final noorSetupDone = user?.userMetadata?['noor_setup_complete'] == true;
        final hasProfile = noorSetupDone || _profileSetupDone;
        final storedName = user?.userMetadata?['noor_name'] as String?;

        if (!hasProfile) {
          return ProfileSetupScreen(
            onComplete: (name) {
              final isQfUser = user?.userMetadata?['provider'] == 'quran_com';
              if (isQfUser) {
                QfAuthService.instance.storeQfName(name);
              }
              // Persist email to profiles table for all login methods so
              // it's always visible in the Supabase dashboard.
              final userEmail = user?.email                               // email/Google
                  ?? user?.userMetadata?['qf_email'] as String?;         // QF
              if (userEmail != null && userEmail.isNotEmpty) {
                Supabase.instance.client.from('profiles').upsert(
                  {'id': user!.id, 'email': userEmail},
                  onConflict: 'id', ignoreDuplicates: false,
                ).catchError((e) => debugPrint('[AuthGate] email upsert failed: $e'));
              }
              setState(() {
                _userName = name;
                _profileSetupDone = true;

                _welcomeShown = false;
              });
            },
          );
        }

        final googleName = user?.userMetadata?['full_name'] as String?;
        final displayName =
            _userName.isNotEmpty ? _userName : (storedName ?? googleName ?? 'Friend');

        if (_profileSetupDone && !_welcomeShown) {
          return WelcomeGateScreen(
            name: displayName,
            onComplete: () => setState(() => _welcomeShown = true),
          );
        }

        return DashboardScreen(name: displayName);
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
      body: Center(
        child: CircularProgressIndicator(
          color: Y4.honeyDeep,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
