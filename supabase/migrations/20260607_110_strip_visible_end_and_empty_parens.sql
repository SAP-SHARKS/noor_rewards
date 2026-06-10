-- =============================================================================
-- 20260607_110_strip_visible_end_and_empty_parens
--
-- Three follow-up fixes:
--
--   1. daily_dua_042's translation starts with " Visible end: ...death…"
--      — an editor's screenshot annotation noting only the bottom portion
--      of the source was captured. Strip "Visible end: ..." and "Top
--      scrolled off" / similar prefixes from all text fields.
--
--   2. daily_dua_044 (Salatul Istikhara — the 39th item displayed in
--      Daily Duas) has an empty " ( ) " between Arabic words. Previously
--      the source had "MENTION THE MATTER BY NAME" inside those parens
--      as an instruction; stripping the English left empty parens which
--      look broken. Remove the empty parens from arabic +
--      transliteration entirely (the translation explains what to do).
--
--   3. daily_dua_042 reward ended with ".." (double period) — leftover
--      from the Albani strip. Collapse "..." artifacts at end.
-- =============================================================================

BEGIN;

-- ── 1. Strip "Visible end:" / "Visible bottom only:" / "Top scrolled" etc.
-- These are screenshot-capture annotations that bled into the data.
-- Apply across all four text columns.

UPDATE azkar_items SET translation = regexp_replace(
  translation,
  '^\s*Visible\s+(?:end|bottom|top)[^:]*:\s*\.?\.?\.?\s*',
  '', 'gi'
)
WHERE translation IS NOT NULL;

UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '^\s*Visible\s+(?:end|bottom|top)[^:]*:\s*\.?\.?\.?\s*',
  '', 'gi'
)
WHERE transliteration IS NOT NULL;

UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '^\s*Visible\s+(?:end|bottom|top)[^:]*:\s*\.?\.?\.?\s*',
  '', 'gi'
)
WHERE reward IS NOT NULL;

UPDATE azkar_items SET arabic = regexp_replace(
  arabic,
  '^\s*Visible\s+(?:end|bottom|top)[^:]*:\s*\.?\.?\.?\s*',
  '', 'gi'
)
WHERE arabic IS NOT NULL;


-- ── 2. Remove empty " ( ) " placeholder from arabic and transliteration ---
-- The source had "MENTION THE MATTER BY NAME" inside these parens; that
-- English instruction was already stripped, leaving the empty container.
-- Drop the parens entirely so the Arabic flow doesn't have a visual gap.
UPDATE azkar_items SET arabic = regexp_replace(
  arabic,
  '\s*\(\s*\)\s*',
  ' ', 'g'
)
WHERE arabic IS NOT NULL;

UPDATE azkar_items SET transliteration = regexp_replace(
  transliteration,
  '\s*\(\s*\)\s*',
  ' ', 'g'
)
WHERE transliteration IS NOT NULL;


-- ── 3. Collapse trailing ".." or "..." artifacts in reward ---------------
UPDATE azkar_items SET reward = regexp_replace(
  reward,
  '\.{2,}\s*$',
  '.', 'g'
)
WHERE reward IS NOT NULL;


-- Final whitespace cleanup
UPDATE azkar_items SET translation     = regexp_replace(translation,     '\s{2,}', ' ', 'g') WHERE translation IS NOT NULL;
UPDATE azkar_items SET transliteration = regexp_replace(transliteration, '\s{2,}', ' ', 'g') WHERE transliteration IS NOT NULL;
UPDATE azkar_items SET arabic          = regexp_replace(arabic,          '\s{2,}', ' ', 'g') WHERE arabic IS NOT NULL;
UPDATE azkar_items SET reward          = regexp_replace(reward,          '\s{2,}', ' ', 'g') WHERE reward IS NOT NULL;

-- Trim leading/trailing whitespace
UPDATE azkar_items SET translation     = trim(translation)     WHERE translation IS NOT NULL;
UPDATE azkar_items SET transliteration = trim(transliteration) WHERE transliteration IS NOT NULL;
UPDATE azkar_items SET arabic          = trim(arabic)          WHERE arabic IS NOT NULL;
UPDATE azkar_items SET reward          = trim(reward)          WHERE reward IS NOT NULL;


-- Verify the flagged rows
SELECT id, title, arabic, translation, transliteration, reward
FROM azkar_items
WHERE id IN ('daily_dua_037', 'daily_dua_039', 'daily_dua_042', 'daily_dua_044')
ORDER BY id;

-- Catch-all: any row still containing annotation markers
SELECT id, title
FROM azkar_items
WHERE COALESCE(arabic,'')          LIKE '%( )%'
   OR COALESCE(transliteration,'') LIKE '%( )%'
   OR COALESCE(translation,'')     ~* '^\s*Visible\s+'
   OR COALESCE(reward,'')          ~* '^\s*Visible\s+'
   OR COALESCE(arabic,'')          ~* '(MENTION\s+(?:THE\s+)?MATTER|INCOMPLETE)'
   OR COALESCE(translation,'')     ~* '(MENTION\s+(?:THE\s+)?MATTER|INCOMPLETE)'
ORDER BY id;

COMMIT;
