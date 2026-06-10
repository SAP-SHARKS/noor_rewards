-- =============================================================================
-- 20260609_060_strip_translation_credit
--
-- The source app showed a "Translation: Sahih International" credit line
-- between the Translation and Benefit blocks for the 40 Rabbana du'as
-- (since all verses use the Sahih International translation). The credit
-- was imported into the data and now displays as visible text in the
-- card. Strip it from both `translation` and `reward` so the cards read
-- cleanly.
--
-- Patterns covered (case-insensitive):
--   • "Translation: Sahih International"
--   • "Translation - Sahih International"
--   • "(Translation: Sahih International)"
--   • Trailing variants with optional period / newline
--   • Optional "Service" / "Source" prefix
-- =============================================================================

BEGIN;

-- Strip from translation field (anywhere in the string)
UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '\s*\(?(?:Service|Source)?\s*Translation\s*[:\-—]?\s*Sahih\s+International\.?\)?',
  '', 'gi'
)
WHERE translation IS NOT NULL;

-- Strip from reward field (in case it bled there too)
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\s*\(?(?:Service|Source)?\s*Translation\s*[:\-—]?\s*Sahih\s+International\.?\)?',
  '', 'gi'
)
WHERE reward IS NOT NULL;

-- Strip from transliteration field (just in case)
UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s*\(?(?:Service|Source)?\s*Translation\s*[:\-—]?\s*Sahih\s+International\.?\)?',
  '', 'gi'
)
WHERE transliteration IS NOT NULL;

-- Whitespace + trailing punctuation cleanup
UPDATE azkar_items SET translation = regexp_replace(translation, '\s{2,}', ' ', 'g') WHERE translation IS NOT NULL;
UPDATE azkar_items SET reward      = regexp_replace(reward,      '\s{2,}', ' ', 'g') WHERE reward      IS NOT NULL;
UPDATE azkar_items SET translation = trim(translation) WHERE translation IS NOT NULL;
UPDATE azkar_items SET reward      = trim(reward)      WHERE reward      IS NOT NULL;


-- Verify a few flagged rows + catch-all
SELECT id, title, translation
FROM azkar_items
WHERE id IN ('rabbana_015', 'rabbana_031', 'rabbana_032', 'rabbana_033', 'rabbana_034')
ORDER BY id;

-- Catch-all scan
SELECT id, title
FROM azkar_items
WHERE COALESCE(translation,'') ~* 'Sahih\s+International'
   OR COALESCE(reward,'')      ~* 'Sahih\s+International'
   OR COALESCE(transliteration,'') ~* 'Sahih\s+International';

COMMIT;
