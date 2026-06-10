-- =============================================================================
-- 20260607_090_strip_recite_count_parenthetical
--
-- daily_dua_037 (Protection from Hellfire) — and similar rows — have
-- "(Recite three times)" / "(Recite 3 times)" appended to their
-- translation AND transliteration. That instruction belongs on the
-- recommended-count badge, not inside the text the user reads.
--
-- Strips:
--   • "(Recite three times)"
--   • "(Recite N times)"  for any N
--   • "(three times)" / "(N times)"
-- from both `translation` and `transliteration`.
--
-- Also updates daily_dua_037's recommended_count to 3 to match the
-- intent of the previously-inline instruction.
-- =============================================================================

BEGIN;

-- Strip "(Recite N times)" / "(N times)" patterns from translation
UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '\s*\(\s*Recite\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+times?\s*\)',
  '', 'gi'
);
UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '\s*\(\s*(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+times?\s*\)',
  '', 'gi'
);

-- Same for transliteration
UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s*\(\s*Recite\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+times?\s*\)',
  '', 'gi'
);
UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s*\(\s*(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+times?\s*\)',
  '', 'gi'
);

-- Cleanup trailing whitespace
UPDATE azkar_items SET translation     = trim(translation)     WHERE translation IS NOT NULL;
UPDATE azkar_items SET transliteration = trim(transliteration) WHERE transliteration IS NOT NULL;

-- daily_dua_037 should be recited 3 times — set recommended_count accordingly
UPDATE azkar_items
SET recommended_count = 3
WHERE id = 'daily_dua_037' AND (recommended_count IS NULL OR recommended_count = 1);

-- Verify
SELECT id, title, translation, transliteration, recommended_count
FROM azkar_items
WHERE id = 'daily_dua_037';

-- Catch-all: any rows still with "(... times)" type parentheticals
SELECT id, title, translation, transliteration
FROM azkar_items
WHERE translation     ~* '\(\s*(?:recite\s+)?(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+times?\s*\)'
   OR transliteration ~* '\(\s*(?:recite\s+)?(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+times?\s*\)'
ORDER BY id;

COMMIT;
