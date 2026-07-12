-- =============================================================================
-- 20260711_010_azkar_sleep_kafirun_inline
--
-- Extends the inline Surah reader treatment (introduced for sleep_before_019
-- and sleep_before_020 in 20260710_010) to sleep_before_008 — Surah
-- Al-Kafirun (Chapter 109, 6 verses), traditionally recited before sleep.
--
-- Setting quran_surah = 109 flips the Flutter side from rendering the DB's
-- hand-pasted Arabic block to using the shared _InlineSurahReader widget,
-- which shows Bismillah + numbered verses + per-ayah translation, sourced
-- from the Quran Foundation API (Hive-cached, offline-tolerant).
--
-- Also refreshes the translation copy so it explains the new behaviour
-- ("The full Surah appears below" instead of the older row-of-verses
-- transliteration text that was previously inside the translation field).
--
-- Idempotent — safe to re-run.
-- =============================================================================

BEGIN;

UPDATE azkar_items
SET
  quran_surah = 109,
  translation = 'Recite the entire Surah Al-Kafirun (Chapter 109 of the Qur''an, 6 verses) before sleep. The full Surah appears below — read it right here to complete this practice.'
WHERE id = 'sleep_before_008';

COMMIT;
