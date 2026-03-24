# agents.md

Companion to CLAUDE.md — task-specific guidance for common agent workflows in this project.

## Adding a New Per-Azkar Illustration

1. **Choose visual concept** based on the azkar's reward/virtue from `adhkar_data.json` or `assets/data/azkar.json`
2. **Find all IDs** for the azkar: check both Supabase-style IDs (e.g., `morning_ayat_kursi`) in `countstmp.txt` and local fallback IDs (e.g., `morning_lwa_1`) in `assets/data/azkar.json`
3. **Add ID match** in `_buildIllustration()` in `dhikr_screen.dart` — use `id.contains()` for flexible matching
4. **Add top color** in `_illustrationTopColor()` matching the new painter's top gradient color
5. **Create widget** following the pattern:
   - `_YourWidget extends StatefulWidget` with `progress`, `isComplete`, `tapCount`, `pointsToday`
   - `_YourWidgetState with TickerProviderStateMixin` — init animation controllers for: pulse, grow, stars, particles, punch, shockwave, plus any custom ones
   - `_YourWidgetPainter extends CustomPainter` — all rendering in `paint()`, height is `260`
   - Must implement `didUpdateWidget` for progress animation + tap triggers
   - Must implement `shouldRepaint` comparing all fields
6. **Insert widget** before the `// Toolbar button & divider` comment block
7. **Verify**: `flutter analyze lib/screens/dhikr_screen.dart`

### Animation Controller Checklist
Every illustration needs at minimum:
- `_pulseCtrl` (1.3-1.6s, repeat reverse) — breathing effect
- `_growCtrl` (700ms) — progress animation via `animateTo(widget.progress)`
- `_starCtrl` (1.9s, repeat reverse) — background star twinkle
- `_pCtrl` (1.1s) — particle burst on tap
- `_punchCtrl` (300ms) — scale bump on tap
- `_shockCtrl` (600ms) — expanding ring on tap

### Completion Label Convention
Arabic text shown on completion, related to the azkar's virtue:
- Protection → `محفوظ بإذن الله`
- Sufficiency → `كُفيت بإذن الله`
- Forgiveness → `غُفر لك بإذن الله`
- Freedom → `حُررت بإذن الله`

## Modifying Azkar Data

Three JSON files contain azkar data and must be kept in sync:
- `assets/data/azkar.json` — primary local fallback (loaded by app)
- `adhkar_data.json` — reference data (Life With Allah source)
- `evening_adhkar_data.json` — evening-specific reference

Supabase tables `azkar_categories` and `azkar_items` are the primary source when online. Local JSON is fallback only.

### Formatting Rules
- Bismillah (`بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ`) must be on its own line (`\n` before the surah text)
- Isti'adhah (`أَعُوْذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيْمِ`) must be on its own line (`\n` before the ayah)
- Exception: when the isti'adhah IS the dhikr itself (e.g., `sunnah_anger`), keep it as-is

## Working with the Dhikr Screen

`dhikr_screen.dart` is the largest file (~5000+ lines). Key sections by line range (approximate, shifts with edits):

- **Models** (`_Azkar`, `_Category`, `_DhikrSettings`): top of file
- **`DhikrScreen`** (list view + categories): ~line 96-850
- **`_DhikrDetailScreen`** (swipe view + toolbar): ~line 860-1170
- **`_AzkarCard`** (display card): ~line 1430-1640
- **`_buildIllustration()`** router: ~line 1650-1710
- **`_NoorTree`** (default illustration): ~line 1720-2260
- **`_ProtectionShield`**: after NoorTree
- **`_ThreeQuls`**: after ProtectionShield
- **`_GatesOfJannah`**: after ThreeQuls
- **`_BreakingChains`**: after GatesOfJannah
- **`_ToolbarBtn`** + **`_DhikrCounterButton`**: near end of file

### Custom Targets
Users can set custom repetition targets per azkar via the flag button in the toolbar. Stored in `_customTargets` map, persisted via SharedPreferences keys `dhikr_custom_target_keys` + `dhikr_target_{id}`. Use `_getTarget(id, recommendedCount)` to resolve.

## Supabase Patterns

### Adding a New RPC
1. Create function in Supabase SQL editor
2. Call via `Supabase.instance.client.rpc('function_name', params: {...})`
3. Always wrap in try/catch with fallback (direct table query or default value)
4. Check `StreakService._recordFallback()` for the fallback pattern

### Realtime Subscriptions
Only `SettingsService` uses Realtime currently (channel: `app_config_changes`). Pattern:
```dart
_sb.channel('channel_name')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'table_name',
    callback: (payload) { /* re-fetch or update */ },
  ).subscribe();
```

## Testing

No tests exist yet. When adding tests:
- Service singletons need mocking — they access `Supabase.instance.client` directly
- CustomPaint illustrations can be golden-file tested
- Widget tests need `WidgetsFlutterBinding.ensureInitialized()` + Supabase mock

## Common Gotchas

- **Azkar IDs differ** between Supabase (`morning_ayat_kursi`) and local JSON fallback (`morning_lwa_1`). Always match both.
- **`mounted` check** required after every `await` before `setState()`.
- **`withValues(alpha:)`** is used instead of deprecated `withOpacity()` throughout.
- **AppBar background** in dhikr detail screen must match illustration top color via `_illustrationTopColor()`.
- **`_cleanArabic()`** strips tajweed marks — don't add them to display text expecting them to render.
- **Illustration height** is `260` across all painters (SizedBox inside build method). Change all at once if modifying.
