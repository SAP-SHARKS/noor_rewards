-- =============================================================================
-- 20260710_010_azkar_sleep_full_surah_inline
--
-- Follow-up to 20260604_040. The dhikr card for sleep_before_019 (As-Sajdah)
-- and sleep_before_020 (Al-Mulk) used to render an "Open in Quran Reader"
-- button that navigated to QuranScreen. The user wanted the full Surah text
-- inline in the card instead, so the Flutter side now embeds a mini Quran
-- reader (_InlineSurahReader) directly in the card.
--
-- This migration just refreshes the user-facing translation copy so it no
-- longer references a button that doesn't exist anymore.
--
-- Idempotent — safe to re-run.
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET translation = 'Recite the entire Surah As-Sajdah (Chapter 32 of the Qur''an, 30 verses) before sleep. The full Surah appears below — read it right here to complete this practice.'
WHERE id = 'sleep_before_019';

UPDATE azkar_items
SET translation = 'Recite the entire Surah Al-Mulk (Chapter 67 of the Qur''an, 30 verses) before sleep. The full Surah appears below — read it right here to complete this practice.'
WHERE id = 'sleep_before_020';

COMMIT;
