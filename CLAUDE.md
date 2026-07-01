# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Noor Rewards is a Flutter mobile app that gamifies Islamic worship (Quran reading, dhikr/azkar, tafsir) with XP economy, streaks, levels, badges, community donations, and custom illustrations. Backend is Supabase (auth, Postgres, Realtime). Primary target is Android, with iOS/web/desktop scaffolded.

## Build & Dev Commands

```bash
flutter pub get              # Install dependencies
flutter analyze              # Static analysis (flutter_lints)
flutter run                  # Run on device/emulator
flutter build apk --debug    # Debug APK
flutter build apk --release  # Release APK
flutter analyze lib/screens/dhikr_screen.dart  # Analyze single file (fast iteration)
```

**CI**: Push to `qa` branch → GitHub Actions builds debug APK. iOS TestFlight workflow in `.github/workflows/ios-testflight.yml`.

**Environment**: Requires `.env` in project root with Quran Foundation API credentials (`QURAN_API_CLIENT_ID`, `QURAN_API_CLIENT_SECRET`). Loaded by `flutter_dotenv`, parsed by `lib/services/quran_api_config.dart`.

**SDK**: Dart `>=3.7.0 <4.0.0`, Flutter stable. Android uses Java 17 with desugaring.

## Architecture

### Startup Sequence (`lib/main.dart`)

1. `Hive.initFlutter()` → local storage
2. `Supabase.initialize()` → hardcoded project URL + anon key
3. `QuranApiConfig.load()` → .env credentials
4. `SettingsService.instance.initialize()` → fetch remote config + Realtime subscription
5. `AssetHelper.loadAssets()` → pre-load asset registry
6. `NoorLiveNotificationService.init()` → persistent notification
7. `runApp()` with `ChangeNotifierProvider<SettingsService>`

### Auth Flow (AuthGate state machine)

```
No session → OnboardingScreen → StartJourneyScreen (Google sign-in)
Session exists → ProfileSetupScreen (if not done) → WelcomeGateScreen → DashboardScreen
```

Auth state flags stored in `auth.currentUser.userMetadata`. No named routes — direct widget swaps.

### State Management

- **SettingsService**: Singleton `ChangeNotifier` via Provider. Watches Supabase `app_config` table with Realtime. Admin changes (theme, economy values, feature flags) propagate instantly to all clients.
- **Screens**: `StatefulWidget` + direct Supabase queries in `initState()`. No separate state providers per screen.
- **Services**: Pure singleton business logic (no ChangeNotifier). Access via `ServiceName.instance`.

### Service Singletons

| Service | File | Responsibility |
|---------|------|----------------|
| `XpService` | `xp_service.dart` | XP economy, levels, badges, challenges. Weighted dhikr XP in `XpReward._dhikrXpMap`. All XP-earning **must** go through this. |
| `StreakService` | `streak_service.dart` | 3-type streaks (login, dhikr, quran). Idempotent — safe to call multiple times/day. Milestone bonuses at 3, 7, 14, 30, 60, 100 days. |
| `SettingsService` | `settings_service.dart` | Remote config via `app_config` table. `updateKey()` = optimistic UI + DB sync. |
| `TrackingService` | `tracking_service.dart` | Privacy-first analytics. Country via ip-api.com, no IP stored. |
| `DonationService` | `donation_service.dart` | Community project donations via RPC. |
| `QuranApiService` | `quran_api_service.dart` | OAuth2 client-credentials to Quran Foundation API. Token caching + auto-refresh. Falls back to alquran.cloud for unsupported editions. |
| `NoorLiveNotificationService` | `live_notification_service.dart` | Android persistent notification with daily Quran/Dhikr count. SharedPreferences auto-reset at midnight. |

### Supabase Tables

Core: `profiles`, `app_config`, `badges`, `user_badges`, `user_activities`, `streak_history`, `user_challenge_progress`, `challenges`, `xp_levels`, `leaderboard_global`, `user_donations`, `donation_projects`, `user_analytics`, `quran_bookmarks`, `quran_favorites`, `azkar_categories`, `azkar_items`.

Key RPCs: `earn_xp()`, `award_badge()`, `record_streak_activity()`, `get_streak_history()`, `donate_to_project()`.

### Dhikr Screen Architecture (`lib/screens/dhikr_screen.dart`)

This is the largest and most complex file. Key internal structure:

- **`_Azkar`** model: id, arabic, transliteration, translation, recommendedCount, category, reward, reference
- **`DhikrScreen`** (list view): categories, filtering, counts, favorites, custom targets (`_customTargets` map persisted in SharedPreferences)
- **`_DhikrDetailScreen`**: PageView-based swipe through azkar. Floating toolbar (settings, favorite, share, target, reset). Counter button at bottom.
- **`_AzkarCard`**: Display card with illustration + Arabic text + transliteration + translation + reward box
- **`_buildIllustration()`**: Router that picks the right CustomPaint widget per azkar ID
- **`_getTarget()`**: Returns custom target if set, otherwise recommendedCount

### Per-Azkar Illustrations System

Each illustration is a `StatefulWidget` with `TickerProviderStateMixin` containing animation controllers, wrapping a `CustomPainter`. They share a common interface: `progress`, `isComplete`, `tapCount`, `pointsToday`.

| Widget | Azkar | Visual |
|--------|-------|--------|
| `_NoorTree` | Default (all others) | Growing tree with colorful leaf orbs, small garden plants |
| `_ProtectionShield` | Ayat al-Kursi | Shield dome building around praying figure |
| `_ThreeQuls` | 3 Quls | 3 concentric barrier rings around Quran |
| `_GatesOfJannah` | Sayyid al-Istighfar | Two gates swinging open with paradise light |
| `_BreakingChains` | Anxiety/Laziness dua | 4 chains breaking progressively |

**ID matching** in `_buildIllustration()` uses `azkarId.toLowerCase()` with both Supabase IDs (e.g., `morning_ayat_kursi`) and local fallback IDs (e.g., `morning_lwa_1`).

**`_illustrationTopColor()`** returns the matching background color for the app bar to blend seamlessly.

### Arabic Text Styling

`_buildStyledArabic()` renders Arabic text with Bismillah/Isti'adhah phrases in a distinct highlight color (teal in light mode, blue in dark mode). Pattern matching via `_kHighlightPatterns` regex.

`_cleanArabic()` strips footnote markers, bracket chars, waqf/tajweed marks.

### Directory Layout

```
lib/
├── auth/           Auth screen (Supabase email/password + Google)
├── screens/        All app screens
│   └── admin/      Admin dashboard + sponsor analytics
├── services/       Business logic singletons
├── models/         Data models (AppConfig)
├── widgets/        Reusable widgets (NoorIcon, offline banner, popups)
├── utils/          Helpers (AssetHelper)
└── main.dart       Init + AuthGate
assets/
├── data/           azkar.json (dhikr library with ~70+ items)
├── images/         Category illustrations (18 PNGs)
├── lottie/         Lottie animations
└── fonts/          Custom Arabic font (KFGQPC Hafs)
```

### Coding Patterns

- **Error handling**: Silent try/catch with fallback data. Never crash UI. `debugPrint()` for logs.
- **Mounted checks**: Always `if (mounted) setState(...)` after async operations.
- **Supabase access**: `final _sb = Supabase.instance.client;` at top of State class.
- **Color constants**: File-level `const _kBg`, `_kText`, etc. Dark mode uses ternary throughout.
- **Typography**: `GoogleFonts.outfit()` for UI, `_kArabicFonts` list for Arabic (Amiri, Noto Naskh, Scheherazade).
- **CustomPaint animations**: AnimatedBuilder + Listenable.merge for multi-controller repaints.
- **Admin gating**: Client-side email whitelist `_kAdminEmails` in DashboardScreen.

### Key Dependencies

Core: `supabase_flutter`, `provider`, `google_fonts`, `hive_flutter`, `flutter_dotenv`, `just_audio`, `lottie`, `confetti`, `shared_preferences`, `share_plus`, `fl_chart`, `flutter_local_notifications`, `device_info_plus`.

### Notification Scheduling Policy (IMPORTANT)

Two delivery paths exist — pick the right one per use-case:

**Local scheduling (preferred for fixed wall-clock times).** Use
`LocalReminderScheduler` in `lib/services/local_reminder_scheduler.dart`
to register notifications with Android's `AlarmManager` via
`flutter_local_notifications` + `AndroidScheduleMode.exactAllowWhileIdle`.
These fire reliably even under Doze and on OEM battery-killers
(Xiaomi/Oppo/Vivo/Samsung) because they're queued by the OS itself,
not delivered over the network.

Currently local-scheduled: `morning_azkaar` (08:00),
`daily_astaghfir` (11:00), `evening_azkaar` (15:30 — Asr window),
`sleep_azkar` (21:00), `surah_kahf_friday` (Fri 07:00 + 16:00),
`salawat_friday` (Fri 12:00).

Requires `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM` in
`AndroidManifest.xml` (already added). Re-scheduled on every app
launch by `_AuthGateState._scheduleLocalReminders()`.

**FCM push (only for event-driven / unpredictable notifications).** Server-side
Edge Functions + pg_cron — when the firing time depends on user state we
can't compute on-device:
- `streak-at-risk` — depends on today's streak status
- `resume-reading` — depends on last_read_date
- `level-up-close` — depends on XP delta
- `community-momentum` — cohort timing
- `nightly-coin-reminder` — last-chance flow
- `monthly-quran-reminder`, `monthly-milestone` — monthly summaries
- `check-disengaged-users` — pauses notifications for inactive users
- `disengagement_pause` — the goodbye push itself
- `validate-seeds-reminder` — donate-your-Seeds nudge (~18:00 local)
- `habit-gap-reminder` — Quran-but-no-dhikr or dhikr-but-no-Quran
  bridges (~14:00 local)
- `featured-dua-reminder` — daily ~13:00 local; rotates a random
  azkar from the library and uses its `hadith_full` as the
  notification body so users discover new duas with motivating
  benefit text
- `project-funded-notifier` — daily; notifies all donors when a
  `community_projects` row flips to `is_completed = true`
- `akhirah-milestone-celebration` — daily; celebrates users crossing
  total_xp thresholds (1k / 5k / 10k / 25k / 50k / 100k / 250k /
  500k / 1M). At most one per threshold per user lifetime.
- `streak-milestone-celebration` — daily; celebrates day 3 / 7 / 14
  / 30 / 60 / 100 on any of the 3 streaks (login / dhikr / quran).

**Rule of thumb:** if the notification fires at the same local wall-clock
moment for every user every day, schedule it locally. If the firing
condition is "user state X is true," push it from the server. Never
implement a hybrid for the same notification type — duplicates are
worse than misses.

**Daily push cap.** Every server push function (except `admin-test-push`
and `check-disengaged-users`) calls `dailyPushCapReached(supabase, userId)`
from `supabase/functions/_shared/daily_cap.ts` and skips when the user
already has `MAX_PUSHES_PER_DAY` (currently **3**) FCM rows in
`notification_log` for the current UTC day. Local notifications do NOT
count — they aren't logged. When adding a new server push function, the
cap check is mandatory.
