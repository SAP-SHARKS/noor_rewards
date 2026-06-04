-- =============================================================================
-- 20260604_040_azkar_quran_link
--
-- Sleep #19 (Surah As-Sajdah) and Sleep #20 (Surah Al-Mulk) are full-Surah
-- recitations. The earlier import dumped developer-targeted placeholder text
-- like "Recite the entire Surah... App-level note: link/render via Quran
-- reader rather than inline." into the Arabic field. Hand-pasting 30 verses
-- of Qur'an would risk typos, so instead this migration:
--
--   1. Adds an azkar_items.quran_surah INTEGER column.
--   2. Sets quran_surah = 32 (As-Sajdah) and 67 (Al-Mulk).
--   3. Replaces the Arabic field with the Bismillah (standard Surah opener).
--   4. Writes user-facing translation/reward describing the practice.
--
-- Flutter then renders an "Open in Quran Reader" button on rows where
-- quran_surah IS NOT NULL, deep-linking into the existing QuranScreen.
-- =============================================================================

BEGIN;

-- 1. Schema -----------------------------------------------------------------
ALTER TABLE azkar_items ADD COLUMN IF NOT EXISTS quran_surah INTEGER;

COMMENT ON COLUMN azkar_items.quran_surah IS
  'Optional Quran chapter number (1-114). When non-null, the dhikr card renders an Open-In-Quran-Reader button that deep-links to QuranScreen(initialSurah: this).';


-- 2. Sleep #19 — Surah As-Sajdah (Chapter 32) -------------------------------
UPDATE azkar_items
SET
  quran_surah = 32,
  arabic = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  transliteration = 'Surah As-Sajdah',
  translation = 'Recite the entire Surah As-Sajdah (Chapter 32 of the Qur''an, 30 verses) before sleep. Tap the button below to open the full Surah in the Qur''an Reader.',
  reward = 'Jabir (RA) said: The Prophet ﷺ would not sleep until he recited Tanzeel as-Sajdah (Surah As-Sajdah) and Tabarak (Surah Al-Mulk).',
  reference = 'Surah As-Sajdah (Qur''an 32) | Jami at-Tirmidhi 3404',
  phrases = NULL
WHERE id = 'sleep_before_019';


-- 3. Sleep #20 — Surah Al-Mulk (Chapter 67) ---------------------------------
UPDATE azkar_items
SET
  quran_surah = 67,
  arabic = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  transliteration = 'Surah Al-Mulk',
  translation = 'Recite the entire Surah Al-Mulk (Chapter 67 of the Qur''an, 30 verses) before sleep. Tap the button below to open the full Surah in the Qur''an Reader.',
  reward = 'Abu Hurairah (RA) reported: The Messenger of Allah ﷺ said: "There is a Surah in the Qur''an which is only thirty verses. It defended whoever recited it until it puts him into Jannah, [namely Surah Al-Mulk]."',
  reference = 'Surah Al-Mulk (Qur''an 67) | Sunan Abi Dawud 1400 | Jami at-Tirmidhi 2891',
  phrases = NULL
WHERE id = 'sleep_before_020';


-- 4. Verify -----------------------------------------------------------------
SELECT id, title, quran_surah,
       (arabic ~ '[A-Za-z]') AS arabic_has_english,
       LENGTH(arabic) AS arabic_len
FROM azkar_items
WHERE quran_surah IS NOT NULL
ORDER BY id;

COMMIT;
