-- =============================================================================
-- 20260607_100_strip_screenshot_annotations
--
-- Cleans up three leftover artifacts from the original screenshot import:
--
--   1. "INCOMPLETE - top Section scrolled…" / "INCOMPLETE - top scrolled…"
--      style editor annotations. These were screenshot-capture markers
--      noting that the source image cut off content. They may appear in
--      any text column.
--
--   2. "MENTION THE MATTER BY NAME" — an English instruction phrase that
--      sits between Arabic sections in source-screenshot duas (typically
--      the Salatul Istikhara style). The user reports it bleeding into
--      the arabic field of some azkar.
--
--   3. The Albani/Silsilat-al-Ahadith grading note that survived the
--      earlier strip because the embedded "no." abbreviation period ended
--      the previous `[^.]*\.` match early, leaving "3139." orphan.
--
-- =============================================================================

BEGIN;

-- ── 1. Strip "INCOMPLETE … top scrolled" annotations from any text field --
-- These came out of capture-tool notes left in the source data. They can
-- appear with various separators (—, :, dash) and capitalisations.
UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '\s*INCOMPLETE[^a-z]*top\s+(?:section\s+)?scroll(?:ed)?(?:\s+off)?[^.]*\.?',
  '', 'gi'
)
WHERE translation IS NOT NULL;

UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s*INCOMPLETE[^a-z]*top\s+(?:section\s+)?scroll(?:ed)?(?:\s+off)?[^.]*\.?',
  '', 'gi'
)
WHERE transliteration IS NOT NULL;

UPDATE azkar_items SET arabic = regexp_replace(
  arabic,
  '\s*INCOMPLETE[^a-z]*top\s+(?:section\s+)?scroll(?:ed)?(?:\s+off)?[^.]*\.?',
  '', 'gi'
)
WHERE arabic IS NOT NULL;

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*INCOMPLETE[^a-z]*top\s+(?:section\s+)?scroll(?:ed)?(?:\s+off)?[^.]*\.?',
  '', 'gi'
)
WHERE reward IS NOT NULL;


-- ── 2. Strip "MENTION THE MATTER BY NAME" instruction line ────────────────
-- Source-app placeholder shown between Arabic sections to indicate the
-- reciter should personalise the dua. Belongs in app UX (an input field),
-- not in the static azkar text.
UPDATE azkar_items SET arabic = regexp_replace(
  arabic,
  '\s*MENTION\s+(?:THE\s+)?MATTER\s+BY\s+NAME\s*',
  ' ', 'gi'
)
WHERE arabic IS NOT NULL;

UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '\s*MENTION\s+(?:THE\s+)?MATTER\s+BY\s+NAME\s*',
  ' ', 'gi'
)
WHERE translation IS NOT NULL;

UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s*MENTION\s+(?:THE\s+)?MATTER\s+BY\s+NAME\s*',
  ' ', 'gi'
)
WHERE transliteration IS NOT NULL;


-- ── 3. Re-strip Albani/Silsilat citations using greedy `.*$` so the
-- "no." abbreviation period inside the citation doesn't end the match.
-- Targets the "Classed as Hasan by Shaykh al-Albani in Silsilat al-Ahadith
-- as-Sahihah no. 3139." pattern in daily_dua_042 + orphan " 3139." tails.
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*Classed\s+as\s+(?:Sahih|Hasan)\s+by\s+Shaykh\s+al-Albani.*$',
  '', 'gi'
);

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*in\s+Silsilat?\s+al-(?:Ahadith|Saheehah)[^.]*\.?\s*\d*\.?\s*$',
  '', 'gi'
);

-- Orphan trailing " no. ###." or " ###." after the strip
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s+(?:no\.\s+)?\d{2,5}\.\s*$',
  '.', 'g'
);


-- Final whitespace cleanup
UPDATE azkar_items SET translation     = regexp_replace(translation,     '\s{2,}', ' ', 'g') WHERE translation IS NOT NULL;
UPDATE azkar_items SET transliteration = regexp_replace(transliteration, '\s{2,}', ' ', 'g') WHERE transliteration IS NOT NULL;
UPDATE azkar_items SET arabic          = regexp_replace(arabic,          '\s{2,}', ' ', 'g') WHERE arabic IS NOT NULL;
UPDATE azkar_items SET reward          = regexp_replace(reward,          '\s{2,}', ' ', 'g') WHERE reward IS NOT NULL;


-- Verify the rows the user flagged
SELECT id, title, arabic, translation, transliteration, reward
FROM azkar_items
WHERE id IN ('daily_dua_037', 'daily_dua_039', 'daily_dua_042', 'daily_dua_044')
ORDER BY id;

-- Catch-all: any row still containing the annotation markers anywhere
SELECT id, title
FROM azkar_items
WHERE COALESCE(arabic,'')          ~* '(INCOMPLETE|MENTION\s+(?:THE\s+)?MATTER)'
   OR COALESCE(translation,'')     ~* '(INCOMPLETE|MENTION\s+(?:THE\s+)?MATTER)'
   OR COALESCE(transliteration,'') ~* '(INCOMPLETE|MENTION\s+(?:THE\s+)?MATTER)'
   OR COALESCE(reward,'')          ~* '(INCOMPLETE|MENTION\s+(?:THE\s+)?MATTER|Silsilat|Shaykh\s+al-Albani)'
ORDER BY id;

COMMIT;
