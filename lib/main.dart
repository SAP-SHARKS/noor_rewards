import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      title: 'NoorRewards',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(cfg),
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
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: cfg.primaryColor,
        secondary: cfg.secondaryColor,
      ),
      useMaterial3: true,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        if (session == null) {
          if (!_onboardingDone) {
            return OnboardingScreen(
              onComplete: () => setState(() => _onboardingDone = true),
            );
          }
          return StartJourneyScreen(
            onBack: () => setState(() => _onboardingDone = false),
          );
        }

        final user = Supabase.instance.client.auth.currentUser;
        final noorSetupDone = user?.userMetadata?['noor_setup_complete'] == true;
        final hasProfile = noorSetupDone || _profileSetupDone;
        final storedName = user?.userMetadata?['noor_name'] as String?;

        if (!hasProfile) {
          return ProfileSetupScreen(
            onComplete: (name) => setState(() {
              _userName = name;
              _profileSetupDone = true;
              _welcomeShown = false;
            }),
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
