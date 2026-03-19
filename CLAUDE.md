# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Noor Rewards is a Flutter mobile app that gamifies Islamic worship activities (Quran reading, dhikr, tafsir) with an XP/coins economy, streaks, levels, and community impact tracking. Backend is Supabase (auth, database, Realtime). The app targets Android, iOS, web, and desktop.

## Build & Dev Commands

```bash
flutter pub get              # Install dependencies
flutter analyze              # Run static analysis (uses flutter_lints)
flutter run                  # Run on connected device/emulator
flutter build apk --debug    # Build debug Android APK
flutter build apk --release  # Build release Android APK
flutter test                 # Run tests (test/ directory exists but is currently empty)
```

**CI**: Push to `qa` branch triggers GitHub Actions debug APK build. iOS TestFlight workflow exists for `ios-testflight.yml`.

**Environment**: Requires `.env` file in project root with Quran Foundation API credentials. Loaded at runtime via `flutter_dotenv` and parsed by `lib/services/quran_api_config.dart`.

**SDK**: Dart SDK `>=3.7.0 <4.0.0`, Flutter stable channel.

## Architecture

### Startup Flow (`lib/main.dart`)
1. Hive local storage init
2. Supabase init (hardcoded project URL + anon key)
3. Load `.env` (Quran API creds)
4. `SettingsService` fetches remote config from `app_config` Supabase table + subscribes to Realtime
5. `AssetHelper.loadAssets()` pre-loads asset registry
6. `NoorLiveNotificationService` init
7. `AuthGate` widget manages auth state → Onboarding → Profile Setup → Welcome → Dashboard

### Key Patterns

- **SettingsService** (`lib/services/settings_service.dart`): Singleton `ChangeNotifier` exposed via Provider. Fetches key-value pairs from Supabase `app_config` table, subscribes to Realtime for live updates. The admin panel can change theme colors, economy values, and feature flags that take effect instantly across all clients.

- **AppConfig** (`lib/models/app_config.dart`): Strongly-typed wrapper over the raw config map. All economy values (coins per ayah, XP per dhikr, daily caps) and theme colors are driven from here with sensible defaults.

- **XP System** (`lib/services/xp_service.dart`): Central XP/level/badge service. Each dhikr type has a weighted XP value in `XpReward._dhikrXpMap`. All XP-earning events must go through this service.

- **Admin access**: Client-side email whitelist in `DashboardScreen` (`_kAdminEmails`) gates access to `AdminDashboard`.

### Directory Layout

- `lib/auth/` — Auth screen (Supabase auth)
- `lib/screens/` — All app screens (dashboard, quran, dhikr, tafsir, streak, levels, impact, profile, onboarding)
- `lib/screens/admin/` — Admin dashboard and analytics
- `lib/services/` — Business logic singletons (XP, streaks, tracking, donations, settings, notifications, Quran API)
- `lib/models/` — Data models (AppConfig)
- `lib/widgets/` — Reusable widgets (icons, offline banner, animations, popups)
- `lib/utils/` — Helpers (asset loading)
- `assets/data/` — JSON data files (azkar)
- `assets/images/`, `assets/lottie/` — Visual assets

### State Management
Provider with `ChangeNotifier` (SettingsService). Most screens manage their own state via `StatefulWidget` + direct Supabase queries.

### External Services
- **Supabase**: Auth (Google sign-in), database (profiles, XP, streaks, donations, app_config), Realtime subscriptions
- **Quran Foundation API**: Quran text and tafsir data, configured via `.env` credentials
- **Hive**: Local key-value storage
- **SharedPreferences**: Simple local persistence for UI state
