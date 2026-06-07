-- =============================================================================
-- 20260607_050_strip_verse_numbers_from_text
--
-- Removes inline Quranic verse markers (e.g. "112:1", "112:2") from the
-- `translation` and `transliteration` fields of azkar_items. Sample:
--
--   Before (sleep_before_002):
--     "Bismillaahir Rahmaanir Raheem. 112:1 Qul huwa Allahu ahad,
--      112:2 Allahus-samad, 112:3 Lam yalid wa lam yoolad, 112:4 …"
--   After:
--     "Bismillaahir Rahmaanir Raheem. Qul huwa Allahu ahad,
--      Allahus-samad, Lam yalid wa lam yoolad, …"
--
-- The verse-number markers are useful metadata in scholarly texts but
-- clutter the reading display; the surah-level reference is already
-- shown in the `reference` field.
--
-- Two passes:
--   1. Strip mid-text " 112:1 " patterns → keep one separating space.
--   2. Strip start-of-string "112:1 " patterns → remove entirely.
--
-- Idempotent. Touches translation + transliteration columns.
-- =============================================================================

BEGIN;

-- ── translation ────────────────────────────────────────────────────────────
-- Pass 1: mid-text marker (preceded + followed by whitespace)
UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '\s+\d{1,3}:\d{1,3}\s+',
  ' ', 'g'
)
WHERE translation IS NOT NULL;

-- Pass 2: start-of-string marker
UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '^\d{1,3}:\d{1,3}\s+',
  '', 'g'
)
WHERE translation IS NOT NULL;

-- ── transliteration ───────────────────────────────────────────────────────
UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s+\d{1,3}:\d{1,3}\s+',
  ' ', 'g'
)
WHERE transliteration IS NOT NULL;

UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '^\d{1,3}:\d{1,3}\s+',
  '', 'g'
)
WHERE transliteration IS NOT NULL;

-- Final whitespace cleanup
UPDATE azkar_items SET translation = regexp_replace(translation, '\s{2,}', ' ', 'g')
WHERE translation IS NOT NULL;
UPDATE azkar_items SET transliteration = regexp_replace(transliteration, '\s{2,}', ' ', 'g')
WHERE transliteration IS NOT NULL;


-- Verify on the trigger row
SELECT id, title, translation, transliteration
FROM azkar_items
WHERE id = 'sleep_before_002';

-- Catch-all: any row still containing a digit:digit verse marker
SELECT id, title, translation
FROM azkar_items
WHERE translation ~ '\d{1,3}:\d{1,3}'
ORDER BY id;

SELECT id, title, transliteration
FROM azkar_items
WHERE transliteration ~ '\d{1,3}:\d{1,3}'
ORDER BY id;

COMMIT;
