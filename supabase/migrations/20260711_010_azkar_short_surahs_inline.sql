-- =============================================================================
-- 20260711_010_azkar_short_surahs_inline
--
-- Extends the inline Surah reader (added for sleep_before_019/020 in
-- 20260604_040 + 20260710_010) to the eight morning/evening azkar that
-- currently prefix "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ" to a full short
-- Surah as a concatenated string. Setting `quran_surah` flips them to the
-- same _InlineSurahReader path used by Al-Mulk and As-Sajda:
--
--   • The card auto-hides the standalone Arabic/transliteration/translation
--     block (because `azkar.quranSurah != null`).
--   • The inline reader renders a centred Bismillah header once, then every
--     verse — pulled fresh from QuranApiService, Uthmani + Sahih Intl.
--
-- Mapping (both morning and evening editions of each dua share the surah):
--   morning_1  / evening_1  → Surah 1   (Al-Fatiha,  7 verses)
--   morning_9  / evening_9  → Surah 112 (Al-Ikhlas,  4 verses)
--   morning_10 / evening_10 → Surah 113 (Al-Falaq,   5 verses)
--   morning_11 / evening_11 → Surah 114 (An-Nas,     6 verses)
--
-- The existing `arabic`, `transliteration`, `translation`, `reward`, and
-- `reference` fields are left untouched — the card no longer displays the
-- Arabic body when quran_surah is set, so there is no reason to disturb
-- the underlying content (rollback = simply NULL out quran_surah).
--
-- Idempotent — safe to re-run.
-- =============================================================================

BEGIN;

UPDATE azkar_items SET quran_surah = 1   WHERE id = 'morning_1';
UPDATE azkar_items SET quran_surah = 1   WHERE id = 'evening_1';
UPDATE azkar_items SET quran_surah = 112 WHERE id = 'morning_9';
UPDATE azkar_items SET quran_surah = 112 WHERE id = 'evening_9';
UPDATE azkar_items SET quran_surah = 113 WHERE id = 'morning_10';
UPDATE azkar_items SET quran_surah = 113 WHERE id = 'evening_10';
UPDATE azkar_items SET quran_surah = 114 WHERE id = 'morning_11';
UPDATE azkar_items SET quran_surah = 114 WHERE id = 'evening_11';

-- ── Verify ───────────────────────────────────────────────────────────────────
SELECT id, title, quran_surah
FROM azkar_items
WHERE quran_surah IS NOT NULL
ORDER BY quran_surah, id;

COMMIT;
