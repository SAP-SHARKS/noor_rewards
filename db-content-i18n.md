# DB / API-Sourced User-Facing Content — Phase 4 Report

Strings shown to users that originate from **Supabase tables** or **external APIs**, not from `.arb` files. These require schema-level localization (per-column locale variants or a separate `translations` table joined by `locale`). Do NOT wrap in `AppLocalizations` in Dart — the fix belongs in the database.

Generated as part of the i18n audit. Detector output: `i18n-audit.txt`. Wrap worklist: `TODO_I18N.md`.

---

## 1. Azkar / Dhikr library (`azkar_items`, `azkar_categories`, `azkar_item_categories`)

Fetched in `dhikr_hub_screen.dart:289,308` and cached in memory. Displayed on the Dua & Azkar screen, detail screen, illustrations, and reminders.

**Columns needing per-locale variants:**

| Column | Example | Locales affected |
|---|---|---|
| `title` / `title_<lang>` | "Ayat al-Kursi" | all 8 |
| `arabic` | (Arabic — no translation needed, same everywhere) | — |
| `transliteration` | "A'oodhu billahi..." | localized transliteration per script tradition |
| `translation` | "I seek refuge in Allah..." | all 8 |
| `benefits` / `benefit` | "Whoever recites this after every prayer..." | all 8 |
| `reward` | "10 hasanat per recitation" | all 8 |
| `reference` | "Sahih Muslim 395" | Arabic locale should be `صحيح مسلم ٣٩٥` |
| `category_label` | "MORNING REMEMBRANCE" | all 8 |
| `condition` / `context` | "After Fajr and Maghrib prayers" | all 8 |
| `section` | "Book of Complete Prayer" | all 8 |

**Existing pattern:** `donation_projects` already has `title_ur, title_ar, description_ur, description_ar` etc. Follow the same pattern for `azkar_items`.

**Schema suggestion:**
```sql
ALTER TABLE azkar_items
  ADD COLUMN title_ur text, ADD COLUMN title_ar text,
  ADD COLUMN title_fr text, ADD COLUMN title_id text,
  ADD COLUMN title_ms text, ADD COLUMN title_ru text,
  ADD COLUMN title_tr text,
  ADD COLUMN translation_ur text, ADD COLUMN translation_ar text,
  -- ... same for fr, id, ms, ru, tr
  ADD COLUMN benefits_ur text, ADD COLUMN benefits_ar text,
  -- ... same for fr, id, ms, ru, tr
  ADD COLUMN reference_ar text; -- Arabic canonical citation form
```

Or normalize into `azkar_item_translations (item_id, locale, field, value)`.

---

## 2. Dhikr illustration content (`dhikr_screen.dart:6702–8474`, `8480–8996`, `9000+`)

Three adjacent blocks in `dhikr_screen.dart` totalling **~600 hardcoded editorial strings**:

- **6702–8474** — benefit-illustration switch block (~190 strings): `benefitText`, `subtitle`, `completedSubtitle` for each illustration.
- **8480–8996** — `_pickTagline` function (~320 strings): a const `<Map<String,String>>` + `if (id == 'X') return 'tagline'` cascade mapping azkar IDs to English taglines.
- **9000+** — illustration widgets from `_DuaScene` to end-of-file (~70 strings): editorial dua/verse translations embedded as `text:` props inside CustomPainter subclasses (`_kQuranicTextLines`, `_segments` record lists, direct string args to painter helpers).

All three need `azkar_illustrations` (or a broader `azkar_content`) DB table with per-locale text columns. Example row-per-illustration schema:

```dart
'benefit_morning_1' => w(
  ({...}) => _BenefitTextIllustration(
    benefitText: 'Allah responds to every verse you recite, "This is for My servant..."',
    subtitle: 'Sahih Muslim 395',
    completedSubtitle: 'Allah has answered your call',
    accentColor: const Color(0xFFD4A843),
  ),
),
```

**Recommendation:** Move to a new Supabase table:

```sql
CREATE TABLE azkar_illustrations (
  ill_key text PRIMARY KEY,           -- 'benefit_morning_1'
  accent_color text,                  -- '#D4A843'
  benefit_text text,                  -- + benefit_text_ur / _ar / etc.
  subtitle text,                      -- + subtitle_ur / _ar / etc.
  completed_subtitle text             -- + completed_subtitle_ur / _ar / etc.
);
```

Then `dhikr_screen.dart` `_buildIllustration()` becomes a lookup instead of a switch. This deletes ~1800 lines of code and enables non-EN illustrations without an app release.

---

## 3. Donation projects (`community_projects`, `donation_projects`)

Fetched in `dashboard_screen.dart:393`, `project_detail_screen.dart`, `donation_service.dart`. Already partially localized per the memory note ("same approach which you used for Donation projects description").

**Columns needing per-locale variants (verify all 8 exist):**
- `title_<lang>`
- `description_<lang>`
- `category_<lang>` (if displayed)
- `location_<lang>` (city/country names — some locales transliterate)

---

## 4. Community project updates (`community_project_updates`)

Fetched in `project_detail_screen.dart:161`. Free-form English text right now.

**Columns:** `title`, `body`, `caption` — each needs per-locale variants.

---

## 5. Badges (`badges`, `user_badges`)

Fetched in `xp_service.dart:499`, `dashboard_screen.dart:822`. Awarded badges show name + description in the achievements grid + toast.

**Columns:** `name`, `description`, `tier_label` — per-locale variants.

---

## 6. Challenges (`challenges`, `user_challenge_progress`)

Fetched in `xp_service.dart:191,538,548`. Shown on dashboard "Today's challenges" card and Progress screen.

**Columns:** `title`, `description`, `reward_text` — per-locale variants.

---

## 7. XP Levels (`xp_levels`)

Fetched in `xp_service.dart:422`, `dashboard_screen.dart:431`. Level titles like "Seeker", "Champion", "Legend", "Believer", "Devoted".

Currently hardcoded fallback in `_levelTitleFor()` and translated in-app via `_localizeLevel(context, levelTitle)`. **Two-tier system already exists** — code translates DB values through an in-app lookup. Acceptable but fragile: any new level added in DB won't be translated until a client release.

**Recommendation:** Add `title_<lang>` columns to `xp_levels` so new levels are localized without an app release.

---

## 8. Quran verses + translations (`quran_verses`, `quran_translations`)

Fetched in `tafsir_screen.dart:686,692`. Verse text (Arabic — invariant) + translations (already per-locale).

**Status:** Likely already localized via `quran_translations.locale` column. Verify.

---

## 9. Orphan sponsor stories (`orphans` / sponsor tables)

Fetched in dashboard sponsor card, `orphan_detail_screen.dart`. Per the memory note, the story field is auto-translated via `swift-worker` Edge Function into 8 locales already.

**Status:** Fixed. Verify all locales are being populated.

---

## 10. Notifications (server-generated FCM push bodies)

Per `CLAUDE.md`, these Edge Functions send push notifications with English bodies:
`streak-at-risk`, `resume-reading`, `level-up-close`, `community-momentum`, `nightly-coin-reminder`, `monthly-quran-reminder`, `monthly-milestone`, `disengagement_pause`, `validate-seeds-reminder`, `habit-gap-reminder`, `featured-dua-reminder`, `project-funded-notifier`, `akhirah-milestone-celebration`, `streak-milestone-celebration`.

Each Edge Function needs to look up the recipient's `profiles.locale` and pick the correct body variant. Either:
- Store body variants in a `notification_templates(key, locale, title, body)` table and index by (key, locale)
- Or call an OpenAI/DeepL translation Edge Function per send (cheaper if cached)

**This is 14 Edge Functions × 8 locales — ~112 template rows.**

---

## Summary

| Source | Roughly-affected user-facing strings |
|---|---|
| Azkar library (columns) | ~500 (title + benefits + reward + reference across ~70 items) |
| Dhikr illustration block | ~190 (in-code, should move to DB) |
| Donation projects | ~50 (dynamic — varies per active project) |
| Community project updates | ~20 (dynamic) |
| Badges | ~40 (name + description × 20 badges) |
| Challenges | ~30 (title + description × 15 challenges) |
| XP Levels | ~20 (title × 20 levels) |
| Server-push notifications | ~30 template bodies × 14 functions |
| **Total DB-content strings** | **~880 rows needing per-locale variants** |

The `.arb`-side work fixes chrome (buttons, headers, labels). This DB-side work fixes content — the actual religious/community text the app renders. Both are required for a fully-localized app.
